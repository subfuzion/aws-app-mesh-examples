## colorteller app environment variables

* COLOR - (optional) override default color (black)
* ENABLE_ENVOY_XRAY_TRACING - (optional) set to "1" to emit traces for AWS X-Ray
* SERVER_PORT - (optional) override default listening port (8080)

## colorteller image

You can use a colorteller image from either of these repos:

* 226767807331.dkr.ecr.us-west-2.amazonaws.com/colorteller (ECR for AWS accounts only)
* subfuzion/colorteller (public Docker Hub)

You can use `deploy.sh` to build and push a colorteller image to
your own ECR repo. Make sure you have created a `colorteller` repo under your
account first.


