EDGE_STACK_HOME := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))


HELM_OUTPUT_DIR := $(EDGE_STACK_HOME)/build/helm/

update-yaml/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes.yaml
update-yaml/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes-crds.yaml
update-yaml/files += $(EDGE_STACK_HOME)/manifests/edge-stack/oss-migration.yaml
update-yaml/files += $(EDGE_STACK_HOME)/manifests/edge-stack/resources-migration.yaml

create-venv:
	[[ -d $(EDGE_STACK_HOME)/venv ]] || python3 -m venv $(EDGE_STACK_HOME)/venv
.PHONY: create-venv

python-setup: create-venv
	$(EDGE_STACK_HOME)/venv/bin/python -m pip install ruamel.yaml
.PHONY: python-setup

FORCE:

$(EDGE_STACK_HOME)/manifests/edge-stack/aes.yaml: $(wildcard $(EDGE_STACK_HOME)/charts/edge-stack/templates/*.yaml) $(wildcard $(EDGE_STACK_HOME)/charts/edge-stack/charts/*.tgz) $(EDGE_STACK_HOME)/charts/edge-stack/values.yaml $(EDGE_STACK_HOME)/k8s-config/aes/values.yaml FORCE
	mkdir -p  $(@D)
	helm template edge-stack -n ambassador -f $(EDGE_STACK_HOME)/k8s-config/aes/values.yaml $(EDGE_STACK_HOME)/charts/edge-stack/ > $@

template-helm:
	rm -rf $(HELM_OUTPUT_DIR)
	mkdir -p $(HELM_OUTPUT_DIR)
	helm template edge-stack --output-dir $(HELM_OUTPUT_DIR) --include-crds -n ambassador $(EDGE_STACK_HOME)/charts/edge-stack
.PHONY: template-helm

$(EDGE_STACK_HOME)/manifests/edge-stack/aes-crds.yaml: $(wildcard $(EDGE_STACK_HOME)/charts/edge-stack/templates/*.yaml) $(wildcard $(EDGE_STACK_HOME)/charts/edge-stack/charts/*.tgz) template-helm FORCE
	cat $(sort $(wildcard $(HELM_OUTPUT_DIR)/edge-stack/charts/emissary-ingress/crds/*.yaml)) > $@
	cat $(sort $(wildcard $(HELM_OUTPUT_DIR)/edge-stack/crds/*.yaml)) >> $@
	rm -rf $(HELM_OUTPUT_DIR)

define generate_yaml_from_helm
	mkdir -p `dirname $(3)` && \
	mkdir -p $(EDGE_STACK_HOME)/build/yaml/$(1) && \
		helm template edge-stack -n $(2) \
		-f $(EDGE_STACK_HOME)/k8s-config/$(1)/values.yaml \
		$(EDGE_STACK_HOME)/charts/edge-stack > $(EDGE_STACK_HOME)/build/yaml/$(1)/helm-expanded.yaml
	$(EDGE_STACK_HOME)/venv/bin/python $(EDGE_STACK_HOME)/k8s-config/create_yaml.py \
		$(EDGE_STACK_HOME)/build/yaml/$(1)/helm-expanded.yaml $(EDGE_STACK_HOME)/k8s-config/$(1)/require.yaml > $(3)
endef

$(EDGE_STACK_HOME)/manifests/edge-stack/oss-migration.yaml: $(EDGE_STACK_HOME)/k8s-config/create_yaml.py $(EDGE_STACK_HOME)/k8s-config/oss-migration/require.yaml $(EDGE_STACK_HOME)/k8s-config/oss-migration/values.yaml $(EDGE_STACK_HOME)/charts/edge-stack/templates/*.yaml $(EDGE_STACK_HOME)/charts/edge-stack/values.yaml python-setup FORCE
	@printf '  $(CYN)$@$(END)\n'
	$(call generate_yaml_from_helm,oss-migration,default,$@)

$(EDGE_STACK_HOME)/manifests/edge-stack/resources-migration.yaml: $(EDGE_STACK_HOME)/k8s-config/create_yaml.py $(EDGE_STACK_HOME)/k8s-config/resources-migration/require.yaml $(EDGE_STACK_HOME)/k8s-config/resources-migration/values.yaml $(EDGE_STACK_HOME)/charts/edge-stack/templates/*.yaml $(EDGE_STACK_HOME)/charts/edge-stack/values.yaml python-setup FORCE
	@printf '  $(CYN)$@$(END)\n'
	$(call generate_yaml_from_helm,resources-migration,default,$@)

update-yaml:
	@echo '$(MAKE) $$(update-yaml/files)'; $(MAKE) $(update-yaml/files) --always-make
.PHONY: update-yaml

push-manifests:
	$(EDGE_STACK_HOME)/manifests/push_manifests.sh
.PHONY: push-manifests

generate:
	$(MAKE) update-yaml
	cd $(EDGE_STACK_HOME)/.circleci && ./generate --always-make
.PHONY: generate

create-venv:
	[[ -d $(EDGE_STACK_HOME)/venv ]] || python3 -m venv $(EDGE_STACK_HOME)/venv
.PHONY: create-venv

$(EDGE_STACK_HOME)/.circleci/yq: $(EDGE_STACK_HOME)/.circleci/yq.d/go.mod
	cd $(<D) && go build -o $(abspath $@) github.com/mikefarah/yq/v3

clean-manifests:
	@cd $(EDGE_STACK_HOME) && git restore $(EDGE_STACK_HOME)/manifests/*/*.yaml
.PHONY: clean-manifests

include $(EDGE_STACK_HOME)/charts/charts.mk
