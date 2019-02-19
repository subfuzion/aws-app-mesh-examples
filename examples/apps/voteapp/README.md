# Vote App

## Prerequisites

## Set up infrastructure

### Deploy VPC

The following environment variables must be set:

This script will deploy a CloudFormation stack template for the Vote App VPC.

Ensure that the following environment variable is defined:

* **ENVIRONMENT_NAME** - the friendly prefix for CloudFormation stack resources (ex: `appmesh-demo`)

Optional [environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html):
* **AWS_DEFAULT_PROFILE** - specifies the name of a CLI profile to use (overrides "default")
* **AWS_DEFAULT_REGION** - specifies the region to use (overrides the CLI profile); for the public preview
  only the following regions are supported: (`us-west-2` | `us-east-1` | `us-east-2` | `eu-west-1`) 

#### Example

```sh
# required
export ENVIRONMENT_NAME=appmesh-demo

# optional, overrides default profile
export AWS_DEFAULT_PROFILE="tony"

# optional, overrides region for "tony"
export AWS_DEFAULT_REGION="us-west-2"
```
