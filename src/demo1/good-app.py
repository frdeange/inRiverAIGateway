import os
import sys

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from openai import AzureOpenAI


API_VERSION = "2024-10-21"


def build_client() -> tuple[AzureOpenAI, str, str]:
    ai_gateway_url = os.getenv("AI_GATEWAY_URL", "").strip()
    foundry_endpoint = os.getenv("FOUNDRY_SEC_ENDPOINT", "").strip()

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
        endpoint,
        mode_label,
    )


def main() -> int:
    load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))
    deployment = os.getenv("MODEL_DEPLOYMENT", "gpt-5.2")
    endpoint = os.getenv("AI_GATEWAY_URL", "").strip() or os.getenv("FOUNDRY_SEC_ENDPOINT", "").strip()

    if not endpoint:
        print("Set FOUNDRY_SEC_ENDPOINT (or AI_GATEWAY_URL) in environment or src/.env.")
        return 1

    client, resolved_endpoint, mode_label = build_client()
    print(mode_label)
    print(f"🎯 Endpoint: {resolved_endpoint}")

    raw_response = client.chat.completions.with_raw_response.create(
        model=deployment,
        messages=[{"role": "user", "content": "What is Azure AI Gateway in one sentence?"}],
        max_completion_tokens=100,
    )
    response = raw_response.parse()

    print(f"✅ Response: {response.choices[0].message.content}")
    print(
        f"📊 Tokens: {response.usage.prompt_tokens} prompt + {response.usage.completion_tokens} completion = "
        f"{response.usage.total_tokens} total"
    )
    print(f"🌍 x-ms-region: \x1b[1;32m{raw_response.headers.get('x-ms-region', 'N/A')}\x1b[0m")
    if raw_response.headers.get("x-backend-region"):
        print(f"🔀 x-backend-region: \x1b[1;36m{raw_response.headers.get('x-backend-region')}\x1b[0m")
    return 0


if __name__ == "__main__":
    sys.exit(main())
