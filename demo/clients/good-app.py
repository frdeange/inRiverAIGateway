import os
import sys

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from openai import AzureOpenAI


API_VERSION = "2024-10-21"


def build_client() -> tuple[AzureOpenAI, str, str]:
    apim_gateway_url = os.getenv("APIM_GATEWAY_URL", "").strip()
    foundry_endpoint = os.getenv("FOUNDRY_SEC_ENDPOINT", "").strip()

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
    endpoint = os.getenv("APIM_GATEWAY_URL", "").strip() or os.getenv("FOUNDRY_SEC_ENDPOINT", "").strip()

    if not endpoint:
        print("Set FOUNDRY_SEC_ENDPOINT (or APIM_GATEWAY_URL) in environment or demo/.env.")
        return 1

    client, resolved_endpoint, mode_label = build_client()
    print(mode_label)
    print(f"🎯 Endpoint: {resolved_endpoint}")

    response = client.chat.completions.create(
        model=deployment,
        messages=[{"role": "user", "content": "What is Azure AI Gateway in one sentence?"}],
        max_completion_tokens=100,
    )

    print(f"✅ Response: {response.choices[0].message.content}")
    print(
        f"📊 Tokens: {response.usage.prompt_tokens} prompt + {response.usage.completion_tokens} completion = "
        f"{response.usage.total_tokens} total"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
