import collections
import concurrent.futures
import os
import sys
import time

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from openai import APIStatusError, AzureOpenAI, RateLimitError


API_VERSION = os.getenv("API_VERSION", "2024-10-21")


def create_client(endpoint, api_key):
    return AzureOpenAI(
        azure_endpoint=endpoint,
        api_key=api_key,
        api_version=API_VERSION,
        default_headers={"api-key": api_key, "Ocp-Apim-Subscription-Key": api_key},
    )


def send_request(client, model, index, customer_name):
    try:
        raw = client.chat.completions.with_raw_response.create(
            model=model,
            messages=[{"role": "user", "content": f"Request {index} from {customer_name}. Reply in one sentence."}],
            max_completion_tokens=40,
        )
        response = raw.parse()
        remaining_calls = raw.headers.get("x-remaining-calls", "?")
        remaining_tokens = raw.headers.get("x-remaining-tokens", "?")
        tokens_consumed = raw.headers.get("x-tokens-consumed", "?")
        region = raw.headers.get("x-ms-region", "?")
        return {
            "status": 200,
            "remaining_calls": remaining_calls,
            "remaining_tokens": remaining_tokens,
            "tokens_consumed": tokens_consumed,
            "region": region,
            "tokens": response.usage.total_tokens,
        }
    except (RateLimitError, APIStatusError) as exc:
        status = 429 if isinstance(exc, RateLimitError) else int(exc.status_code)
        return {"status": status, "remaining_calls": "0", "remaining_tokens": "0", "tokens_consumed": "0", "region": "N/A", "tokens": 0}
    except Exception as exc:
        return {"status": 0, "remaining_calls": "?", "remaining_tokens": "?", "tokens_consumed": "?", "region": "N/A", "tokens": 0}


def run_customer(name, client, model, num_requests, delay=0.3):
    results = []
    for i in range(1, num_requests + 1):
        result = send_request(client, model, i, name)
        results.append(result)
        print_result(name, i, result)
        time.sleep(delay)
    return results


def run_customer_parallel(name, client, model, num_requests):
    indexed_results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=num_requests) as executor:
        futures = {
            executor.submit(send_request, client, model, i, name): i
            for i in range(1, num_requests + 1)
        }
        for future in concurrent.futures.as_completed(futures):
            i = futures[future]
            result = future.result()
            indexed_results.append((i, result))

    # Print sorted by request number for readability
    indexed_results.sort(key=lambda x: x[0])
    results = []
    for i, result in indexed_results:
        results.append(result)
        print_result(name, i, result)
    return results


def print_result(name, i, result):
    status = result["status"]
    if status == 200:
        label = f"\x1b[1;32m200 OK\x1b[0m"
    elif status == 429:
        label = f"\x1b[1;31m429 THROTTLED\x1b[0m"
    elif status == 403:
        label = f"\x1b[1;35m403 QUOTA EXCEEDED\x1b[0m"
    else:
        label = f"\x1b[1;33m{status} ERROR\x1b[0m"

    remaining = result.get("remaining_calls", "?")
    remaining_tok = result.get("remaining_tokens", "?")
    consumed = result.get("tokens_consumed", "?")
    try:
        remaining = str(max(0, int(remaining)))
    except (ValueError, TypeError):
        pass
    print(
        f"   [{name}] #{i:02d} → {label} | "
        f"calls-left: {remaining} | "
        f"tokens-left: {remaining_tok} | "
        f"consumed: {consumed} | "
        f"🌍 {result['region']}"
    )


def main() -> int:
    load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))

    gateway_base = os.getenv("AI_GATEWAY_URL", "").strip()
    if not gateway_base:
        print("Set AI_GATEWAY_URL in src/.env")
        return 1

    noisy_endpoint = gateway_base.rsplit("/", 1)[0] + "/noisyneighbor"
    model = os.getenv("MODEL_DEPLOYMENT", "gpt-5.2")

    key_a = os.getenv("NOISY_CUSTOMER_A_KEY", "").strip()
    key_b = os.getenv("NOISY_CUSTOMER_B_KEY", "").strip()
    name_a = os.getenv("NOISY_CUSTOMER_A_NAME", "Customer A")
    name_b = os.getenv("NOISY_CUSTOMER_B_NAME", "Customer B")

    if not key_a or not key_b:
        print("Set NOISY_CUSTOMER_A_KEY and NOISY_CUSTOMER_B_KEY in src/.env")
        return 1

    client_a = create_client(noisy_endpoint, key_a)
    client_b = create_client(noisy_endpoint, key_b)

    print("🔒 Noisy Neighbor Protection Demo")
    print(f"🎯 Endpoint: {noisy_endpoint}")
    print(f"📊 Limits: 3 calls/min + 200 tokens/min per customer")
    print("=" * 70)

    # Phase 1: Customer A alone — works fine
    print(f"\n📋 Phase 1: {name_a} alone (3 requests)")
    print("-" * 70)
    results_a1 = run_customer(name_a, client_a, model, 3, delay=0.5)

    ok_a1 = sum(1 for r in results_a1 if r["status"] == 200)
    throttled_a1 = sum(1 for r in results_a1 if r["status"] == 429)
    quota_a1 = sum(1 for r in results_a1 if r["status"] == 403)
    print(f"\n   ✅ {ok_a1}/3 OK | 🚫 {throttled_a1} throttled | 🛑 {quota_a1} quota exceeded\n")

    # Phase 2: Customer B floods — gets throttled
    print(f"\n📋 Phase 2: {name_b} batch flood (12 requests, ALL PARALLEL)")
    print("-" * 70)
    results_b = run_customer_parallel(name_b, client_b, model, 12)

    ok_b = sum(1 for r in results_b if r["status"] == 200)
    throttled_b = sum(1 for r in results_b if r["status"] == 429)
    quota_b = sum(1 for r in results_b if r["status"] == 403)
    print(f"\n   ✅ {ok_b}/12 OK | 🚫 {throttled_b} throttled | 🛑 {quota_b} quota exceeded\n")

    # Phase 3: Customer A again — still works despite B being throttled
    print(f"📋 Phase 3: {name_a} again (3 requests) — unaffected by B's flood?")
    print("-" * 70)
    results_a2 = run_customer(name_a, client_a, model, 3, delay=0.5)

    ok_a2 = sum(1 for r in results_a2 if r["status"] == 200)
    throttled_a2 = sum(1 for r in results_a2 if r["status"] == 429)
    quota_a2 = sum(1 for r in results_a2 if r["status"] == 403)

    print("\n" + "=" * 70)
    print("📊 RESULTS SUMMARY")
    print("=" * 70)
    print(f"   {name_a} (Phase 1): ✅ {ok_a1}/3 OK | 🚫 {throttled_a1} throttled | 🛑 {quota_a1} quota exceeded")
    print(f"   {name_b} (flood):   ✅ {ok_b}/12 OK | 🚫 {throttled_b} throttled | 🛑 {quota_b} quota exceeded")
    print(f"   {name_a} (Phase 3): ✅ {ok_a2}/3 OK | 🚫 {throttled_a2} throttled | 🛑 {quota_a2} quota exceeded")
    print()
    print("   📖 429 = rate limit (resets every minute)")
    print("   📖 403 = monthly quota exhausted (resets next month)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
