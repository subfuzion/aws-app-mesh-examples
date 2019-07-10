#!/usr/bin/env bash
set -e

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)
SCRIPT="$(basename "$0")"

usage() {
  echo "Usage: $SCRIPT app|mesh"

}

info () {
  echo "Environment:"
  echo "AWS_DEFAULT_REGION  = ${AWS_DEFAULT_REGION}"
  echo "AWS_DEFAULT_PROFILE = ${AWS_DEFAULT_PROFILE}"
  echo "RESOURCE_PREFIX     = ${RESOURCE_PREFIX}"
  echo
}

deploy_stack() {
  [[ -z $1 ]] && echo "deploy_stack: missing stack name" && exit 1

  local stack="$1"
  local stackname="${RESOURCE_PREFIX}-${stack}"
  local template="${DIR}/${stack}.yaml"

  echo "deploy ${stackname} (${stack}.yaml) ..."

  aws --region "${AWS_DEFAULT_REGION}" \
    cloudformation deploy \
    --no-fail-on-empty-changeset \
    --stack-name "$stackname" \
    --template-file "${template}" \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
    Prefix="${RESOURCE_PREFIX}"

  echo
}

delete_stack() {
  [[ -z $1 ]] && echo "delete_stack: missing stack name" && exit 1
  local stack="$1"
  local stackname="${RESOURCE_PREFIX}-${stack}"

  echo "delete stack: ${stackname} ..."
  aws --region "${AWS_DEFAULT_REGION}" \
    cloudformation delete-stack \
    --stack-name "${stackname}"

  aws --region "${AWS_DEFAULT_REGION}" \
    cloudformation wait stack-delete-complete \
    --stack-name "${stackname}"

  echo
}

deploy_vpc() {
  deploy_stack "vpc"
}

deploy_cluster() {
  deploy_stack "cluster"
}

deploy_gateway() {
  deploy_stack "gateway"
}

deploy_blue() {
  deploy_stack "blue"
}

deploy_green() {
  deploy_stack "green"
}

deploy_mesh() {
  deploy_stack "mesh"
}

confirm_service_linked_role() {
  if ! aws iam get-role --role-name AWSServiceRoleForAppMesh >/dev/null; then
    echo "Error: no service linked role for App Mesh"
    exit 1
  fi
}

print_endpoints() {
  local stackname="${RESOURCE_PREFIX}-$1"

  echo
  echo "Endpoints:"
  echo "=========="
  local url=$(aws cloudformation describe-stacks \
    --stack-name="${stackname}" \
    --query="Stacks[0].Outputs[?OutputKey=='PublicURL'].OutputValue" \
    --output=text)
  echo "1. get color        :  "${url}"/color"
  echo "2. clear histogram  :  "${url}"/color/clear"
  echo
}

deploy_app() {
  deploy_vpc
  deploy_cluster
  deploy_gateway
  deploy_blue

  confirm_service_linked_role
  print_endpoints "cluster"
}

delete_all() {
  delete_stack "green"
  delete_stack "blue"
  delete_stack "gateway"
  delete_stack "cluster"
  delete_stack "vpc"
}

main() {
  local arg=$1

  info

  case $arg in
  app) deploy_app ;;
  vpc) deploy_vpc ;;
  cluster) deploy_cluster ;;
  gateway) deploy_gateway ;;
  blue) deploy_blue ;;
  green) deploy_green ;;
  mesh) deploy_mesh ;;
  url) print_endpoints ;;
  delete-stack) delete_stack $2 ;;
  delete-all) delete_all ;;
  *)
    usage
    exit 1
    ;;
  esac
}

main "$@"
