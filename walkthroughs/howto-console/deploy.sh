#!/usr/bin/env bash
set -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )
SCRIPT="$( basename "$0" )"

usage() {
    echo "Usage: $SCRIPT app|mesh"
}

deploy_vpc() {
    aws --region "${AWS_DEFAULT_REGION}" \
        cloudformation deploy \
        --no-fail-on-empty-changeset \
        --stack-name "${RESOURCE_PREFIX}-vpc" \
        --template-file "${DIR}/vpc.yaml" \
        --capabilities CAPABILITY_IAM
}

deploy_mesh() {
    aws --region "${AWS_DEFAULT_REGION}" \
        cloudformation deploy \
        --no-fail-on-empty-changeset \
        --stack-name "${RESOURCE_PREFIX}-mesh" \
        --template-file "${DIR}/mesh.yaml" \
        --capabilities CAPABILITY_IAM
}

deploy_app() {
    local stackname="$1"
    local template="$2"

    aws --region "${AWS_DEFAULT_REGION}" \
        cloudformation deploy \
        --no-fail-on-empty-changeset \
        --stack-name "$stackname" \
        --template-file "${template}" \
        --capabilities CAPABILITY_IAM \
        --parameter-overrides \
          Prefix="${RESOURCE_PREFIX}"
}

confirm_service_linked_role() {
    if ! aws iam get-role --role-name AWSServiceRoleForAppMesh >/dev/null
    then
        echo "Error: no service linked role for App Mesh"
        exit 1
    fi
}

print_endpoint() {
    local stackname=$1

    echo
    echo "Endpoints:"
    echo "=========="
    local url=$(aws cloudformation describe-stacks \
      --stack-name="${stackname}" \
      --query="Stacks[0].Outputs[?OutputKey=='ColorGatewayEndpoint'].OutputValue" \
      --output=text)
    echo "1. get color        :  "${url}"/color"
    echo "2. clear histogram  :  "${url}"/color/clear"
    echo
}

deploy_blue() {
    local stackname="$1"
    local template="${DIR}"/app.yaml

    echo "deploy vpc..."
    deploy_vpc

    echo "deploy app (blue service)..."
    deploy_app "${stackname}" "${template}"

    confirm_service_linked_role
    print_endpoint "${stackname}"
}

deploy_green() {
    local stackname="$1"

    echo "deploy update (green service)..."
    deploy_app "${stackname}" "${DIR}"/green.yaml
    print_endpoint "${stackname}"
}

deploy_both() {
  deploy_blue "$1"
  deploy_green "$2"
}

deploy_mesh_only() {
    echo "deploy mesh..."
    deploy_mesh
}

main() {
    local arg=$1
    local bluestack="${RESOURCE_PREFIX}"-app
    local greenstack="${RESOURCE_PREFIX}"-green

    case $arg in
        app) deploy_blue "${bluestack}" ;;
        update) deploy_green "${greenstack}" ;;
        both) deploy_both "${bluestack}" "${greenstack}" ;;
        mesh) deploy_mesh_only ;;
        url) print_endpoint "${bluestack}" ;;
        *) usage; exit 1 ;;
    esac
}

main "$@"

