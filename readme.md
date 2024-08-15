# Integration Workshop

## Goals:
- Simplify getting started with AIS using a template to pre-deploy resources
- Provide familiarity with API-M, Logic Apps, Service Bus, Application Insights
- Optionally provide familiarity with Azure Functions, Integration Environments, and Business Process Tracking
- Can be extended to show Data Factory, Azure Storage, and Event Grid

## Prerequisites:
- Azure Subscription
- Template found in deploy/ deployed

## Deployment:
```bash
RG=scootais # Resource Group
LOC=eastasia # Location
az group create --name $RG --location $LOC
az deployment group create --resource-group $RG --template-file deploy/deploy.bicep
```

## Recommended flow (2-3 hours):
- [15 min] Slides - Intro to AIS
- [10 min] Slides & Demo - Logic App Editor
- [25 min] Hands on - Create a Logic App workflow that exposes an API, filters messages, composes data, and sends to Service Bus Topic (pre-created)
- [10 min] Slides & Demo - Service Bus
- [15 min] Hands on - Create a subscription for the Service Bus Topic, and create a Logic App workflow that receives the message and parses some data
- [10 min] Slides & Demo - API Management
- [15 min] Hands on - Create an API within API-M, create an API operation to call the Logic App, and test it end to end
- [ 5 min] Slides & Demo - Application Insights
- [10 min] Hands on - Use Application Insights to trace an execution from API-M through all Logic App workflows
- Optional: [10 min] Slides & Demo - Integration Environments & Business Process tracking
- Optional: [10 min] Hands on - Create an Integration Environment application, and use Business Process tracking to monitor the execution of the Logic App workflows

## Clean up:
```bash
az group delete --name $RG
```