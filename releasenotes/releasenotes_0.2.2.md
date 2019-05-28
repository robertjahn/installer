# Release Notes 0.2.2

This is the first release of the keptn installer, which has been extraced from the [keptn repository](https://github.com/keptn/keptn).

## New Features
- Dynatrace-managed tenants are supported [#255](https://github.com/keptn/keptn/issues/255)
- Deploys dynatrace-service when Dynatrace monitoring is activated [#354](https://github.com/keptn/keptn/issues/354)
- Deploys [keptn's bridge](https://github.com/keptn/bridge)

## Fixed Issues
- Removed Istio service entries, which were used for communication to a Dynatrace tenant [#222](https://github.com/keptn/keptn/issues/222)
- Improvements of install script for Dynatrace [352](https://github.com/keptn/keptn/issues/352)

## Version dependencies:

keptn is installed by using these images from the [keptn Dockerhub registry](https://hub.docker.com/u/keptn):

- keptn/installer:0.2.2
- keptn/authenticator:0.2.2
- keptn/control:0.2.2
- keptn/eventbroker:0.2.2
- keptn/eventbroker-ext:0.2.2
- keptn/pitometer-service:0.1.2
- keptn/servicenow-service:0.1.1
- keptn/github-service:0.2.0
- keptn/jenkins-service:0.3.0
- keptn/jenkins:0.6.0
  
## Known Limitations
