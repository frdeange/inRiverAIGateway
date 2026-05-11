import os
import time

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from openai import APIStatusError, AzureOpenAI, RateLimitError


API_VERSION = "2024-10-21"


def build_client() -> tuple[AzureOpenAI, str, str, str]:
    apim_gateway_url = os.getenv("APIM_GATEWAY_URL", "").strip()
    foundry_endpoint = os.getenv("FOUNDRY_SEC_ENDPOINT", "").strip()
    deployment = os.getenv("MODEL_DEPLOYMENT", "gpt-5.2")
    if apim_gateway_url:
        endpoint = apim_gateway_url
        mode_label = "🔒 Mode: APIM Gateway (governed)"
        subscription_key = os.getenv("APIM_SUBSCRIPTION_KEY", "").strip()
        if subscription_key:
            return (
                AzureOpenAI(
                    azure_endpoint=endpoint,
                    api_key=subscription_key,
                    api_version=API_VERSION,
                    default_headers={"Ocp-Apim-Subscription-Key": subscription_key},
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
    endpoint = os.getenv("APIM_GATEWAY_URL", "").strip() or os.getenv("FOUNDRY_SEC_ENDPOINT", "").strip()

    if not endpoint:
        print("Set FOUNDRY_SEC_ENDPOINT (or APIM_GATEWAY_URL) in environment or demo/.env.")
        return 1

    client, deployment, resolved_endpoint, mode_label = build_client()
    print(mode_label)
    print(f"🎯 Endpoint: {resolved_endpoint}")

    for index in range(1, 21):
        try:
            response = client.chat.completions.create(
                model=deployment,
                messages=[
                    {"role": "system", "content": "You are a concise assistant."},
                    {"role": "user", "content": f"Request {index}: explain AI gateway governance in one sentence."},
                ],
                max_completion_tokens=80,
            )
            print(f"#{index:02d} -> 200 OK ({response.usage.total_tokens} tokens)")
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
