---
title : Deploy Azure management groups at Scale using Azure Devops
permalink: /blog/azure-management-groups-at-scale-using-azure-devops.html
type: blogpost
datecreated : 2020-07-02 10:00
category : tech
tags : 
    - azure
    - azure-arm
    - azure-resource-manager
    - azure-management-groups
    - azure-landing-zones
    - azure-devops
    - devops
---

When working with 100s of Azure subscriptions, you may need to organize them into groups. When you group your subscriptions in to groups, you can assign roles, assign polices and manage your subscriptions easily. In this post, we will be using **Azure Management Groups** to organize the subscriptions and we will be using Azure Devops to deploy these templates.

[Source Code available here](https://github.com/yesoreyeram/azure-deploy)

[Pipelines Available here](https://sriramajeyam.visualstudio.com/azure-deploy/_build?definitionId=7)

### Management Group Structure Definition

 For the demo, I have created 10 subscriptions and I want to group them as follows.

* Tenant Management Group
    * Hello ( Management Group )
        * Hello Platforms ( Management Group )
            * Hello Platforms Prod ( Management Group )
                * 3 x Subscriptions
            * Hello Platforms NonProd ( Management Group )
                * 2 x Subscriptions
        * Hello Payments ( Management Group )
            * Hello Payments Prod ( Management Group )
                * 2 x Subscriptions
            * Hello Payments NonProd ( Management Group )
                * 3 x Subscriptions

Once I created the management groups, I would like to move my subscriptions into it accordingly. Also, I am interested to assign tags to my subscriptions and setup budget alerts to all the subscriptions. We will be using Azure Devops Pipelines to deploy this.

### Connection Setup

First step is to create a SPN with `Contributor` and `User Access Administrator` role at tenant level as mentioned [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-tenant#required-access). This can be done using the following command

`az role assignment create --assignee "SPN_CLIENT_ID_GOES_HERE" --scope "/" --role "Contributor"`

`az role assignment create --assignee "SPN_CLIENT_ID_GOES_HERE" --scope "/" --role "User Access Administrator"`

As mentioned in the document, this should be executed by **Global Admins** who also have **User Access Administrator** access at root level.

Once the SPN is created, Create the corresponding **Service Connection** in Azure Devops. Azure Resource Manager Service connection is created using **Management Group** level scope. Specify your Tenant ID as the management group id / Name. For the demo, I have created a service connection with the name `yesoreyeram-demo-demo-tenant-contributor`

### Pipeline Setup

Azure devops pipeline was created using the Template available [here](https://github.com/yesoreyeram/azure-deploy/blob/master/azure-pipelines/tenant_with_management_groups.yml). The pipeline has two stages

* Build
    * Build artifacts 
* Deploy
    * Deploy to environment called `tenant-demo` and the service connection `yesoreyeram-demo-demo-tenant-contributor`. 

At the time of writing, Azure devops resource manager doesn't support tenant level deployment. So as a workaround, I am using **AzureCLI@2** task.

### Template walk-through

Our ARM template which is defined [here](https://github.com/yesoreyeram/azure-deploy/blob/master/arm-templates/tenant_with_management_groups.json), does the following things.

* Create a root management group
* Create child management group hierarchy
* Assign subscriptions to the management groups
* Setup Tags and Budget alerts for all the subscriptions

### Create root management group

Template expects a parameter called `RootManagmentGroup` which will be used as root management group. This is created using the following template.

```
{
    "type": "Microsoft.Management/managementGroups",
    "apiVersion": "2020-02-01",
    "name": "[parameters('RootManagmentGroup')]",
    "properties": {
        "displayName": "[parameters('RootManagmentGroup')]"
    }
}
```

### Create Child management hierarchy

Hierarchy of the child management groups are passed to the template as a parameter `ManagementGroups`. The parameter is an array of management groups. Structure of the management group parameter is given below.

```
{
    "ManagementGroups": {
        "type": "array",
        "defaultValue": [
            { "Name": "Platforms Hello", "Id": "HelloPlatforms", "ParentManagementGroupId": "Hello" },
            { "Name": "Platforms Hello Prod", "Id": "HelloPlatformsProd", "ParentManagementGroupId": "HelloPlatforms" },
            { "Name": "Platforms Hello NonProd", "Id": "HelloPlatformsNonProd", "ParentManagementGroupId": "HelloPlatforms" },
            { "Name": "Payments Hello", "Id": "HelloPayments", "ParentManagementGroupId": "Hello"},
            { "Name": "Payments Hello Opex", "Id": "HelloPaymentsOpex", "ParentManagementGroupId": "HelloPayments" },
            { "Name": "Payments Hello Capex", "Id": "HelloPaymentsCapex", "ParentManagementGroupId": "HelloPayments"}
        ]
    }
}
```

All the management groups and their parents are defined in the hierarchy. Then using `copy` method of the ARM template, each management group is created as shown below

```
{
        "type": "Microsoft.Management/managementGroups",
        "apiVersion": "2020-02-01",
        "name": "[parameters('ManagementGroups')[copyIndex()].Id]",
        "dependsOn": ["[parameters('ManagementGroups')[copyIndex()].ParentManagementGroupId]"],
        "copy": {
            "name": "managmentgroups",
            "count": "[length(parameters('ManagementGroups'))]"
        },
        "properties": {
            "displayName": "[parameters('ManagementGroups')[copyIndex()].Name]",
            "details": {
                "parent": {
                    "id": "[tenantResourceId('Microsoft.Management/managementGroups', parameters('ManagementGroups')[copyIndex()].ParentManagementGroupId )]"
                }
            }
        }
    }
```

### Assignment of subscriptions to the management groups.

All our 10 subscriptions will be moved to corresponding management groups. To achieve this, we are passing the list of subscriptions to the template as parameter. The structure of the `` param is given below.

```
{
    "subscriptions": {
            "type": "array",
            "defaultValue": [
                { "SubscriptionId": "0b65b765-1294-4e4f-9dca-b513ef0ac3b9", "ManagementGroupId": "HelloPlatformsProd", "SubscriptionName": "HelloMarketplace", "PlatformName": "Marketplace", "ContactEmail":"noreply@foo.com", "Environment":"Production", "CostType":"Opex" , "MonthlyBudget": 30000, "CostAlertsEmail":["noreply@foo.com"]},
                { "SubscriptionId": "1f7c433c-e913-42bb-9f16-ee54cf5913b9", "ManagementGroupId": "HelloPlatformsProd", "SubscriptionName": "HelloOrders", "PlatformName": "Orders", "ContactEmail":"noreply@foo.com", "Environment":"Production", "CostType":"Opex" , "MonthlyBudget": 40000, "CostAlertsEmail":["noreply@foo.com"]},
                { "SubscriptionId": "fc2be19c-f9f0-420d-9ccc-b175e3e5498e", "ManagementGroupId": "HelloPlatformsProd", "SubscriptionName": "HelloPlatformEngineering", "PlatformName": "Engineering", "ContactEmail":"noreply@foo.com", "Environment":"Production", "CostType":"Opex" , "MonthlyBudget": 20000, "CostAlertsEmail":["noreply@foo.com"]},
                { "SubscriptionId": "bc3d2d69-555c-4678-a68f-34085833d9ce", "ManagementGroupId": "HelloPlatformsNonProd", "SubscriptionName": "HelloMarketplaceNonProd", "PlatformName": "Marketplace", "ContactEmail":"noreply@foo.com", "Environment":"Non-Production", "CostType":"Capex" , "MonthlyBudget": 2000, "CostAlertsEmail":["noreply@foo.com"]},
                { "SubscriptionId": "61efcc2f-f2ce-4eae-915b-656950cae015", "ManagementGroupId": "HelloPlatformsNonProd", "SubscriptionName": "HelloAppsNonProd", "PlatformName": "Apps", "ContactEmail":"noreply@foo.com", "Environment":"Non-Production", "CostType":"Capex" , "MonthlyBudget": 2000, "CostAlertsEmail":["noreply@foo.com"]},
                { "SubscriptionId": "40adf8ce-e2ea-49b1-a84e-e17f98119729", "ManagementGroupId": "HelloPaymentsOpex", "SubscriptionName": "HelloFinance", "PlatformName": "Finance", "ContactEmail":"noreply@foo.com", "Environment":"Production", "CostType":"Opex" , "MonthlyBudget": 50000, "CostAlertsEmail":["noreply@foo.com"]},
                { "SubscriptionId": "c365c73b-1aab-4a9b-ac31-4b8bcf48fbdc", "ManagementGroupId": "HelloPaymentsOpex", "SubscriptionName": "HelloPaymentsSecure", "PlatformName": "Payments", "ContactEmail":"noreply@foo.com", "Environment":"Production", "CostType":"Opex" , "MonthlyBudget": 30000, "CostAlertsEmail":["noreply@foo.com"]},
                { "SubscriptionId": "53cd1729-8cf8-4fc7-b648-3017a8f0be0b", "ManagementGroupId": "HelloPaymentsCapex", "SubscriptionName": "HelloPaymentsDev", "PlatformName": "Payments", "ContactEmail":"noreply@foo.com", "Environment":"Non-Production", "CostType":"Capex" , "MonthlyBudget": 3000, "CostAlertsEmail":["noreply@foo.com"]},
                { "SubscriptionId": "857ab2c1-be7c-408d-b463-43b08d866f33", "ManagementGroupId": "HelloPaymentsCapex", "SubscriptionName": "HelloPaymentsNonProd", "PlatformName": "Payments", "ContactEmail":"noreply@foo.com", "Environment":"Non-Production", "CostType":"Capex" , "MonthlyBudget": 1000, "CostAlertsEmail":["noreply@foo.com"]},
                { "SubscriptionId": "dd47879e-07fe-4c27-8489-40ff43dce93b", "ManagementGroupId": "HelloPaymentsCapex", "SubscriptionName": "HelloPaymentsSecureNonProd", "PlatformName": "Payments", "ContactEmail":"noreply@foo.com", "Environment":"Non-Production", "CostType":"Capex", "MonthlyBudget": 3000, "CostAlertsEmail":["noreply@foo.com"] }
            ]
        }
}
```

The key here is `SubscriptionId` and `ManagementGroupId`.  Based on the two properties, all the subscriptions moved to corresponding management groups as shown below.

```
 {
        "type": "Microsoft.Management/managementGroups/subscriptions",
        "apiVersion": "2020-02-01",
        "name": "[concat( parameters('subscriptions')[copyIndex()].ManagementGroupId ,'/', parameters('subscriptions')[copyIndex()].SubscriptionId  )]",
        "dependsOn": [
            "[parameters('subscriptions')[copyIndex()].ManagementGroupId]"
        ],
        "copy": {
            "name": "subscriptions_mgmgt_group_association",
            "count": "[length(parameters('subscriptions'))]"
        },
        "properties": {}
    }
```

### Assigning Tags to subscriptions and Budgets.

While passing the subscriptions parameter, we also pass few meta data for the subscription like Platform, Environment, CostType, Budget and whom we want to alert during any specified events.
Based on these data, following two resources been deployed on each subscriptions iteratively.

##### Subscription Tags
```
{
    "apiVersion": "2019-10-01",
    "type": "Microsoft.Resources/tags",
    "name": "default",
    "properties": {
        "tags": {
            "Platform": "[parameters('subscriptions')[copyIndex()].PlatformName]",
            "Environment": "[parameters('subscriptions')[copyIndex()].Environment]",
            "CostType": "[parameters('subscriptions')[copyIndex()].CostType]"
        }
    }
}
```

##### Subscription Budget

```
 {
    "type": "Microsoft.Consumption/budgets",
    "apiVersion": "2019-10-01",
    "name": "[concat('Subscription_Budget_',parameters('subscriptions')[copyIndex()].SubscriptionName)]",
    "properties": {
        "category": "Cost",
        "timeGrain": "BillingMonth",
        "amount": "[parameters('subscriptions')[copyIndex()].MonthlyBudget]",
        "timePeriod": {
            "startDate": "2020-05-01T00:00:00.0Z"
        },
        "notifications": {
        }
    }
 }
```

### Conclusion

With the power of ARM template, we have bootstrapped our tenant. From this you can understand that, we can build entire the tenant from scratch using **Infra as a config**. With the power of Azure Devops, We have also automated the deployment and secured our pipelines with polices.

[Source Code available here](https://github.com/yesoreyeram/azure-deploy)

[Pipelines Available here](https://sriramajeyam.visualstudio.com/azure-deploy/_build?definitionId=7)

<Signature />