---
title: AWS EventBridge - Create a PagerDuty incident in response to OAuth client deletes
author: ronan.watkins
indextype: blueprint
icon: blueprint
image: images/arch-eventbridge-lambda.png
category: 6
summary: |
  This Genesys Cloud Developer Blueprint provides an example of a Lambda function that creates a PagerDuty incident in response to OAuth client deletes. This blueprint includes a SAM template with Typescript and Python Lambda functions for the CloudFormation stack used in this blueprint.
---

This Genesys Cloud Developer Blueprint provides an example of a Lambda function that creates a PagerDuty incident in response to OAuth client deletes. This blueprint includes a SAM template with Typescript and Python Lambda functions for the CloudFormation stack used in this blueprint.

![Create a PagerDuty incident in response to OAuth Client deletes](images/arch-eventbridge-lambda.png "Diagram for the AWS EventBridge - Create a PagerDuty incident in response to OAuth client deletes blueprint")

* [Solution components](#solution-components "Goes to the Solutions components section")
* [Software development kits (SDKs)](#software-development-kits-sdks "Goes to the Software development kits (SDKs) section")
* [Prerequisites](#prerequisites "Goes to the Prerequisites section")
* [Implementation steps](#implementation-steps "Goes to the Implementation steps section")
* [Additional resources](#additional-resources "Goes to the Additional resources section")

## Solution components

* **[PagerDuty](https://www.pagerduty.com/ "Opens the PagerDuty website")** - An incident management platform that provides reliable notifications, automatic escalations, on-call scheduling, and related functionality to help teams detect and fix infrastructure problems quickly.
* **[AWS Serverless Application Model (SAM) Command Line Interface (CLI)](https://aws.amazon.com/serverless/sam/ "Opens the AWS SAM CLI website")** - A cross-platform CLI that provides a Lambda-like execution environment for locally building, testing, and debugging applications defined by SAM templates.
* **[AWS Lambda](https://aws.amazon.com/lambda/ "Opens the AWS Lambda website")** - A serverless computing service for running code without creating or maintaining the underlying infrastructure.
* **[Amazon EventBridge](https://aws.amazon.com/eventbridge/ "Opens the Amazon EventBridge website")** - A scalable, serverless event bus that streams real-time data to selected targets based on custom routing rules.
* **[AWS CloudFormation](https://aws.amazon.com/cloudformation/ "Opens the AWS CloudFormation website")** - A service that gives developers and businesses an easy way to create a collection of related AWS and third-party resources, and provision and manage them in an orderly and predictable fashion.
* **[Node.js](https://nodejs.org/en/ "Opens the NodeJs website")** - An open-source, cross-platform JavaScript runtime environment.
* **[Python](https://www.python.org/ "Opens the Python website")** - An interpreted, high-level programming language that is used to quickly build modularized, object-oriented programs.

## Software development kits (SDKs)

* **[PDJS](https://github.com/PagerDuty/pdjs "Opens the PDJS repo in GitHub")** - A JavaScript wrapper that allows convenient access to the PagerDuty APIs.
* **[python-pagerduty](https://github.com/PagerDuty/python-pagerduty "Opens the python-pagerduty repo in GitHub")** - A Python client that simplifies access to the PagerDuty REST API and PagerDuty Events API.

## Prerequisites

### Specialized knowledge

* AWS Cloud Practitioner-level knowledge of AWS CloudFormation, AWS IAM, AWS Lambda, AWS SAM CLI, Amazon DynamoDB, and Amazon EventBridge
* Familiarity with PagerDuty and the PagerDuty REST API
* Experience with TypeScript, JavaScript or Python

### Genesys Cloud account

* A Genesys Cloud license. For more information, see [Genesys Cloud pricing](https://www.genesys.com/pricing "Opens the Genesys Cloud pricing page") on the Genesys website.

### AWS user account  

* An administrator account with permissions to access the following services:
  * AWS Identity and Access Management (IAM)
  * AWS Lambda
* AWS credentials. For more information about setting up your AWS credentials on your local machine, see [The shared config and credentials files](https://docs.aws.amazon.com/sdkref/latest/guide/creds-config-files.html "Opens The shared config and credentials files on the About credential providers page") in AWS documentation.
* AWS SAM CLI version 1.23.0 or later. For more information, see [Install AWS SAM](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html "Opens Installing AWS SAM CLI") on the AWS website.

### PagerDuty account

* An account that can generate an API Key.
* A service where you want the incident to be reported.

### Third-party software

* Python version 3.9.0 or later. For more information, see [Download Python](https://www.python.org/downloads/ "Opens Download the latest version of Python") on the Python website.
* Node.js version 20.0.0 or later. For more information, see [Node.js](https://nodejs.org/en/ "Opens Download Node.js") on the Node.js website.

## Implementation steps

* [Clone the repository that contains the project files](#clone-the-repository-that-contains-the-project-files "Goes to the Clone the repository that contains the project files section")
* [Enable the Amazon EventBridge integration in your Genesys Cloud Organization](#enable-the-amazon-eventbridge-source-integration-in-your-genesys-cloud-organization "Goes to the Enable the Amazon EventBridge integration in your Genesys Cloud account section")
* [Configure your EventBridge software as a service (SaaS) integration](#configure-your-eventbridge-software-as-a-service-saas-integration "Goes to the Configure your EventBridge software as a service (SaaS) integration section")
* [Configure and fetch PagerDuty details](#configure-and-fetch-pagerduty-details  "Goes to the Configure and fetch PagerDuty details section")
* [Build and Deploy the application](#build-and-deploy-the-application "Goes to the Deploy the application section")
  * [via AWS SAM CLI](#via-aws-sam-cli "Goes to the via AWS SAM CLI section")
  * [via Terraform](#via-terraform "Goes to the via Terraform section")
* [Delete an OAuth client](#delete-an-oauth-client "Goes to the Delete an OAuth client section")
* [Run locally](#run-locally "Goes to the Run locally section")

### Clone the repository that contains the project files

Clone the [aws-eventbridge-oauth-client-delete-blueprint](https://github.com/GenesysCloudBlueprints/aws-eventbridge-oauth-client-delete-blueprint "Opens the aws-eventbridge-oauth-client-delete-blueprint") repository in GitHub.

### Enable the Amazon EventBridge Source integration in your Genesys Cloud organization

1. In Genesys Cloud, install an Amazon EventBridge Source integration. For more information, see [Install Amazon EventBridge integration from Genesys AppFoundry](https://help.mypurecloud.com/?p=228013 "Goes to the Install Amazon EventBridge integration from Genesys AppFoundry article") in the Genesys Cloud Resource Center.

2. Configure the integration with the following settings:

* **AWS Account ID**: Your AWS account ID
* **AWS Account region**: Your [AWS account region](/api/rest/ "Goes to the Platform API page in the Genesys Cloud Developer Center")
* **Event Source Suffix**: Your preferred suffix that identifies the source of the events
* **Topic Filtering**: Select `v2.audits.entitytype.{id}.entityid.{id}`. This value corresponds to the event action on the AWS Lambda function.

![Topic filtering](images/topic-filtering.png "Topic filtering selection")

### Configure your EventBridge software as a service (SaaS) integration

1. In your AWS account, configure your [EventBridge software as a service (SaaS)](https://console.aws.amazon.com/events/home?region=us-east-1#/partners "Opens your AWS management console") integration.
2. Make a note of the event source name (for example, `aws.partner/example.com/1234567890/test-event-source`).
3. Before proceeding to the next step, verify that your event source is listed as **Pending**.

### Configure and Fetch PagerDuty Details

You will be needing a PagerDuty API Key and the PagerDuty Service ID to send the OAuth Deletion notification. For more information about creating a PagerDuty API key and Service, see [Generating API Keys](https://support.pagerduty.com/docs/generating-api-keys "Opens the Generating API Keys") and [Create a Service](https://support.pagerduty.com/main/docs/services-and-integrations#create-a-service "Opens Create a Service") on the PagerDuty website. You can also see the ID of the service you want to direct the incident when checking the URL when viewing the specific service that you want. The url looks like this `https://your-company-name.pagerduty.com/service-directory/the-service-id`.

If you don't want to use either of the Lambda functions, remove the source code for them and references to them from `template.yaml`.

### Build and deploy the application

#### via AWS SAM CLI

You must build the application before you deploy it. The SAM CLI resolves the dependencies of both Lambda functions, builds them, and stores the artifacts in a directory named `.aws-sam`.  

1. From the repo root, run the following command:

  ```
  sam build
  ```

2. Deploy the application. The following command uses CloudFormation to create the necessary resources for this application (roles, Lambdas, DynamoDB table, and so on).

  :::primary
  **Note**: This command creates resources in your AWS account and incurs costs. You must be authenticated to use the CLI before running the following command.
  :::

  ```
  sam deploy --guided
  ```

3. When you are prompted, choose an appropriate stack name.  
4. Verify that the `EventSourceName` parameter contains the event source name that you noted in the [Configure your EventBridge software as a service (SaaS) integration](#configure-your-eventbridge-software-as-a-service-saas-integration "Goes to the Configure your EventBridge software as a service (SaaS) integration section") step and the `PagerDutyToken` and `PagerDutyServiceId` you got in [Configure and fetch PagerDuty details](#configure-and-fetch-pagerduty-details  "Goes to the Configure and fetch PagerDuty details section") step.

#### via Terraform

1. Go to the `src/terraform` folder and initialize the Terraform configuration:

  ```bash
  terraform init
  ```

2. Provide the necessary details in the `dev.auto.tfvars` file like the AWS region, [EventBridge Source Name](#configure-your-eventbridge-software-as-a-service-saas-integration), [PagerDuty API Token, and the ID of your selected PagerDuty Service](#configure-and-fetch-pagerduty-details  "Goes to the Configure and fetch PagerDuty details section"). Also, ensure that you have provided the following environment variables in `dev.env.sh`. You may also run the command `source dev.env.sh` once you assign the appropriate values in the file.

3. Once provided, run `terraform plan` to check and verify the details.

4. Once checked, run `terraform apply -auto-approve` to deploy the resources.

### Delete an OAuth client

:::primary
**Note**: Take extra care not to delete an existing OAuth client that is currently used in your production environment.
:::

If you have the permissions to create and delete OAuth clients in Genesys Cloud, follow the instructions to [Create an OAuth client](https://help.mypurecloud.com/?p=188023). Then, delete the OAuth client in order to trigger the Lambda functions.  

If you do **not** have the permissions to create and delete OAuth clients, use the event body located in `events/OAuthClientDelete.json` to trigger the Lambda functions:

1. Find the stack by searching the [CloudFormation console](https://console.aws.amazon.com/cloudformation/home "Opens the CloudFormation console in the AWS website").
2. Open the Lambda function. The `Logical ID` is `EventBridgeFunctionNode` for the TypeScript Lambda and `EventBridgeFunctionPython` for the Python Lambda.
3. From the **Test** tab, paste the event from `events/OAuthClientDelete.json` and click **Test**.
4. Review the logs from the function invocation.
5. To see if the Lambda function successfully created the incident, use the PagerDuty console.

## Run locally

For debugging purposes, you can run the Python and TypeScript functions for this solution locally.

### Pre-step

Go to `run_local.sh` in the root of the repository and provide the `PAGER_DUTY_API_KEY` and `PAGER_DUTY_SERVICE_ID` from [Configure and fetch PagerDuty details](#configure-and-fetch-pagerduty-details  "Goes to the Configure and fetch PagerDuty details section") step.

### Run locally using the TypeScript functions

1. Log a user presence update event to CloudWatch and save the contents to the `events/UserPresenceChange.json` file.  

2. Install the dependencies from the `src/typescript` folder:

  ```
  npm install
  ```

3. From the root folder of the blueprint repository, run the following command:

  ```
  ./run_local.sh node
  ```

### Run locally using the Python functions

1. Log a user presence update event to CloudWatch and save the contents to the `events/UserPresenceChange.json` file.  

2. Install the dependencies from the  `src/python` folder:  

  ```
  pip3 install -r requirements.txt
  ```

3. Execute the following command:

  ```
  /.run_local.sh python
```

### Run locally using the SAM CLI

:::primary
**Note**: This is only applicable when you used AWS SAM CLI to deploy this solution.
:::

To run the Lambdas locally and imitate the AWS Lambda environment, use the following commands.

Python:

```
sam local invoke EventBridgeFunctionPython --event ./events/OAuthClientDelete.json
```

TypeScript:

```
sam local invoke EventBridgeFunctionNode --event ./events/OAuthClientDelete.json
```

## Additional resources

* [SAM CLI developer guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-command-reference.html "Opens the SAM CLI developer guide")
* [AWS EventBridge user guide](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-what-is.html "Opens the AWS EventBridge user guide")
* The [aws-eventbridge-oauth-client-delete-blueprint](https://github.com/GenesysCloudBlueprints/aws-eventbridge-oauth-client-delete-blueprint "Opens the aws-eventbridge-oauth-client-delete-blueprint repository in GitHub") repository in GitHub
