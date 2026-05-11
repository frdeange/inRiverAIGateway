import os
import time

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from openai import APIStatusError, AzureOpenAI, RateLimitError


API_VERSION = "2024-10-21"


def build_client() -> tuple[AzureOpenAI, str, str, str]:
    ai_gateway_url = os.getenv("AI_GATEWAY_URL", "").strip()
    foundry_endpoint = os.getenv("FOUNDRY_SEC_ENDPOINT", "").strip()
    deployment = os.getenv("MODEL_DEPLOYMENT", "gpt-5.2")
    if ai_gateway_url:
        endpoint = ai_gateway_url
        mode_label = "🔒 Mode: AI Gateway (governed)"
        subscription_key = os.getenv("AI_GATEWAY_KEY", "").strip()
        if subscription_key:
            return (
                AzureOpenAI(
                    azure_endpoint=endpoint,
                    api_key=subscription_key,
                    api_version=API_VERSION,
                    default_headers={"api-key": subscription_key, "Ocp-Apim-Subscription-Key": subscription_key},
                ),
                deployment,
                endpoint,
                mode_label,
            )
    else:
        endpoint = foundry_endpoint
        mode_label = "⚡ Mode: Direct to Foundry (ungoverned)"

    credential = DefaultAzureCredential()
    token_provider = get_bearer_token_provider(credential, "https://cognitiveservices.azure.com/.default")
    return (
        AzureOpenAI(
            azure_endpoint=endpoint,
            azure_ad_token_provider=token_provider,
            api_version=API_VERSION,
        ),
        deployment,
        endpoint,
        mode_label,
    )


def main() -> int:
    load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))
    endpoint = os.getenv("AI_GATEWAY_URL", "").strip() or os.getenv("FOUNDRY_SEC_ENDPOINT", "").strip()

    if not endpoint:
        print("Set FOUNDRY_SEC_ENDPOINT (or AI_GATEWAY_URL) in environment or src/.env.")
        return 1

    client, deployment, resolved_endpoint, mode_label = build_client()
    print(mode_label)
    print(f"🎯 Endpoint: {resolved_endpoint}")

    for index in range(1, 21):
        try:
            raw_response = client.chat.completions.with_raw_response.create(
                model=deployment,
                messages=[
                    {"role": "system", "content": "You are a concise assistant."},
                    {"role": "user", "content": f"Request {index}: explain AI gateway governance in one sentence."},
                ],
                max_completion_tokens=80,
            )
            response = raw_response.parse()
            print(f"#{index:02d} -> 200 OK ({response.usage.total_tokens} tokens)")
            print(f"🌍 x-ms-region: \x1b[1;32m{raw_response.headers.get('x-ms-region', 'N/A')}\x1b[0m")
            if raw_response.headers.get("x-backend-region"):
                print(f"🔀 x-backend-region: \x1b[1;36m{raw_response.headers.get('x-backend-region')}\x1b[0m")
        except RateLimitError:
            print(f"#{index:02d} -> RATE-LIMITED (429)")
        except APIStatusError as exc:
            if exc.status_code == 429:
                print(f"#{index:02d} -> RATE-LIMITED (429)")
            else:
                print(f"#{index:02d} -> ERROR ({exc.status_code})")
        except Exception as exc:
            print(f"#{index:02d} -> ERROR ({type(exc).__name__}: {exc})")
        time.sleep(0.1)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
