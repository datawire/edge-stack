#!/bin/sh

set -ex

helm repo add emissary-ingress https://s3.amazonaws.com/datawire-static-files/charts-dev || helm repo update

ct "$@"
