# Introducing AWS Management Console support for enabling AWS App Mesh

## Overview

This demo walks through enabling App Mesh support for an ECS/Fargate application using the AWS management console.

## Prerequisites

1. You have version 1.16.178 or higher of the AWS CLI (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) installed.
2. You have cloned the github.com/aws/aws-app-mesh-examples (https://github.com/aws/aws-app-mesh-examples) repo and changed directory to the project root.

## Environment

Set or export the following environment variables with appropriate values for your account, etc.

```
# optional: override your AWS CLI profile
export AWS_DEFAULT_PROFILE=default

# required: the AWS region you want to use
export AWS_DEFAULT_REGION=us-west-1

# required: the prefix to use for all the resources we create
export RESOURCE_PREFIX=demo
```

## Run the Demo without App Mesh

Once your environment is ready, run `walkthroughs/howto-console/deploy.sh`

```
$ walkthroughs/howto-console/deploy.sh app
deploy vpc...
deploy app...
Waiting for changeset to be created..
Waiting for stack create/update to complete
Successfully created/updated stack - demo
http://demo-Public-1G1K8NGKE7VH6-369254194.us-west-1.elb.amazonaws.com
```

Save the endpoint in a variable and curl it to see responses:

```
$ app=http://demo-Public-1G1K8NGKE7VH6-369254194.us-west-1.elb.amazonaws.com
$ curl $app/color
$ ...

## Run the Demo with App Mesh

```
$ walkthroughs/howto-console/deploy.sh mesh
deploy mesh...
Waiting for changeset to be created..
Waiting for stack create/update to complete
Successfully created/updated stack - demo
```

Now enable App Mesh in the console ...
TODO - add instructions