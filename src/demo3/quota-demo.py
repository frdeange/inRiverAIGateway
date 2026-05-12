import os
import sys
import time

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from openai import APIStatusError, AzureOpenAI, RateLimitError


API_VERSION = "2024-10-21"


def create_client(endpoint, api_key):
    return AzureOpenAI(
        azure_endpoint=endpoint,
        api_key=api_key,
        api_version=API_VERSION,
        default_headers={"api-key": api_key, "Ocp-Apim-Subscription-Key": api_key},
        max_retries=0,
    )


def send_request(client, model, index, customer_name):
    try:
        raw = client.chat.completions.with_raw_response.create(
            model=model,
            messages=[{"role": "user", "content": f"Request {index} from {customer_name}. Reply in one sentence."}],
            max_completion_tokens=40,
        )
        response = raw.parse()
        remaining_quota = raw.headers.get("x-remaining-quota", "?")
        consumed = raw.headers.get("x-tokens-consumed", "?")
        region = raw.headers.get("x-ms-region", "?")
        return {
            "status": 200,
            "remaining_quota": remaining_quota,
            "consumed": consumed,
            "region": region,
            "tokens": response.usage.total_tokens,
        }
    except (RateLimitError, APIStatusError) as exc:
        status = 429 if isinstance(exc, RateLimitError) else int(exc.status_code)
        return {"status": status, "remaining_quota": "0", "consumed": "0", "region": "N/A", "tokens": 0}
    except Exception:
        return {"status": 0, "remaining_quota": "?", "consumed": "?", "region": "N/A", "tokens": 0}


def print_result(name, i, result):
    status = result["status"]
    if status == 200:
        label = f"\x1b[1;32m200 OK\x1b[0m"
    elif status == 403:
        label = f"\x1b[1;35m403 QUOTA EXCEEDED\x1b[0m"
    elif status == 429:
        label = f"\x1b[1;31m429 THROTTLED\x1b[0m"
    else:
        label = f"\x1b[1;33m{status} ERROR\x1b[0m"

    print(
        f"   [{name}] #{i:02d} → {label} | "
        f"quota-left: {result['remaining_quota']} | "
        f"consumed: {result['consumed']} | "
        f"🌍 {result['region']}"
    )


def run_session(name, client, model, num_requests, delay=1.0):
    results = []
    total_consumed = 0
    for i in range(1, num_requests + 1):
        result = send_request(client, model, i, name)
        results.append(result)
        print_result(name, i, result)
        total_consumed += result.get("tokens", 0)
        time.sleep(delay)
    return results, total_consumed


def main() -> int:
    load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))

    gateway_base = os.getenv("AI_GATEWAY_URL", "").strip()
    if not gateway_base:
        print("Set AI_GATEWAY_URL in src/.env")
        return 1

    endpoint = gateway_base.rsplit("/", 1)[0] + "/noisyneighbor2"
    model = os.getenv("MODEL_DEPLOYMENT", "gpt-5.2")

    key_a = os.getenv("NOISY_CUSTOMER_A_KEY", "").strip()
    key_b = os.getenv("NOISY_CUSTOMER_B_KEY", "").strip()
    name_a = os.getenv("NOISY_CUSTOMER_A_NAME", "Customer A")
    name_b = os.getenv("NOISY_CUSTOMER_B_NAME", "Customer B")

    if not key_a or not key_b:
        print("Set NOISY_CUSTOMER_A_KEY and NOISY_CUSTOMER_B_KEY in src/.env")
        return 1

    client_a = create_client(endpoint, key_a)
    client_b = create_client(endpoint, key_b)

    print("📅 Monthly Token Quota Demo")
    print(f"🎯 Endpoint: {endpoint}")
    print(f"📊 Quota: 200 tokens/month per customer")
    print("=" * 65)

    # Session 1: Customer A uses some quota
    print(f"\n📋 Session 1: {name_a} (5 requests)")
    print("-" * 65)
    results_a1, consumed_a1 = run_session(name_a, client_a, model, 5)
    ok_a1 = sum(1 for r in results_a1 if r["status"] == 200)
    quota_a1 = sum(1 for r in results_a1 if r["status"] == 403)
    print(f"\n   ✅ {ok_a1}/5 OK | 🛑 {quota_a1} quota exceeded | ~{consumed_a1} tokens used\n")

    # Session 2: Customer B uses quota
    print(f"📋 Session 2: {name_b} (5 requests)")
    print("-" * 65)
    results_b, consumed_b = run_session(name_b, client_b, model, 5)
    ok_b = sum(1 for r in results_b if r["status"] == 200)
    quota_b = sum(1 for r in results_b if r["status"] == 403)
    print(f"\n   ✅ {ok_b}/5 OK | 🛑 {quota_b} quota exceeded | ~{consumed_b} tokens used\n")

    # Session 3: Customer A again — quota should be exhausted
    print(f"📋 Session 3: {name_a} again (3 requests) — quota exhausted?")
    print("-" * 65)
    results_a2, consumed_a2 = run_session(name_a, client_a, model, 3)
    ok_a2 = sum(1 for r in results_a2 if r["status"] == 200)
    quota_a2 = sum(1 for r in results_a2 if r["status"] == 403)

    print("\n" + "=" * 65)
    print("📊 RESULTS")
    print("=" * 65)
    print(f"   {name_a} (Session 1): ✅ {ok_a1}/5 OK | 🛑 {quota_a1} quota exceeded")
    print(f"   {name_b} (Session 2): ✅ {ok_b}/5 OK | 🛑 {quota_b} quota exceeded")
    print(f"   {name_a} (Session 3): ✅ {ok_a2}/3 OK | 🛑 {quota_a2} quota exceeded")
    print()
    print("   📖 403 = monthly quota exhausted (resets next month)")
    print("   🔑 Each customer has an INDEPENDENT monthly token budget")
    print("   💡 Perfect for FinOps: control AI spend per customer per month")
    return 0


if __name__ == "__main__":
    sys.exit(main())
