###############################################################################
# inriver AI Gateway — populated from the original Bicep export.
# Keep secrets in secrets.auto.tfvars (gitignored).
###############################################################################

project          = "iagw"
environment      = "prd"
primary_location = "swedencentral"

###############################################################################
# Container Apps — image is overridden by CI/CD; lifecycle ignores changes
###############################################################################
aca_workload    = "mcp"
aca_image       = "inriveraigwacr.azurecr.io/mcp-product-catalog:latest"
aca_target_port = 8080
aca_cpu         = 0.25
aca_memory      = "0.5Gi"
aca_scale_min   = 0
aca_scale_max   = 10

###############################################################################
# AI Foundry (AIServices) — 3 accounts mirroring the export.
# Deployments per region come from the original capacity matrix:
#
#                       sec   esp   frc
#   gpt-4.1             10    10    10
#   gpt-4.1-mini        10    10    10
#   text-embedding-3-l  10    10    10
#   o3-mini             10    10    10
###############################################################################
ai_foundry_accounts = {
  sec = {
    location                 = "swedencentral"
    sku_name                 = "S0"
    local_auth_enabled       = false
    allow_project_management = true
    defender_for_ai_enabled  = false

    deployments = {
      "gpt-4.1" = {
        model_format  = "OpenAI"
        model_name    = "gpt-4.1"
        model_version = "2025-04-14"
        sku_name      = "GlobalStandard"
        sku_capacity  = 10
      }
      "gpt-4.1-mini" = {
        model_format  = "OpenAI"
        model_name    = "gpt-4.1-mini"
        model_version = "2025-04-14"
        sku_name      = "GlobalStandard"
        sku_capacity  = 10
      }
      "text-embedding-3-large" = {
        model_format  = "OpenAI"
        model_name    = "text-embedding-3-large"
        model_version = "1"
        sku_name      = "Standard"
        sku_capacity  = 10
      }
      "o3-mini" = {
        model_format  = "OpenAI"
        model_name    = "o3-mini"
        model_version = "2025-01-31"
        sku_name      = "GlobalStandard"
        sku_capacity  = 10
      }
    }

    projects = {
      "inriver-aigw-foundry-sec-project" = {
        display_name = "inriver-aigw-foundry-sec-project"
        description  = "Default AI Foundry project (Sweden Central)."
      }
    }
  }

  esp = {
    location                 = "spaincentral"
    sku_name                 = "S0"
    local_auth_enabled       = false
    allow_project_management = true
    defender_for_ai_enabled  = false

    deployments = {
      "gpt-4.1" = {
        model_format  = "OpenAI"
        model_name    = "gpt-4.1"
        model_version = "2025-04-14"
        sku_name      = "GlobalStandard"
        sku_capacity  = 10
      }
      "gpt-4.1-mini" = {
        model_format  = "OpenAI"
        model_name    = "gpt-4.1-mini"
        model_version = "2025-04-14"
        sku_name      = "GlobalStandard"
        sku_capacity  = 10
      }
      "text-embedding-3-large" = {
        model_format  = "OpenAI"
        model_name    = "text-embedding-3-large"
        model_version = "1"
        sku_name      = "Standard"
        sku_capacity  = 10
      }
      "o3-mini" = {
        model_format  = "OpenAI"
        model_name    = "o3-mini"
        model_version = "2025-01-31"
        sku_name      = "GlobalStandard"
        sku_capacity  = 10
      }
    }

    projects = {
      "inriver-aigw-foundry-esp-project" = {
        display_name = "inriver-aigw-foundry-esp-project"
        description  = "Default AI Foundry project (Spain Central)."
      }
    }
  }

  frc = {
    location                 = "francecentral"
    sku_name                 = "S0"
    local_auth_enabled       = false
    allow_project_management = true
    defender_for_ai_enabled  = false

    deployments = {
      "gpt-4.1" = {
        model_format  = "OpenAI"
        model_name    = "gpt-4.1"
        model_version = "2025-04-14"
        sku_name      = "GlobalStandard"
        sku_capacity  = 10
      }
      "gpt-4.1-mini" = {
        model_format  = "OpenAI"
        model_name    = "gpt-4.1-mini"
        model_version = "2025-04-14"
        sku_name      = "GlobalStandard"
        sku_capacity  = 10
      }
      "text-embedding-3-large" = {
        model_format  = "OpenAI"
        model_name    = "text-embedding-3-large"
        model_version = "1"
        sku_name      = "Standard"
        sku_capacity  = 10
      }
      "o3-mini" = {
        model_format  = "OpenAI"
        model_name    = "o3-mini"
        model_version = "2025-01-31"
        sku_name      = "GlobalStandard"
        sku_capacity  = 10
      }
    }

    projects = {
      "inriver-aigw-foundry-frc-project" = {
        display_name = "inriver-aigw-foundry-frc-project"
        description  = "Default AI Foundry project (France Central)."
      }
    }
  }
}

###############################################################################
# APIM
###############################################################################
apim_sku_name        = "BasicV2_1"
apim_publisher_email = "admin@gpsazure.com"
apim_publisher_name  = "inriver-aigw AI Gateway"

# Named values (1 public, 2 secret). Values for secrets live in secrets.auto.tfvars.
apim_named_values = {
  "credit-service-url" = {
    display_name = "credit-service-url"
    value        = "https://credit-service.example.com"
  }
  "6a01ab85f719a81f409c75f3" = {
    display_name = "Logger-Credentials"
    secret       = true
  }
  "jwt-signing-key" = {
    display_name = "jwt-signing-key"
    secret       = true
  }
}

# Single-URL backends. The foundry-esp backend has a circuit breaker rule.
apim_backends = {
  "inriver-aigw-foundry-esp" = {
    protocol    = "http"
    url         = "https://iagw-prd-aih-esp.cognitiveservices.azure.com"
    description = "Azure OpenAI / AI Foundry — Spain Central"
    circuit_breaker_rules = [
      {
        name               = "trip-on-5xx"
        trip_duration      = "PT1M"
        accept_retry_after = true
        failure = {
          count           = 3
          interval        = "PT1M"
          status_code_min = 500
          status_code_max = 599
        }
      },
    ]
  }
  "inriver-aigw-foundry-frc" = {
    protocol    = "http"
    url         = "https://iagw-prd-aih-frc.cognitiveservices.azure.com"
    description = "Azure OpenAI / AI Foundry — France Central"
  }
  "inriver-aigw-foundry-sec" = {
    protocol    = "http"
    url         = "https://iagw-prd-aih-sec.cognitiveservices.azure.com"
    description = "Azure OpenAI / AI Foundry — Sweden Central"
  }
  "localollama-openai-endpoint" = {
    protocol    = "http"
    url         = "http://localhost:11434/v1"
    description = "Local Ollama OpenAI-compatible endpoint."
  }
}

# Pool backends (round-robin / priority).
apim_backend_pools = {
  "OpenAI-Balanced" = {
    description = "Round-robin across the three Foundry regions, weighted."
    services = [
      { backend_name = "inriver-aigw-foundry-sec", weight = 50 },
      { backend_name = "inriver-aigw-foundry-esp", weight = 30 },
      { backend_name = "inriver-aigw-foundry-frc", weight = 20 },
    ]
  }
  "PTU-PAYG-Pool" = {
    description = "PTU-first with PAYG fallback."
    services = [
      { backend_name = "inriver-aigw-foundry-sec", weight = 100, priority = 1 },
      { backend_name = "inriver-aigw-foundry-esp", weight = 100, priority = 2 },
    ]
  }
}

# Custom groups beyond the built-in administrators/developers/guests.
apim_groups = {}
apim_users  = {}

apim_notifications = {
  # No additional recipients were configured in the export (all 7 default
  # notifications had empty recipient lists). Add entries as needed:
  # "RequestPublisherNotificationMessage" = ["ops@example.com"]
}

###############################################################################
# APIM APIs (10). Foundry/AOAI-style APIs use header "api-key".
###############################################################################
apim_apis = {
  # Generic AI catch-all
  "ai" = {
    display_name                 = "ai"
    path                         = "ai"
    subscription_required        = true
    subscription_key_header_name = "api-key"
    policy_file                  = "./policies/api-ai.xml"
  }

  # Per-region AI Foundry APIs (OpenAI/AOAI surface)
  "inriver-aigw-foundry-frc" = {
    display_name                 = "inriver-aigw-foundry-frc"
    path                         = "foundry/frc"
    subscription_required        = true
    subscription_key_header_name = "api-key"
    service_url                  = "https://iagw-prd-aih-frc.cognitiveservices.azure.com/openai"
    policy_file                  = "./policies/api-inriver-aigw-foundry-frc.xml"
    operations = {
      "chat-completions" = {
        display_name = "Creates a completion for the chat message"
        method       = "POST"
        url_template = "/deployments/{deployment-id}/chat/completions"
        template_parameters = [
          { name = "deployment-id", type = "string", required = true,
          description = "Deployment id of the model which was deployed." },
        ]
      }
      "completions" = {
        display_name = "Creates a completion for the provided prompt and parameters"
        method       = "POST"
        url_template = "/deployments/{deployment-id}/completions"
        template_parameters = [
          { name = "deployment-id", type = "string", required = true,
          description = "Deployment id of the model which was deployed." },
        ]
      }
      "embeddings" = {
        display_name = "Embeddings"
        method       = "POST"
        url_template = "/deployments/{deployment-id}/embeddings"
        template_parameters = [
          { name = "deployment-id", type = "string", required = true,
          description = "Deployment id of the model which was deployed." },
        ]
      }
      "responses" = {
        display_name = "Responses"
        method       = "POST"
        url_template = "/responses"
      }
    }
  }

  "inriver-aigw-foundry-sec" = {
    display_name                 = "inriver-aigw-foundry-sec"
    path                         = "foundry/sec"
    subscription_required        = true
    subscription_key_header_name = "api-key"
    service_url                  = "https://iagw-prd-aih-sec.cognitiveservices.azure.com/openai"
    policy_file                  = "./policies/api-inriver-aigw-foundry-sec.xml"
    operations = {
      "chat-completions" = {
        display_name = "Creates a completion for the chat message"
        method       = "POST"
        url_template = "/deployments/{deployment-id}/chat/completions"
        template_parameters = [
          { name = "deployment-id", type = "string", required = true },
        ]
      }
      "completions" = {
        display_name = "Creates a completion for the provided prompt and parameters"
        method       = "POST"
        url_template = "/deployments/{deployment-id}/completions"
        template_parameters = [
          { name = "deployment-id", type = "string", required = true },
        ]
      }
      "embeddings" = {
        display_name = "Embeddings"
        method       = "POST"
        url_template = "/deployments/{deployment-id}/embeddings"
        template_parameters = [
          { name = "deployment-id", type = "string", required = true },
        ]
      }
      "responses" = {
        display_name = "Responses"
        method       = "POST"
        url_template = "/responses"
      }
    }
  }

  "inrivermock" = {
    display_name                 = "inrivermock"
    path                         = "mock"
    subscription_required        = true
    subscription_key_header_name = "api-key"
    policy_file                  = "./policies/api-inrivermock.xml"
    operations = {
      "post-chat-completions" = {
        display_name = "Mock chat completions"
        method       = "POST"
        url_template = "/chat/completions"
      }
    }
  }

  "localollama" = {
    display_name                 = "localollama"
    path                         = "ollama"
    subscription_required        = true
    subscription_key_header_name = "Ocp-Apim-Subscription-Key"
    service_url                  = "http://localhost:11434/v1"
    policy_file                  = "./policies/api-localollama.xml"
    operations = {
      "chat-completions" = {
        display_name = "Chat completions"
        method       = "POST"
        url_template = "/chat/completions"
      }
      "completions" = {
        display_name = "Completions"
        method       = "POST"
        url_template = "/completions"
      }
      "embeddings" = {
        display_name = "Embeddings"
        method       = "POST"
        url_template = "/embeddings"
      }
      "models" = {
        display_name = "List models"
        method       = "GET"
        url_template = "/models"
      }
    }
  }

  "noisy-neighbor" = {
    display_name                 = "noisy-neighbor"
    path                         = "noisy"
    subscription_required        = true
    subscription_key_header_name = "Ocp-Apim-Subscription-Key"
    policy_file                  = "./policies/api-noisy-neighbor.xml"
    operations = {
      "catch-all" = {
        display_name = "catch-all"
        method       = "POST"
        url_template = "/*"
      }
    }
  }

  "noisy-neighbor2" = {
    display_name                 = "noisy-neighbor2"
    path                         = "noisy2"
    subscription_required        = true
    subscription_key_header_name = "Ocp-Apim-Subscription-Key"
    policy_file                  = "./policies/api-noisy-neighbor2.xml"
    operations = {
      "catch-all" = {
        display_name = "catch-all"
        method       = "POST"
        url_template = "/*"
        policy_file  = "./policies/op-noisy-neighbor2-catch-all.xml"
      }
    }
  }

  "ptupayg" = {
    display_name                 = "ptupayg"
    path                         = "ptupayg"
    subscription_required        = true
    subscription_key_header_name = "api-key"
    policy_file                  = "./policies/api-ptupayg.xml"
    operations = {
      "chat-completions" = {
        display_name = "Chat completions (PTU→PAYG fallback)"
        method       = "POST"
        url_template = "/deployments/{deployment-id}/chat/completions"
        template_parameters = [
          { name = "deployment-id", type = "string", required = true },
        ]
      }
    }
  }

  "smartai" = {
    display_name                 = "smartai"
    path                         = "smartai"
    subscription_required        = true
    subscription_key_header_name = "api-key"
    policy_file                  = "./policies/api-smartai.xml"
    operations = {
      "chat-completions" = {
        display_name = "Smart chat completions"
        method       = "POST"
        url_template = "/deployments/{deployment-id}/chat/completions"
        template_parameters = [
          { name = "deployment-id", type = "string", required = true },
        ]
      }
    }
  }
}

###############################################################################
# APIM products
###############################################################################
apim_products = {
  "inriver-aigw-foundry-sec-inriver-aigw-foundry-sec-proje-ai-2vdyv3rvfp" = {
    display_name          = "inriver-aigw-foundry-sec — project AI"
    description           = "Auto-generated product binding the foundry-sec API to the AI project."
    subscription_required = true
    approval_required     = false
    published             = true
    api_names             = ["inriver-aigw-foundry-sec"]
    group_names           = ["administrators"]
    policy_file           = "./policies/product-foundry-sec.xml"
  }
}

###############################################################################
# APIM subscriptions
#
# The original export had 4 subscriptions; "master" is auto-created by APIM and
# is intentionally omitted. The remaining ones are scoped to APIs that exist in
# this configuration.
###############################################################################
apim_subscriptions = {
  "inriver-aigw-foundry-sec-inriver-aigw-foundry-sec-proje-ai-2vdyv3rvfp" = {
    display_name = "inriver-aigw-foundry-sec — project subscription"
    scope_kind   = "product"
    scope_target = "inriver-aigw-foundry-sec-inriver-aigw-foundry-sec-proje-ai-2vdyv3rvfp"
    state        = "active"
  }
  "inriver-aigw-foundry-frc-subscription" = {
    display_name = "inriver-aigw-foundry-frc subscription"
    scope_kind   = "api"
    scope_target = "inriver-aigw-foundry-frc"
    state        = "active"
  }
}

