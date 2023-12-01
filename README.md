Ambassador Edge Stack [![Build Status][build-status]][build-pages]
 [![Docker Repository][docker-latest]][docker-repo] ![Docker Pulls][docker-pulls] [![Join Slack][slack-join]][slack-url]
==========

[build-pages]:   https://travis-ci.org/datawire/ambassador
[build-status]:  https://travis-ci.org/datawire/ambassador.png?branch=master
[docker-repo]:   https://hub.docker.com/repository/docker/datawire/aes
[docker-latest]: https://img.shields.io/docker/v/datawire/aes?sort=semver
[docker-pulls]:  https://img.shields.io/docker/pulls/datawire/aes
[slack-url]:     https://a8r.io/slack
[slack-join]:    https://img.shields.io/badge/slack-join-orange.svg

The Ambassador Edge Stack is a complete superset of the OSS Emissary Ingress project that offers additional functionality. Edge Stack is designed to easily expose, secure, and manage traffic to your Kubernetes microservices of any type. Edge Stack was built around the ideas of self-service (enabling GitOps-style management) and comprehensiveness (so it works with your situations and technology solutions).

Emissary-Ingress (formerly known as the [Ambassador API Gateway](https://www.getambassador.io)) is an open-source Kubernetes-native API Gateway + Layer 7 load balancer + Kubernetes Ingress built on [Envoy Proxy](https://www.envoyproxy.io). Emissary Ingress is an CNCF incubation project.

Ambassador Edge Stack enables its users to:

* Manage ingress traffic with [load balancing](https://www.getambassador.io/docs/edge-stack/latest/topics/running/load-balancer/#load-balancing-in-ambassador-edge-stack), protocol support([gRPC and HTTP/2](https://www.getambassador.io/docs/edge-stack/latest/howtos/grpc/), [TCP](https://www.getambassador.io/docs/edge-stack/latest/topics/using/tcpmappings/), and [web sockets](https://www.getambassador.io/docs/edge-stack/latest/topics/using/tcpmappings/)), and Kubernetes integration
* Manage changes to routing with an easy to use declarative policy engine and [self-service configuration](https://www.getambassador.io/docs/edge-stack/latest/topics/using/mappings/), via Kubernetes [CRDs](https://www.getambassador.io/docs/edge-stack/latest/topics/using/edge-policy-console/) or annotations
* Secure microservices with [authentication](https://www.getambassador.io/docs/edge-stack/latest/topics/running/services/auth-service/), rate limiting, [TLS](https://www.getambassador.io/docs/edge-stack/latest/howtos/tls-termination/), [automatic HTTPS](https://www.getambassador.io/docs/edge-stack/latest/topics/running/host-crd/), and [custom request fiters](https://www.getambassador.io/docs/edge-stack/latest/howtos/filter-dev-guide/#developing-custom-filters-for-routing)
* Ensure high availability with [sticky sessions](https://www.getambassador.io/docs/edge-stack/latest/topics/running/load-balancer/#sticky-sessions--session-affinity), [rate limiting](https://www.getambassador.io/docs/edge-stack/latest/topics/running/services/rate-limit-service/), and [circuit breaking](https://www.getambassador.io/docs/edge-stack/latest/topics/using/circuit-breakers/)
* Leverage observability with integrations with [Grafana](https://www.getambassador.io/docs/edge-stack/latest/topics/running/statistics/#grafana), [Prometheus](https://www.getambassador.io/docs/edge-stack/latest/topics/running/statistics/#prometheus), and [Datadog](https://www.getambassador.io/docs/edge-stack/latest/topics/running/statistics/#datadog), and comprehensive [metrics](https://www.getambassador.io/docs/edge-stack/latest/topics/running/statistics/) support
* Onboard developers with a [Developer Portal](https://www.getambassador.io/docs/edge-stack/latest/topics/using/dev-portal/)
* Enable progressive delivery with [canary releases](https://www.getambassador.io/docs/edge-stack/latest/topics/using/canary/)
* Connect service meshes including [Consul](https://www.getambassador.io/docs/edge-stack/latest/howtos/consul/), [Linkerd](https://www.getambassador.io/docs/edge-stack/latest/howtos/linkerd2/), and [Istio](https://www.getambassador.io/docs/edge-stack/latest/howtos/istio/)
* [Knative serverless integration](https://www.getambassador.io/docs/edge-stack/latest/howtos/knative/)

See the full list of [features](https://www.getambassador.io/features/) here. Learn [Why the Ambassador Edge Stack?](https://www.getambassador.io/docs/edge-stack/latest/about/why-ambassador/#why-the-ambassador-edge-stack)

Refer to [Ambassador EdgeStack Release Notes](https://www.getambassador.io/docs/edge-stack/latest/release-notes/) for the changelog.

Architecture
============

Ambassador deploys the Envoy Proxy for L7 traffic management. Configuration of Ambassador is via Kubernetes annotations. Ambassador relies on Kubernetes for scaling and resilience. For more on Ambassador's architecture and motivation, read [this blog post](https://blog.getambassador.io/building-ambassador-an-open-source-api-gateway-on-kubernetes-and-envoy-ed01ed520844).

Getting Started
===============

You can get Ambassador up and running in just three steps. Follow the instructions here: https://www.getambassador.io/docs/edge-stack/latest/tutorials/getting-started/.


If you are looking for a Kubernetes ingress controller, Ambassador provides a superset of the functionality of a typical ingress controller. (It does the traditional routing, and layers on a raft of configuration options.) This blog post covers [Kubernetes ingress](https://blog.getambassador.io/kubernetes-ingress-nodeport-load-balancers-and-ingress-controllers-6e29f1c44f2d).

For other common questions, view this [FAQ page](https://www.getambassador.io/docs/edge-stack/latest/about/faq/).

You can also use Helm to install Ambassador. For more information, see the instructions in the [Helm installation documentation](https://www.getambassador.io/user-guide/helm).

Community
=========

To get started:

* Join our [Slack channel](https://d6e.co/slack)
* Check out the [Ambassador documentation](https://www.getambassador.io/docs/edge-stack/latest)

The Ambassador Edge Stack is a superset of the Ambassador API Gateway that provides additional functionality including OAuth/OpenID Connect, advanced rate limiting, Swagger/OpenAPI support, integrated ACME support for automatic TLS certificate management, and a UI. For more information, visit https://www.getambassador.io/editions/.
