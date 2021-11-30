EDGE_STACK_HOME := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

SHELL := /bin/bash
HELM_OUTPUT_DIR := $(EDGE_STACK_HOME)/build/helm/

generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes.yaml
generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes-crds.yaml
generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/oss-migration.yaml
generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/resources-migration.yaml
generate/files += $(EDGE_STACK_HOME)/CHANGELOG.md
generate/files += $(EDGE_STACK_HOME)/.circleci/config.yml

$(EDGE_STACK_HOME)/venv:
	python3 -m venv $@
	$@/bin/python -m pip install ruamel.yaml

FORCE:
.PHONY: FORCE

$(EDGE_STACK_HOME)/manifests/edge-stack/aes.yaml: $(wildcard $(EDGE_STACK_HOME)/charts/edge-stack/templates/*.yaml)
$(EDGE_STACK_HOME)/manifests/edge-stack/aes.yaml: $(wildcard $(EDGE_STACK_HOME)/charts/edge-stack/charts/*.tgz)
$(EDGE_STACK_HOME)/manifests/edge-stack/aes.yaml: $(EDGE_STACK_HOME)/charts/edge-stack/values.yaml
$(EDGE_STACK_HOME)/manifests/edge-stack/aes.yaml: $(EDGE_STACK_HOME)/k8s-config/aes/values.yaml
$(EDGE_STACK_HOME)/manifests/edge-stack/aes.yaml: FORCE
	mkdir -p  $(@D)
	helm template edge-stack -n ambassador -f $(EDGE_STACK_HOME)/k8s-config/aes/values.yaml $(EDGE_STACK_HOME)/charts/edge-stack/ > $@

$(HELM_OUTPUT_DIR):
	rm -rf $@
	mkdir -p $@
	helm template edge-stack --output-dir $@ --include-crds -n ambassador $(EDGE_STACK_HOME)/charts/edge-stack

$(EDGE_STACK_HOME)/manifests/edge-stack/aes-crds.yaml: $(wildcard $(EDGE_STACK_HOME)/charts/edge-stack/templates/*.yaml)
$(EDGE_STACK_HOME)/manifests/edge-stack/aes-crds.yaml: $(wildcard $(EDGE_STACK_HOME)/charts/edge-stack/charts/*.tgz)
$(EDGE_STACK_HOME)/manifests/edge-stack/aes-crds.yaml: $(HELM_OUTPUT_DIR)
$(EDGE_STACK_HOME)/manifests/edge-stack/aes-crds.yaml: FORCE
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

$(EDGE_STACK_HOME)/manifests/edge-stack/oss-migration.yaml: $(EDGE_STACK_HOME)/k8s-config/create_yaml.py
$(EDGE_STACK_HOME)/manifests/edge-stack/oss-migration.yaml: $(EDGE_STACK_HOME)/k8s-config/oss-migration/require.yaml
$(EDGE_STACK_HOME)/manifests/edge-stack/oss-migration.yaml: $(EDGE_STACK_HOME)/k8s-config/oss-migration/values.yaml
$(EDGE_STACK_HOME)/manifests/edge-stack/oss-migration.yaml: $(wildcard $(EDGE_STACK_HOME)/charts/edge-stack/templates/*.yaml)
$(EDGE_STACK_HOME)/manifests/edge-stack/oss-migration.yaml: $(EDGE_STACK_HOME)/charts/edge-stack/values.yaml
$(EDGE_STACK_HOME)/manifests/edge-stack/oss-migration.yaml: $(EDGE_STACK_HOME)/venv
$(EDGE_STACK_HOME)/manifests/edge-stack/oss-migration.yaml: FORCE
	@printf '  $(CYN)$@$(END)\n'
	$(call generate_yaml_from_helm,oss-migration,default,$@)

$(EDGE_STACK_HOME)/manifests/edge-stack/resources-migration.yaml: $(EDGE_STACK_HOME)/k8s-config/create_yaml.py
$(EDGE_STACK_HOME)/manifests/edge-stack/resources-migration.yaml: $(EDGE_STACK_HOME)/k8s-config/resources-migration/require.yaml
$(EDGE_STACK_HOME)/manifests/edge-stack/resources-migration.yaml: $(EDGE_STACK_HOME)/k8s-config/resources-migration/values.yaml
$(EDGE_STACK_HOME)/manifests/edge-stack/resources-migration.yaml: $(wildcard $(EDGE_STACK_HOME)/charts/edge-stack/templates/*.yaml)
$(EDGE_STACK_HOME)/manifests/edge-stack/resources-migration.yaml: $(EDGE_STACK_HOME)/charts/edge-stack/values.yaml
$(EDGE_STACK_HOME)/manifests/edge-stack/resources-migration.yaml: $(EDGE_STACK_HOME)/venv
$(EDGE_STACK_HOME)/manifests/edge-stack/resources-migration.yaml: FORCE
	@printf '  $(CYN)$@$(END)\n'
	$(call generate_yaml_from_helm,resources-migration,default,$@)

push-manifests:
	$(EDGE_STACK_HOME)/manifests/push_manifests.sh
.PHONY: push-manifests

generate:
	$(MAKE) generate-clean
	$(MAKE) $(generate/files)
.PHONY: generate

generate-clean:
	rm -rf $(generate/files)
.PHONY: generate

$(EDGE_STACK_HOME)/CHANGELOG.md: $(EDGE_STACK_HOME)/docs/CHANGELOG.tpl $(EDGE_STACK_HOME)/docs/releaseNotes.yml
	docker run --rm \
	  -v $(EDGE_STACK_HOME)/docs/CHANGELOG.tpl:/tmp/CHANGELOG.tpl \
	  -v $(EDGE_STACK_HOME)/docs/releaseNotes.yml:/tmp/releaseNotes.yml \
	  hairyhenderson/gomplate --verbose --file /tmp/CHANGELOG.tpl --datasource relnotes=/tmp/releaseNotes.yml > CHANGELOG.md

$(EDGE_STACK_HOME)/.circleci/yq: $(EDGE_STACK_HOME)/.circleci/yq.d/go.mod
	cd $(<D) && go build -o $(abspath $@) github.com/mikefarah/yq/v3

$(EDGE_STACK_HOME)/.circleci/config.yml: $(EDGE_STACK_HOME)/.circleci/yq $(MAKEFILE_LIST) $(EDGE_STACK_HOME)/.circleci/config.yml.d $(sort $(wildcard $(EDGE_STACK_HOME)/.circleci/config.yml.d/*.yml))
	{ echo '# Generated by `make generate`. DO NOT EDIT.'; echo; $(<D)/$(<F) merge $(filter %.yml,$^); } > $@

clean-manifests:
	@cd $(EDGE_STACK_HOME) && git restore $(EDGE_STACK_HOME)/manifests/*/*.yaml
.PHONY: clean-manifests

include $(EDGE_STACK_HOME)/charts/charts.mk
