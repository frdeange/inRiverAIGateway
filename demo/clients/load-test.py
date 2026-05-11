import collections
import concurrent.futures
import os

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from openai import APIStatusError, AzureOpenAI, RateLimitError

API_VERSION = "2024-10-21"
TOTAL_REQUESTS = 20


def build_endpoint_list() -> list[tuple[str, str]]:
    apim_gateway_url = os.getenv("APIM_GATEWAY_URL", "").strip()
    if apim_gateway_url:
        return [("apim", apim_gateway_url)]

    endpoints: list[tuple[str, str]] = []
    for region, env_name in (
        ("swedencentral", "FOUNDRY_SEC_ENDPOINT"),
        ("francecentral", "FOUNDRY_FRC_ENDPOINT"),
        ("spaincentral", "FOUNDRY_ESP_ENDPOINT"),
    ):
        endpoint = os.getenv(env_name, "").strip()
        if endpoint:
            endpoints.append((region, endpoint))

    return endpoints


def create_client(endpoint: str) -> AzureOpenAI:
    apim_gateway_url = os.getenv("APIM_GATEWAY_URL", "").strip()
    if apim_gateway_url:
        subscription_key = os.getenv("APIM_SUBSCRIPTION_KEY", "").strip()
        if subscription_key:
            return AzureOpenAI(
                azure_endpoint=endpoint,
                api_key=subscription_key,
                api_version=API_VERSION,
                default_headers={"Ocp-Apim-Subscription-Key": subscription_key},
            )

    credential = DefaultAzureCredential()
    token_provider = get_bearer_token_provider(credential, "https://cognitiveservices.azure.com/.default")
    return AzureOpenAI(
        azure_endpoint=endpoint,
        azure_ad_token_provider=token_provider,
        api_version=API_VERSION,
    )


def send_request(index: int, region: str, endpoint: str, deployment: str) -> tuple[int, str]:
    client = create_client(endpoint)
    try:
        response = client.chat.completions.with_raw_response.create(
            model=deployment,
            messages=[
                {"role": "system", "content": "You are a concise assistant."},
                {"role": "user", "content": f"Load test request {index}. Reply with one sentence."},
            ],
            max_completion_tokens=80,
        )
        backend = response.headers.get("x-backend-region", region)
        response.parse()
        return 200, backend
    except RateLimitError:
        return 429, region
    except APIStatusError as exc:
        return int(exc.status_code), region
    except Exception:
        return 0, region


def main() -> int:
    load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))
    endpoint_list = build_endpoint_list()
    deployment = os.getenv("MODEL_DEPLOYMENT", "gpt-5.2")
    apim_gateway_url = os.getenv("APIM_GATEWAY_URL", "").strip()

    if not endpoint_list:
        print("Set APIM_GATEWAY_URL or at least one FOUNDRY_*_ENDPOINT.")
        return 1

    print("🔒 Mode: APIM Gateway (governed)" if apim_gateway_url else "⚡ Mode: Direct to Foundry (ungoverned)")

    backend_counts = collections.Counter()
    status_counts = collections.Counter()

    with concurrent.futures.ThreadPoolExecutor(max_workers=TOTAL_REQUESTS) as executor:
        futures = []
        for i in range(1, TOTAL_REQUESTS + 1):
            region, endpoint = endpoint_list[(i - 1) % len(endpoint_list)]
            futures.append(executor.submit(send_request, i, region, endpoint, deployment))
        for i, future in enumerate(concurrent.futures.as_completed(futures), start=1):
            status, backend = future.result()
            status_counts[status] += 1
            backend_counts[backend] += 1
            label = "OK" if status == 200 else ("RATE-LIMITED" if status == 429 else "ERROR")
            print(f"Result {i:02d}: status={status} ({label}), backend={backend}")

    print("\nStatus summary:")
    for code, count in sorted(status_counts.items()):
        print(f"  {code}: {count}")

    print("Backend distribution:")
    for backend, count in backend_counts.items():
        print(f"  {backend}: {count}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
