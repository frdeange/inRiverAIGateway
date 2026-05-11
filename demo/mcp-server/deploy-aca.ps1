az containerapp up `
  --name inriver-aigw-acamcp `
  --environment inriver-aigw-acaenv `
  --resource-group rg-inRiverAIGW `
  --source . `
  --ingress external `
  --target-port 8000
