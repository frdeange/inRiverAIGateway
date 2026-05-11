import collections
import concurrent.futures
import os
import sys

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from openai import APIStatusError, AzureOpenAI, RateLimitError


API_VERSION = os.getenv("API_VERSION", "2024-10-21")
REQUESTS_PER_TIER = int(os.getenv("REQUESTS_PER_TIER", 10))


def load_tiers():
    tiers = []
    for key, value in os.environ.items():
        if key.startswith("SMARTAI_") and key.endswith("_KEY"):
            tier_name = key.replace("SMARTAI_", "").replace("_KEY", "").lower()
            desc = os.getenv(f"SMARTAI_{tier_name.upper()}_DESC", "")
            tiers.append((tier_name, value, desc))
    return sorted(tiers)


def send_request(tier_name, endpoint, api_key, index):
    client = AzureOpenAI(
        azure_endpoint=endpoint,
        api_key=api_key,
        api_version=API_VERSION,
        default_headers={"api-key": api_key, "Ocp-Apim-Subscription-Key": api_key},
    )
    try:
        raw = client.chat.completions.with_raw_response.create(
            model="gpt-5.2",
            messages=[{"role": "user", "content": f"Request {index}. Reply with one word."}],
            max_completion_tokens=20,
        )
        response = raw.parse()
        region = raw.headers.get("x-ms-region", "unknown")
        model = response.model or "unknown"
        return 200, region, model
    except RateLimitError:
        return 429, "N/A", "N/A"
    except APIStatusError as exc:
        return int(exc.status_code), "N/A", "N/A"
    except Exception:
        return 0, "N/A", "N/A"


def run_tier(tier_name, api_key, endpoint):
    region_counts = collections.Counter()
    model_counts = collections.Counter()
    status_counts = collections.Counter()

    with concurrent.futures.ThreadPoolExecutor(max_workers=REQUESTS_PER_TIER) as executor:
        futures = [
            executor.submit(send_request, tier_name, endpoint, api_key, i)
            for i in range(1, REQUESTS_PER_TIER + 1)
        ]
        for future in concurrent.futures.as_completed(futures):
            status, region, model = future.result()
            status_counts[status] += 1
            if region and region != "N/A":
                region_counts[region] += 1
            if model and model != "N/A":
                model_counts[model] += 1

    return status_counts, region_counts, model_counts


def main() -> int:
    load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))
    gateway_url = os.getenv("AI_GATEWAY_URL", "").strip()

    if not gateway_url:
        print("Set AI_GATEWAY_URL in src/.env")
        return 1

    smart_endpoint = gateway_url.rsplit("/", 1)[0] + "/smartai"
    tiers = load_tiers()

    if not tiers:
        print("No SMARTAI_*_KEY variables found in .env")
        return 1

    print("🧠 Smart AI Gateway — Load Test by Product")
    print(f"🎯 Endpoint: {smart_endpoint}")
    print(f"📊 {REQUESTS_PER_TIER} requests per tier")
    print("=" * 60)

    for tier_name, api_key, desc in tiers:
        print(f"\n🏷️  \x1b[1;33m{tier_name.upper()}\x1b[0m ({desc})")
        print(f"   Sending {REQUESTS_PER_TIER} requests...")

        status_counts, region_counts, model_counts = run_tier(tier_name, api_key, smart_endpoint)

        ok = status_counts.get(200, 0)
        errors = sum(c for s, c in status_counts.items() if s != 200)
        print(f"   ✅ {ok} OK | ❌ {errors} errors")

        if region_counts:
            total = sum(region_counts.values())
            regions = " | ".join(
                f"{r}: {c} ({c/total*100:.0f}%)" for r, c in region_counts.most_common()
            )
            print(f"   🌍 Regions: {regions}")

        if model_counts:
            models = ", ".join(f"\x1b[1;36m{m}\x1b[0m" for m in model_counts.keys())
            print(f"   🤖 Model(s): {models}")

    print("\n" + "=" * 60)
    print("💡 Same endpoint, same request — different models and regions per product.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
