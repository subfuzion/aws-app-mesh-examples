#!/usr/bin/env bash
#
# This script will deploy a CloudFormation stack for the App Mesh example Vote App VPC.
# It uses vpc.yaml in the same directory as the script for setting up the VPC.
#
# Ensure that the following environment variables are defined:
# ENVIRONMENT_NAME (the friendly prefix for CloudFormation stack resources; ex: "appmesh-demo")
#
# The following environment variables can optionally be defined:
# AWS_DEFAULT_PROFILE (the AWS CLI named profile to use; overrides "default")
# AWS_DEFAULT_REGION (overrides configured region for the profile)
# NOTE: for public preview, region must be one of: us-west-2 | us-east-1 | us-east-2 | eu-west-1 
#
# Example:
# export ENVIRONMENT_NAME=appmesh-demo      # required
# export AWS_DEFAULT_PROFILE="tony"         # optional, overrides default profile
# export AWS_DEFAULT_REGION="us-west-2"     # optional, overrides region for tony

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
TEMPLATE="vpc.yaml"

required_env=(
    ENVIRONMENT_NAME
)

suggested_env=(
    AWS_DEFAULT_PROFILE
    AWS_DEFAULT_REGION
)

supported_regions=(
    eu-west-1
    us-east-1
    us-east-2
    us-west-2
)

print() {
    printf "%s\n" "$*"
}

err() {
    msg="Error: $1"
    print $msg
    code=${2:-"1"}
    exit $code
}

# Ensure AWS_PROFILE exists; otherwise exit with error
# post-condition: AWS_PROFILE is valid
check_profile() {
    AWS_PROFILE=${AWS_DEFAULT_PROFILE:-"default"}
    errmsg=$(aws configure get profile --profile ${AWS_PROFILE} 2>&1 >/dev/null)
    [[ -n $errmsg ]] && err "The config profile (${AWS_PROFILE}) could not be found"
    print "profile=${AWS_PROFILE}"
}

# Ensure AWS_REGION is valid; otherwise exit with error
# pre-condition: AWS_PROFILE is valid
# post-condition: AWS_REGION is valid
check_region() {
    local region=${AWS_DEFAULT_REGION}
    if [ -z $region ]; then
        region=$(aws configure get region --profile ${AWS_PROFILE})
    fi

    for i in "${supported_regions[@]}"; do
        # supported region, so update AWS_REGION and return
        if [ "$i" = "$region" ]; then
            print "region=$i"
            AWS_REGION=$region
            return
        fi
    done
    err "Either your profile or AWS_DEFAULT_REGION must specify a valid region (unsupported: ${AWS_REGION})"
}

# Ensure environment is valid
check_env() {
    for i in "${suggested_env[@]}"; do
        [ -z "${!i}" ] && print "$i ... not set (will use defaults or ignore)"
    done

    check_profile
    check_region

    for i in "${required_env[@]}"; do
        print "$i=${!i}"
        [ -z "${!i}" ] && err "$i must be set"
    done
}

deploy() {
    print "Deploy VPC..."
    print "${DIR}/${TEMPLATE}"
    aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
        cloudformation deploy \
        --stack-name "${ENVIRONMENT_NAME}-vpc" \
        --capabilities CAPABILITY_IAM \
        --template-file "${DIR}/${TEMPLATE}" \
        --parameter-overrides \
        EnvironmentName="${ENVIRONMENT_NAME}"
}

main() {
    # sanity check for App Mesh public preview
    check_env

    # Create or update the VPC stack
    deploy
}

main $@
