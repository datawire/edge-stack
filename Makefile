HELM_OUTPUT_DIR := build/helm/

update-yaml/files += manifests/edge-stack/aes.yaml
update-yaml/files += manifests/edge-stack/aes-crds.yaml

manifests/edge-stack/aes.yaml: $(wildcard charts/edge-stack/templates/*.yaml) $(wildcard charts/edge-stack/charts/*.tgz) charts/edge-stack/values.yaml k8s-config/aes/values.yaml
	mkdir -p  $(@D)
	helm template edge-stack -n ambassador -f k8s-config/aes/values.yaml charts/edge-stack/ > $@

template-helm:
	rm -rf $(HELM_OUTPUT_DIR)
	mkdir -p $(HELM_OUTPUT_DIR)
	helm template edge-stack --output-dir $(HELM_OUTPUT_DIR) --include-crds -n ambassador charts/edge-stack
.PHONY: template-helm

manifests/edge-stack/aes-crds.yaml: $(wildcard charts/edge-stack/templates/*.yaml) $(wildcard charts/edge-stack/charts/*.tgz) template-helm
	cat $(sort $(wildcard $(HELM_OUTPUT_DIR)/edge-stack/charts/emissary-ingress/crds/*.yaml)) > $@
	cat $(sort $(wildcard $(HELM_OUTPUT_DIR)/edge-stack/crds/*.yaml)) >> $@
	rm -rf $(HELM_OUTPUT_DIR)

update-yaml:
	@echo '$(MAKE) $$(update-yaml/files)'; $(MAKE) $(update-yaml/files)
.PHONY: update-yaml

push-manifests:
	manifests/push_manifests.sh
.PHONY: push-manifests

generate:
	$(MAKE) update-yaml
	cd .circleci && ./generate --always-make
.PHONY: generate


include charts/charts.mk
