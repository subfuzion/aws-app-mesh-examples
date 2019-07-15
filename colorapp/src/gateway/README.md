## gateway app environment variables

* COLOR_TELLER_ENDPOINT - (required) name:port for the colorteller service (ex: `colorteller.svc.local:9080`)
* TCP_ECHO_ENDPOINT - (optional) name:port for the tcp echo service
* ENABLE_ENVOY_XRAY_TRACING - (optional) set to "1" to emit traces for AWS X-Ray
* SERVER_PORT - (optional) override default listening port (8080)

## gateway image

You can use a gateway image from either of these repos:

* 226767807331.dkr.ecr.us-west-2.amazonaws.com/gateway (ECR for AWS accounts only)
* subfuzion/colorgateway (public Docker Hub)

You can use `deploy.sh` to build and push a gateway image to
your own ECR repo. Make sure you have created a `gateway` repo under your
account first.


