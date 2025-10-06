.PHONY: default
default: help

# help target is now provided by Makefile-common

%:
	make -f common/Makefile $*

.PHONY: install
install: operator-deploy post-install ## installs the pattern and loads the secrets
	@echo "Installed"

.PHONY: post-install
post-install: ## Post-install tasks
	make load-secrets
	@echo "Done"

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

.PHONY: test
test:
	@make -f common/Makefile PATTERN_OPTS="-f values-global.yaml -f values-hub.yaml" test

include Makefile-common
