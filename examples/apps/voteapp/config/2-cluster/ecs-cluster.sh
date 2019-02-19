#!/usr/bin/env bash
#
# This script will deploy a CloudFormation stack for the App Mesh example Vote App ECS cluster.
# It uses ecs-cluster.yaml in the same directory as the script for setting up the cluster.
#
# Ensure that the following environment variables are defined:
# ENVIRONMENT_NAME (the friendly prefix for CloudFormation stack resources; ex: "appmesh-demo")
#
# The following environment variables can optionally be defined:
# AWS_DEFAULT_PROFILE (the AWS CLI named profile to use; overrides "default")
# AWS_DEFAULT_REGION (overrides configured region for the profile)
# NOTE: for public preview, region must be one of: us-west-2 | us-east-1 | us-east-2 | eu-west-1 
# KEY_NAME (the Amazon EC2 key pair name for ssh access to bastion host in cluster)
# SERVICES_DOMAIN (domain under which mesh services in the cluster will be discovered)
#
# Example:
# export ENVIRONMENT_NAME=appmesh-demo              # required
# export AWS_DEFAULT_PROFILE="tony"                 # optional, overrides default profile
# export AWS_DEFAULT_REGION="us-west-2"             # optional, overrides region for tony
# export CLUSTER_SIZE=5                             # optional, defaults to 5 ECS nodes
# export KEY_NAME="id_rsa"                          # optional, key pair name for ssh to bastion host in cluster
# export SERVICES_DOMAIN="demo.svc.cluster.local"   # optional, defaults to "default.svc.cluster.local"


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
TEMPLATE="ecs-cluster.yaml"

required_env=(
    ENVIRONMENT_NAME
)

suggested_env=(
    AWS_DEFAULT_PROFILE
    AWS_DEFAULT_REGION
    CLUSTER_SIZE
    KEY_NAME
    SERVICES_DOMAIN
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
    : ${CLUSTER_SIZE:=5}
    print "CLUSTER_SIZE=${CLUSTER_SIZE}"
    : ${SERVICES_DOMAIN:=default.svc.cluster.local}
    print "SERVICES_DOMAIN=${SERVICES_DOMAIN}"
    print "KEY_NAME=${KEY_NAME}"

    check_profile
    check_region

    for i in "${required_env[@]}"; do
        print "$i=${!i}"
        [ -z "${!i}" ] && err "$i must be set"
    done
}

deploy() {
    print "Deploy ECS cluster..."
    print "${DIR}/${TEMPLATE}"

    if [ -z "${KEY_NAME}" ]; then
        aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
            cloudformation deploy \
            --stack-name "${ENVIRONMENT_NAME}-ecs-cluster" \
            --template-file "${DIR}/${TEMPLATE}" \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                EnvironmentName="${ENVIRONMENT_NAME}" \
                ECSServicesDomain="${SERVICES_DOMAIN}" \
                ClusterSize="${CLUSTER_SIZE}"
    else
        aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" \
            cloudformation deploy \
            --stack-name "${ENVIRONMENT_NAME}-ecs-cluster" \
            --template-file "${DIR}/${TEMPLATE}" \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                EnvironmentName="${ENVIRONMENT_NAME}" \
                KeyName="${KEY_NAME}" \
                ECSServicesDomain="${SERVICES_DOMAIN}" \
                ClusterSize="${CLUSTER_SIZE}"
    fi
}

main() {
    # sanity check for App Mesh public preview
    check_env
    
    # Create or update the ECS cluster
    deploy
}

main $@
