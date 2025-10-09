.PHONY: default
default: help     # help target is now provided by Makefile-common

%:
	make -f Makefile-common $*

##@ Testing & Development Tasks

.PHONY: argo-healthcheck
argo-healthcheck: ## Checks if all argo applications are synced
	@echo "Checking argo applications"
	$(eval APPS := $(shell oc get applications.argoproj.io -A -o jsonpath='{range .items[*]}{@.metadata.namespace}{","}{@.metadata.name}{"\n"}{end}'))
	@NOTOK=0; \
	for i in $(APPS); do\
		n=`echo "$${i}" | cut -f1 -d,`;\
		a=`echo "$${i}" | cut -f2 -d,`;\
		STATUS=`oc get -n "$${n}" applications.argoproj.io/"$${a}" -o jsonpath='{.status.sync.status}'`;\
		if [[ $$STATUS != "Synced" ]]; then\
			NOTOK=$$(( $${NOTOK} + 1));\
		fi;\
		HEALTH=`oc get -n "$${n}" applications.argoproj.io/"$${a}" -o jsonpath='{.status.health.status}'`;\
		if [[ $$HEALTH != "Healthy" ]]; then\
			NOTOK=$$(( $${NOTOK} + 1));\
		fi;\
		echo "$${n} $${a} -> Sync: $${STATUS} - Health: $${HEALTH}";\
	done;\
	if [ $${NOTOK} -gt 0 ]; then\
	    echo "Some applications are not synced or are unhealthy";\
	    exit 1;\
	fi

.PHONY: validate-telco-reference
validate-telco-reference: ## Validates telco-hub pattern against telco-reference CRs using cluster-compare
	@kustomize build kustomize/overlays/telco-hub/ | \
		oc cluster-compare \
			-r https://raw.githubusercontent.com/openshift-kni/telco-reference/refs/heads/main/telco-hub/configuration/reference-crs-kube-compare/metadata.yaml \
			-f - \
			-o json | \
		jq -e "if .Summary.NumDiffCRs > 0 \
			then \"FAIL: Found \\(.Summary.NumDiffCRs) content differences (goal: 0 diffs)\" | halt_error(1) \
			elif (.Summary.NumMissingCRs // 0) > 12 \
			then \"FAIL: Found \\(.Summary.NumMissingCRs) missing CRs from reference (max allowed: 12)\" | halt_error(1) \
			else \"PASS: No content differences (\\(.Summary.NumDiffCRs) diffs) and acceptable missing CRs (\\(.Summary.NumMissingCRs // 0)/12 max)\" \
			end"

.PHONY: super-linter
super-linter: ## Runs the super-linter locally
	rm -rf .mypy_cache
	podman run -e RUN_LOCAL=true -e USE_FIND_ALGORITHM=true \
				-e VALIDATE_ANSIBLE=false \
				-e VALIDATE_BASH=false \
				-e VALIDATE_CHECKOV=false \
				-e BIOME_LINT=false \
				-e VALIDATE_DOCKERFILE_HADOLINT=false \
				-e VALIDATE_JSCPD=false \
				-e VALIDATE_JSON_PRETTIER=false \
				-e VALIDATE_MARKDOWN_PRETTIER=false \
				-e VALIDATE_PYTHON_PYLINT=false \
				-e VALIDATE_SHELL_SHFMT=false \
				-e VALIDATE_YAML=false \
				-e VALIDATE_YAML_PRETTIER=false \
				-e VALIDATE_KUBERNETES_KUBECONFORM=false \
				-e VALIDATE_BIOME_FORMAT=false \
				$(DISABLE_LINTERS) \
				-v $(PWD):/tmp/lint:rw,z \
				-w /tmp/lint \
				ghcr.io/super-linter/super-linter:slim-latest

.PHONY: validate-kustomize
validate-kustomize: ## Validates kustomization build and YAML format
	@kustomize build kustomize/overlays/telco-hub/ > /dev/null && \
		echo "✓ Kustomize build successful" || \
		(echo "✗ Kustomize build failed" && exit 1)

include Makefile-common
