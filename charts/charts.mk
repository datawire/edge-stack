HELM_TEST_IMAGE = quay.io/helmpack/chart-testing:v3.0.0-rc.1
K3D_CLUSTER_NAME = helm-chart-test-cluster
CHART_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))edge-stack
CHART_KUBECONFIG := /tmp/kubeconfig/k3dconfig
CT_EXEC = docker run --rm -v $(CHART_KUBECONFIG):/root/.kube/config -v $(CHART_DIR):/charts --network host $(HELM_TEST_IMAGE) /charts/ci/ct.sh
K3D_EXEC := KUBECONFIG=$(CHART_KUBECONFIG) k3d
YQ := $(EDGE_STACK_HOME)/.circleci/yq

define _push_chart
	CHART_NAME=$(1) $(EDGE_STACK_HOME)/charts/scripts/push_chart.sh
endef

define _set_tag_and_repo
	$(EDGE_STACK_HOME)/venv/bin/python $(EDGE_STACK_HOME)/charts/scripts/update_chart_image_values.py \
		--values-file $(1) --tag $(2) --repo $(3)
endef

define _docgen
	if [[ -f $(1)/doc.yaml ]] ; then \
		GO111MODULE=off go get kubepack.dev/chart-doc-gen ; \
		GO111MODULE=off go run kubepack.dev/chart-doc-gen -d $(1)/doc.yaml -t $(1)/readme.tpl -v $(1)/values.yaml > $(1)/README.md ; \
	fi
endef

EMISSARY_CHART_REPO_GA  = https://s3.amazonaws.com/datawire-static-files/charts
EMISSARY_CHART_REPO_PRE = https://s3.amazonaws.com/datawire-static-files/charts-dev
EMISSARY_CHART_REPO     = $(if $(findstring -,$(EMISSARY_CHART_VERSION)),$(EMISSARY_CHART_REPO_PRE),$(EMISSARY_CHART_REPO_GA))
chart/update-emissary: $(YQ)
	[ -n '$(EMISSARY_CHART_VERSION)' ] || (echo "EMISSARY_CHART_VERSION must be set for non-GA pushes" && exit 1)
	rm -f $(CHART_DIR)/charts/emissary-ingress*.tgz
	$(YQ) w -i $(CHART_DIR)/Chart.yaml 'dependencies.(name==emissary-ingress).version' '$(patsubst v%,%,$(EMISSARY_CHART_VERSION))'
	$(YQ) w -i $(CHART_DIR)/Chart.yaml 'dependencies.(name==emissary-ingress).repository' '$(EMISSARY_CHART_REPO)'
.PHONY: chart/update-emissary

chart/docgen:
	$(call _docgen,$(CHART_DIR))
.PHONY: chart/docgen

chart/test: chart/lint chart/preflight-test chart/create-cluster
	$(CT_EXEC) install --config /charts/ct.yaml && \
		$(MAKE) chart/delete-cluster
.PHONY: chart/test

chart/lint: chart/preflight-kubeconfig
	$(CT_EXEC) lint --config /charts/ct.yaml
.PHONY: chart/lint

chart/preflight-test: chart/preflight-kubeconfig
	# check if k3d is installed
	@if ! command -v k3d 2> /dev/null ; then \
		printf 'k3d not installed, plz do that'; \
	    false; \
	fi
.PHONY: chart/preflight-test

chart/preflight-kubeconfig:
	mkdir -p `dirname $(CHART_KUBECONFIG)`
	touch $(CHART_KUBECONFIG)
.PHONY: chart/preflight-kubeconfig

chart/create-cluster: chart/preflight-kubeconfig
	$(MAKE) chart/delete-cluster || true
	$(K3D_EXEC) cluster create $(K3D_CLUSTER_NAME) --k3s-server-arg "--no-deploy=traefik"
	while ! kubectl --kubeconfig=$(CHART_KUBECONFIG) get serviceaccount default >/dev/null; do sleep 1; done
	kubectl --kubeconfig=$(CHART_KUBECONFIG) version
	kubectl --kubeconfig=$(CHART_KUBECONFIG) apply -f manifests/edge-stack/aes-crds.yaml
	kubectl --kubeconfig=$(CHART_KUBECONFIG) --namespace=emissary-system wait --timeout=90s --for=condition=available Deployments/emissary-apiext
.PHONY: chart/create-cluster

chart/delete-cluster:
	$(K3D_EXEC) cluster delete $(K3D_CLUSTER_NAME)
.PHONY: chart/delete-cluster

chart/push-ci: chart/push-preflight
	@echo ">>> This will dirty your local tree and should only be run in CI"
	@echo ">>> If running locally, you'll probably want to run make chart-clean after running this"
	@[ -n "${CHART_VERSION_SUFFIX}" ] || (echo "CHART_VERSION_SUFFIX must be set for non-GA pushes" && exit 1)
	@[ -n "${IMAGE_TAG}" ] || (echo "IMAGE_TAG must be set" && exit 1)
	@[ -n "${IMAGE_REPO}" ] || (echo "IMAGE_REPO must be set" && exit 1)
	sed -i.bak -E "s/^version: ([0-9]+\.[0-9]+\.[0-9]+).*/version: \1${CHART_VERSION_SUFFIX}/g" $(CHART_DIR)/Chart.yaml && rm $(CHART_DIR)/Chart.yaml.bak
	$(call _set_tag_and_repo,$(CHART_DIR)/values.yaml,${IMAGE_TAG},${IMAGE_REPO})
	$(YQ) w -i $(CHART_DIR)/Chart.yaml 'appVersion' ${IMAGE_TAG}
	$(call _push_chart,`basename $(CHART_DIR)`)
.PHONY: chart/push-ci

chart/clean:
	@cd $(EDGE_STACK_HOME) && git restore $(CHART_DIR)/Chart.yaml $(CHART_DIR)/values.yaml
	@rm -f $(CHART_DIR)/*.tgz $(CHART_DIR)/index.yaml $(CHART_DIR)/tmp.yaml

chart/push-preflight: $(EDGE_STACK_HOME)/venv $(YQ)
.PHONY: chart/push-preflight

#########################################################################################
## Release targets
#########################################################################################

release/chart/changelog:
	@$(EDGE_STACK_HOME)/charts/scripts/update_chart_changelog.sh
.PHONY: release/chart/changelog

release/chart/tag:
	@set -e; { \
		if [ -n "$(IS_DIRTY)" ]; then \
			echo "release/chart/tag: tree must be clean" >&2 ;\
			exit 1 ;\
		fi; \
		chart_ver=`grep 'version:' $(CHART_DIR)/Chart.yaml | head -1 | awk ' { print $$2 }'` ; \
		chart_ver=chart-v$${chart_ver} ; \
		git tag -m "Tagging $${chart_ver}" -a $${chart_ver} ; \
		git push origin $${chart_ver} ; \
	}

release/chart/ga-image-update: chart/push-preflight
	@[ -n "${IMAGE_TAG}" ] || (echo "IMAGE_TAG must be set" && exit 1)
	([[ "${IMAGE_TAG}" =~ .*\.0$$ ]] && $(MAKE) release/chart/bump-minor) || $(MAKE) release/chart/bump-revision
	@[[ "${IMAGE_TAG}" =~ .*\-ea$$ ]] && sed -i.bak -E "s/^version: ([0-9]+\.[0-9]+\.[0-9]+).*/version: \1-ea/g" $(CHART_DIR)/Chart.yaml && rm $(CHART_DIR)/Chart.yaml.bak
	$(call _set_tag_and_repo,$(CHART_DIR)/values.yaml,${IMAGE_TAG},"")
	$(YQ) w -i $(CHART_DIR)/Chart.yaml 'appVersion' ${IMAGE_TAG}
	IMAGE_TAG="${IMAGE_TAG}" CHART_NAME=`basename $(CHART_DIR)` $(EDGE_STACK_HOME)/charts/scripts/image_tag_changelog_update.sh
	CHART_NAME=`basename $(CHART_DIR)` $(EDGE_STACK_HOME)/charts/scripts/update_chart_changelog.sh
	$(call _docgen,$(CHART_DIR))
.PHONY: release/chart/ga-image-update

release/chart/ga-push:
	$(call _push_chart,`basename $(CHART_DIR)`)
.PHONY: release/chart/ga-push

release/chart/bump-revision:
	$(EDGE_STACK_HOME)/charts/scripts/bump_chart_version.sh patch $(CHART_DIR)/Chart.yaml
.PHONY: release/chart/bump-revision

release/chart/bump-minor:
	$(EDGE_STACK_HOME)/charts/scripts/bump_chart_version.sh minor $(CHART_DIR)/Chart.yaml
.PHONY: release/chart/bump-minor
