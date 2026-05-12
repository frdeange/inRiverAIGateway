import os
import sys
import time

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from openai import APIStatusError, AzureOpenAI, RateLimitError


API_VERSION = "2024-10-21"
TOTAL_REQUESTS = 10


def create_client(endpoint, api_key):
    return AzureOpenAI(
        azure_endpoint=endpoint,
        api_key=api_key,
        api_version=API_VERSION,
        default_headers={"api-key": api_key, "Ocp-Apim-Subscription-Key": api_key},
        max_retries=0,
    )


def send_request(client, deployment, index):
    try:
        raw = client.chat.completions.with_raw_response.create(
            model=deployment,
            messages=[{"role": "user", "content": f"Request {index}. Write a detailed paragraph about cloud computing benefits, at least 200 words."}],
            max_completion_tokens=300,
        )
        response = raw.parse()
        region = raw.headers.get("x-ms-region", "unknown")
        return {"status": 200, "region": region, "tokens": response.usage.total_tokens}
    except RateLimitError:
        return {"status": 429, "region": "N/A (throttled)", "tokens": 0}
    except APIStatusError as exc:
        return {"status": int(exc.status_code), "region": "N/A", "tokens": 0}
    except Exception as exc:
        return {"status": 0, "region": f"ERROR: {exc}", "tokens": 0}


def main() -> int:
    load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))

    gateway_base = os.getenv("AI_GATEWAY_URL", "").strip()
    if not gateway_base:
        print("Set AI_GATEWAY_URL in src/.env")
        return 1

    endpoint = gateway_base.rsplit("/", 1)[0] + "/ptupayg"
    key = os.getenv("PTUPAYG_KEY", "").strip()
    deployment = "gpt-4.1-nano"

    if not key:
        print("Set PTUPAYG_KEY in src/.env")
        return 1

    client = create_client(endpoint, key)

    print("⚡ PTU → PAYG Failover Demo (Circuit Breaker)")
    print(f"🎯 Endpoint: {endpoint}")
    print(f"🤖 Model: {deployment}")
    print(f"📊 Sending {TOTAL_REQUESTS} requests sequentially")
    print(f"   Priority 1 (PTU sim): Spain Central — 1K TPM")
    print(f"   Priority 2 (PAYG sim): Sweden/France — 500K TPM each")
    print("=" * 65)

    region_counts = {}
    status_counts = {}

    for i in range(1, TOTAL_REQUESTS + 1):
        result = send_request(client, deployment, i)
        status = result["status"]
        region = result["region"]

        status_counts[status] = status_counts.get(status, 0) + 1
        region_counts[region] = region_counts.get(region, 0) + 1

        if status == 200:
            label = f"\x1b[1;32m200 OK\x1b[0m"
        elif status == 429:
            label = f"\x1b[1;31m429 THROTTLED\x1b[0m"
        else:
            label = f"\x1b[1;33m{status} ERROR\x1b[0m"

        region_color = "\x1b[1;33m" if "Spain" in region else "\x1b[1;36m"
        print(f"   #{i:02d} → {label} | 🌍 {region_color}{region}\x1b[0m")
        time.sleep(0.3)

    print("\n" + "=" * 65)
    print("📊 RESULTS")
    print("=" * 65)

    print("\n   Status distribution:")
    for status, count in sorted(status_counts.items()):
        pct = count / TOTAL_REQUESTS * 100
        print(f"     {status}: {count} ({pct:.0f}%)")

    print("\n   🌍 Region distribution:")
    for region, count in sorted(region_counts.items(), key=lambda x: -x[1]):
        pct = count / TOTAL_REQUESTS * 100
        bar = "█" * int(pct / 2)
        print(f"     {region}: {count} ({pct:.0f}%) {bar}")

    # Check if failover happened
    spain_count = sum(c for r, c in region_counts.items() if "Spain" in r)
    other_count = sum(c for r, c in region_counts.items() if "Spain" not in r and "N/A" not in r)

    print()
    if spain_count > 0 and other_count > 0:
        print("   💡 \x1b[1;32mFAILOVER DETECTED!\x1b[0m")
        print(f"   First {spain_count} requests went to Spain (PTU sim)")
        print(f"   Then {other_count} requests failed over to Sweden/France (PAYG sim)")
        print("   Circuit breaker opened when Spain hit its TPM limit")
    elif other_count > 0 and spain_count == 0:
        print("   ⚠️  All requests went to PAYG — PTU might already be tripped")
        print("   Wait a minute for circuit breaker to reset and try again")
    else:
        print("   📋 All requests served by PTU (Spain) — try sending more to trigger failover")

    print()
    print("   🔑 Key insight: Priority-based routing with circuit breaker")
    print("   ensures PTU capacity is used first, with automatic PAYG fallback")
    return 0


if __name__ == "__main__":
    sys.exit(main())
