---
title : Azure Policy to restrict personal email addresses in action groups
permalink: /blog/azure-policy-to-restict-action-group-emails.html
type: blogpost
datecreated : 2020-02-19 20:30
category : tech
tags : 
    - azure
    - azure-policy
    - azure-monitor
    - azure-action-group
    - azure-security
    - security
---

## Azure Policy & Action Groups Problem

In enterprises, thousands of alerts will be setup by multiple teams. Each team might have their own subscriptions and own levels of access to create resources. So they can create any type of [Azure action Group](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/action-groups) with any properties. In such scenarios, you might want to have some control over what type of alerts been setup and whom they have been sent. Also we don't want our confidential alerts been sent to random / personal email addresses.

Recently I started writing policies in Azure and I am already in love with that. Azure Policies used to enforce certain rules over your azure resources creation. 
If you don't know much about azure policy, read it in the [official documentation site](https://docs.microsoft.com/en-us/azure/governance/policy/overview). With azure policy, you will have full control of what is being created in your subscriptions. By default azure gives you tons of templated policies. Also you can create your own custom policies based on your needs.

So, We are going to solve our problem of blocking non standard email addresses using Azure policy. Our policy will make sure only allowed email addresses are used in the action groups. 

## Block personal email addresses in Azure Action Group

First, lets define what email addresses we want support. In my case, following are the only valid email addresses.

* Any email addresses like `*@mycompany.com`
* Any email addresses like `*@MYCOMPANY.onmicrosoft.com`
* Any email addresses like `@mycompany.slack.com`
* One of `mycompany@mythirdparty1.com`, `my-company@mythirdparty2.com`

We should block creation of action groups if any other email addresses present. Example, If someone tries to create action group with email address`mycompany@gmail.com` , then block it.

Let's translate this requirement into azure policy.  The critical part of the policy is given below. This checks if the total email addresses not equals to the email addresses not matching the rules. So, we can deny it. 

```json
{
    "allOf": [
        {
            "count": {
                "field": "Microsoft.Insights/actiongroups/emailReceivers[*]",
                "where": {
                    "anyOf": [
                        {
                            "field": "Microsoft.Insights/actiongroups/emailReceivers[*].emailAddress",
                            "like": "*@mycompany.com"
                        },
                        {
                            "field": "Microsoft.Insights/actiongroups/emailReceivers[*].emailAddress",
                            "like": "*@MYCOMPANY.onmicrosoft.com"
                        },
                        {
                            "field": "Microsoft.Insights/actiongroups/emailReceivers[*].emailAddress",
                            "like": "*@mycompany.slack.com"
                        },
                        {
                            "field": "Microsoft.Insights/actiongroups/emailReceivers[*].emailAddress",
                            "like": "mycompany@mythirdparty1.com"
                        },
                        {
                            "field": "Microsoft.Insights/actiongroups/emailReceivers[*].emailAddress",
                            "like": "my-company@mythirdparty2.com"
                        }
                    ]
                }
            },
            "notequals": "[length(field('Microsoft.Insights/actiongroups/emailReceivers[*]'))]"
        }
    ]
}
```

My entire policy looks like this

```json
{
    "properties": {
        "mode": "all",
        "displayName": "Deny personal Email address in action group",
        "description": "This policy denies personal Email addresses in action groups",
        "policyRule": {
            "if": {
                "allOf": [
                    {
                        "field": "type",
                        "equals": "Microsoft.Insights/actionGroups"
                    },
                    {
                        "allOf": [
                            {
                                "count": {
                                    "field": "Microsoft.Insights/actiongroups/emailReceivers[*]",
                                    "where": {
                                        "anyOf": [
                                            {
                                                "field": "Microsoft.Insights/actiongroups/emailReceivers[*].emailAddress",
                                                "like": "*@mycompany.com"
                                            },
                                            {
                                                "field": "Microsoft.Insights/actiongroups/emailReceivers[*].emailAddress",
                                                "like": "*@MYCOMPANY.onmicrosoft.com"
                                            },
                                            {
                                                "field": "Microsoft.Insights/actiongroups/emailReceivers[*].emailAddress",
                                                "like": "*@mycompany.slack.com"
                                            },
                                            {
                                                "field": "Microsoft.Insights/actiongroups/emailReceivers[*].emailAddress",
                                                "like": "mycompany@mythirdparty1.com"
                                            },
                                            {
                                                "field": "Microsoft.Insights/actiongroups/emailReceivers[*].emailAddress",
                                                "like": "my-company@mythirdparty2.com"
                                            }
                                        ]
                                    }
                                },
                                "notequals": "[length(field('Microsoft.Insights/actiongroups/emailReceivers[*]'))]"
                            }
                        ]
                    }
                ]
            },
            "then": {
                "effect": "deny"
            }
        },
        "parameters": {},
        "metadata": {}
    }
}
```

I hope this post gives you some idea of what can be achieved with the policies and now you know how to block non standard email addresses in Action Groups. You can extend this policy to validate other properties like phone numbers, web hook addresses etc.

<Signature />