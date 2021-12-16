#!/bin/sh

set -ex

helm repo add emissary-ingress https://s3.amazonaws.com/datawire-static-files/charts || helm repo update

ct "$@"
