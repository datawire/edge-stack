EDGE_STACK_HOME := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

SHELL := /bin/bash
HELM_OUTPUT_DIR := $(EDGE_STACK_HOME)/build/helm/

generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes.yaml
generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes-ambassadorns.yaml
generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes-ambassadorns-agent.yaml
generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes-ambassadorns-migration.yaml
generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes-defaultns.yaml
generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes-defaultns-agent.yaml
generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes-defaultns-migration.yaml
generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes-emissaryns.yaml
generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes-emissaryns-agent.yaml
generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/aes-emissaryns-migration.yaml
generate/files += $(EDGE_STACK_HOME)/manifests/edge-stack/resources-migration.yaml

$(EDGE_STACK_HOME)/venv:
	python3 -m venv $@
	$@/bin/pip3 install ruamel.yaml

FORCE:
.PHONY: FORCE
.SECONDARY:

$(EDGE_STACK_HOME)/charts/edge-stack/charts: FORCE
	if test -f ../go.mod && test "$$(cd .. && go list -m)" == github.com/datawire/apro/v3; then \
	  $(MAKE) -C .. $@; \
	else \
	  cd $(@D) && helm dependency update; \
	fi

$(HELM_OUTPUT_DIR): $(EDGE_STACK_HOME)/charts/edge-stack/charts FORCE
	rm -rf $@
	mkdir -p $@
	helm template edge-stack --output-dir $@ -n ambassador $(EDGE_STACK_HOME)/charts/edge-stack

helm-namespace.aes                         = ambassador
helm-namespace.aes-ambassadorns            = ambassador
helm-namespace.aes-ambassadorns-agent      = ambassador
helm-namespace.aes-ambassadorns-migration  = ambassador
helm-namespace.aes-defaultns               = default
helm-namespace.aes-defaultns-agent         = default
helm-namespace.aes-defaultns-migration     = default
helm-namespace.aes-emissaryns              = emissary
helm-namespace.aes-emissaryns-migration    = emissary
helm-namespace.aes-emissaryns-agent        = emissary
helm-namespace.resources-migration         = default
$(EDGE_STACK_HOME)/k8s-config/%/helm-expanded.yaml: \
  $(EDGE_STACK_HOME)/charts/edge-stack/charts \
  $(EDGE_STACK_HOME)/k8s-config/%/values.yaml \
  FORCE
	helm template --namespace=$(helm-namespace.$*) --values=$(@D)/values.yaml edge-stack $(EDGE_STACK_HOME)/charts/edge-stack >$@
$(EDGE_STACK_HOME)/manifests/edge-stack/%.yaml: \
  $(EDGE_STACK_HOME)/k8s-config/%/helm-expanded.yaml \
  $(EDGE_STACK_HOME)/k8s-config/%/require.yaml \
  $(EDGE_STACK_HOME)/k8s-config/create_yaml.py \
  $(EDGE_STACK_HOME)/venv
	. $(EDGE_STACK_HOME)/venv/bin/activate && $(filter %.py,$^) $(filter %/helm-expanded.yaml,$^) $(filter %/require.yaml,$^) >$@

push-manifests:
	$(EDGE_STACK_HOME)/manifests/push_manifests.sh
.PHONY: push-manifests

generate:
	$(MAKE) generate-clean
	$(MAKE) $(generate/files)
.PHONY: generate

generate-clean:
	rm -rf $(generate/files)
	rm -rf $(EDGE_STACK_HOME)/charts/edge-stack/charts/
.PHONY: generate-clean

clean-manifests:
	@cd $(EDGE_STACK_HOME) && git restore $(EDGE_STACK_HOME)/manifests/*/*.yaml
.PHONY: clean-manifests

include $(EDGE_STACK_HOME)/charts/charts.mk
