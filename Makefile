SHELL := /usr/bin/env bash
BIN = $(CURDIR)/.bin

OSP_VERSION ?= latest

# using the chart name and version from chart's metadata
CHART_NAME ?= $(shell awk '/^name:/ { print $$2 }' Chart.yaml)
CHART_VERSION ?= $(shell awk '/^version:/ { print $$2 }' Chart.yaml)
RELEASE_VERSION = v$(CHART_VERSION)

CATALOGCD_VERSION = v0.1.0

# bats entry point and default flags
BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

# release directory where the Tekton resources are rendered into.
RELEASE_DIR ?= /tmp/$(CHART_NAME)-$(CHART_VERSION)

# path to the bats test files, overwite the variables below to tweak the test scope
E2E_TEST_DIR ?= ./test/e2e
# based on the test directory, selecting all dot-bats files
E2E_TESTS ?= $(E2E_TEST_DIR)/*.bats

# container registry URL, usually hostname and port
REGISTRY_URL ?= registry.registry.svc.cluster.local:32222
# container registry namespace, as in the section of the registry allowed to push images
REGISTRY_NAMESPACE ?= task-containers
# base part of a fully qualified container image name
IMAGE_BASE ?= $(REGISTRY_URL)/$(REGISTRY_NAMESPACE)

# skopeo-copy task e2e test variables, source, destination url and tls-verify parameter.
# Could use cgr.dev/chainguard/static as well
E2E_SC_PARAMS_SOURCE_IMAGE_URL ?= docker://docker.io/library/busybox:latest
# end-to-end test destination image name and tag
E2E_SC_IMAGE_TAG ?= busybox:latest
# end-to-end test fully qualified destination image name
E2E_SC_PARAMS_DESTINATION_IMAGE_URL ?= docker://$(IMAGE_BASE)/${E2E_SC_IMAGE_TAG}

# setting tls-verify as false disables the HTTPS client as well, something we need for e2e testing
# using the internal container registry (HTTP based)
E2E_PARAMS_TLS_VERIFY ?= false
E2E_PARAMS_SRC_TLS_VERIFY ?= false
E2E_PARAMS_DEST_TLS_VERIFY ?= false

# auxiliary task to create a Containerfile for buildah end-to-end testing
E2E_BUILDAH_TASK_CONTAINERFILE_STUB ?= test/e2e/resources/task-containerfile-stub.yaml
# container image name and tag to be created by buildah during e2e
E2E_BUILDAH_IMAGE_TAG ?= task-buildah:latest
# fully qualified container image passed to buildah task IMAGE param
E2E_BUILDAH_PARAMS_IMAGE ?= $(IMAGE_BASE)/${E2E_BUILDAH_IMAGE_TAG}

# container image name and tag to be created by s2i during e2e
E2E_S2I_IMAGE_TAG ?= task-s2i:latest
# (fully qualified) container image passed to s2i task IMAGE param
E2E_S2I_PARAMS_IMAGE ?= $(IMAGE_BASE)/${E2E_S2I_IMAGE_TAG}

# s2i end-to-end test pipeline params, the git repository URL and revision
E2E_S2I_PARAMS_URL ?= https://github.com/cpuguy83/go-md2man.git
E2E_S2I_PARAMS_REVISION ?= master

# s2i end-to-end test language of choice for using correct builder image
E2E_S2I_LANGUAGE ?= python

# s2i's "image-script-url" flag for container-file generation
E2E_S2I_IMAGE_SCRIPTS_URL ?= image:///usr/libexec/s2i

# s2i end-to-end test pipeline params adding env variables as a comma-separated string
E2E_S2I_PARAMS_ENV_VARS ?=

# path to the github actions testing workflows
ACT_WORKFLOWS ?= ./.github/workflows/test.yaml

# generic arguments employed on most of the targets
ARGS ?=

# making sure the variables declared in the Makefile are exported to the executables/scripts
# invoked on all targets
.EXPORT_ALL_VARIABLES:

# uses helm to render the resource templates to the stdout
define render-template
	@helm template $(ARGS) .
endef

$(BIN):
	@mkdir -p $@

CATALOGCD = $(or ${CATALOGCD_BIN},${CATALOGCD_BIN},$(BIN)/catalog-cd)
$(BIN)/catalog-cd: $(BIN)
	curl -fsL https://github.com/openshift-pipelines/catalog-cd/releases/download/v0.1.0/catalog-cd_0.1.0_linux_x86_64.tar.gz | tar xzf - -C $(BIN) catalog-cd

# renders the task resource file printing it out on the standard output
helm-template:
	$(call render-template)

default: helm-template

# renders the task templates and copies documentation into the ${RELEASE_DIR}
prepare-release:
	mkdir -p $(RELEASE_DIR) || true
	hack/release.sh $(RELEASE_DIR)

# runs "catalog-cd release" to create the release payload based on the Tekton resources
# prepared by the previous step
release: $(CATALOGCD) prepare-release
	mkdir -p $(RELEASE_DIR) || true
	pushd ${RELEASE_DIR} && \
		$(CATALOGCD) release \
			--output release \
			--version $(CHART_VERSION) \
			tasks/* \
		; \
	popd

# tags the repository with the RELEASE_VERSION and pushes to "origin"
git-tag-release-version:
	if ! git rev-list "${RELEASE_VERSION}".. >/dev/null; then \
		git tag "$(RELEASE_VERSION)" && \
			git push origin --tags; \
	fi

# rolls out the current Chart version as the repository release version, uploads the release
# payload prepared to GitHub (using gh)
github-release: git-tag-release-version release
	gh release create $(RELEASE_VERSION) --generate-notes && \
	gh release upload $(RELEASE_VERSION) $(RELEASE_DIR)/release/catalog.yaml && \
	gh release upload $(RELEASE_VERSION) $(RELEASE_DIR)/release/resources.tar.gz

# renders and installs the resources (task)
install:
	$(call render-template) |kubectl $(ARGS) apply -f -

# renders and remove the resources (task)
remove:
	$(call render-template) |kubectl $(ARGS) delete -f -

# removes the package helm chart, and also the chart-releaser temporary directories
clean:
	rm -f $(CHART_NAME)-*.tgz >/dev/null 2>&1 || true

# packages the helm-chart as a single tarball, using it's name and version to compose the file
helm-package: clean
	helm package $(ARGS) .
	tar -ztvpf $(CHART_NAME)-$(CHART_VERSION).tgz

# prepares the buildah end-to-end tests, installs the required resources
.PHONY: prepare-e2e-buildah
prepare-e2e-buildah:
	kubectl apply -f $(E2E_BUILDAH_TASK_CONTAINERFILE_STUB)

# runs bats-core against the pre-determined tests
.PHONY: bats
bats: install
	$(BATS_CORE) $(BATS_FLAGS) $(ARGS) $(E2E_TESTS)

# runs the end-to-end tests narrowing down on "skopeo-copy"
.PHONY: test-e2e-skopeo-copy
test-e2e-skopeo-copy: E2E_TESTS = $(E2E_TEST_DIR)/*skopeo-copy*.bats
test-e2e-skopeo-copy: bats

.PHONY: test-e2e-skopeo-copy-openshift
test-e2e-skopeo-copy-openshift: REGISTRY_URL = image-registry.openshift-image-registry.svc.cluster.local:5000
test-e2e-skopeo-copy-openshift: REGISTRY_NAMESPACE = $(shell oc project -q)
test-e2e-skopeo-copy-openshift: E2E_TESTS = $(E2E_TEST_DIR)/*skopeo-copy*.bats
test-e2e-skopeo-copy-openshift: bats

# runs the end-to-end tests for buildah
.PHONY: test-e2e-buildah
test-e2e-buildah: prepare-e2e-buildah
test-e2e-buildah: E2E_TESTS = $(E2E_TEST_DIR)/*buildah*.bats
test-e2e-buildah: bats

.PHONY: test-e2e-buildah-openshift
test-e2e-buildah-openshift: prepare-e2e-buildah
test-e2e-buildah-openshift: REGISTRY_URL = image-registry.openshift-image-registry.svc.cluster.local:5000
test-e2e-buildah-openshift: REGISTRY_NAMESPACE = $(shell oc project -q)
test-e2e-buildah-openshift: E2E_TESTS = $(E2E_TEST_DIR)/*buildah*.bats
test-e2e-buildah-openshift: bats

# runs the end-to-end tests for s2i-python
.PHONY: test-e2e-s2i-python
test-e2e-s2i-python: E2E_S2I_LANGUAGE = python
test-e2e-s2i-python: E2E_S2I_IMAGE_TAG = task-s2i-python:latest
test-e2e-s2i-python: E2E_S2I_PARAMS_URL = https://github.com/Kalebu/Plagiarism-checker-Python
test-e2e-s2i-python: test-e2e-s2i

# runs the end-to-end tests for s2i-ruby
.PHONY: test-e2e-s2i-ruby
test-e2e-s2i-ruby: E2E_S2I_LANGUAGE = ruby
test-e2e-s2i-ruby: E2E_S2I_IMAGE_TAG = task-s2i-ruby:latest
test-e2e-s2i-ruby: E2E_S2I_PARAMS_URL = https://github.com/DataDog/dd-trace-rb
test-e2e-s2i-ruby: test-e2e-s2i

# runs the end-to-end tests for s2i-perl
.PHONY: test-e2e-s2i-perl
test-e2e-s2i-perl: E2E_S2I_LANGUAGE = perl
test-e2e-s2i-perl: E2E_S2I_IMAGE_TAG = task-s2i-perl:latest
test-e2e-s2i-perl: E2E_S2I_PARAMS_URL = https://github.com/major/MySQLTuner-perl
test-e2e-s2i-perl: test-e2e-s2i

# runs the end-to-end tests for s2i-php
.PHONY: test-e2e-s2i-php
test-e2e-s2i-php: E2E_S2I_LANGUAGE = php
test-e2e-s2i-php: E2E_S2I_IMAGE_TAG = task-s2i-php:latest
test-e2e-s2i-php: E2E_S2I_PARAMS_URL = https://github.com/PuneethReddyHC/online-shopping-system-advanced
test-e2e-s2i-php: test-e2e-s2i

# runs the end-to-end tests for s2i-golang
.PHONY: test-e2e-s2i-go
test-e2e-s2i-go: E2E_S2I_LANGUAGE = go
test-e2e-s2i-go: E2E_S2I_IMAGE_TAG = task-s2i-go:latest
test-e2e-s2i-go: E2E_S2I_PARAMS_URL = https://github.com/cpuguy83/go-md2man.git
test-e2e-s2i-go: test-e2e-s2i

# runs the end-to-end tests for s2i-nodejs
.PHONY: test-e2e-s2i-nodejs
test-e2e-s2i-nodejs: E2E_S2I_LANGUAGE = nodejs
test-e2e-s2i-nodejs: E2E_S2I_IMAGE_TAG = task-s2i-nodejs:latest
test-e2e-s2i-nodejs: E2E_S2I_PARAMS_URL = https://github.com/ashadnasim52/sentiment-analysis
test-e2e-s2i-nodejs: test-e2e-s2i

# runs the end-to-end tests for s2i-dotnet
.PHONY: test-e2e-s2i-dotnet
test-e2e-s2i-dotnet: E2E_S2I_LANGUAGE = dotnet
test-e2e-s2i-dotnet: E2E_S2I_IMAGE_TAG = task-s2i-dotnet:latest
test-e2e-s2i-dotnet: E2E_S2I_PARAMS_URL = https://github.com/biswajitpanday/CleanArchitecture.Net6.git
test-e2e-s2i-dotnet: E2E_S2I_PARAMS_REVISION = main
test-e2e-s2i-dotnet: E2E_S2I_PARAMS_ENV_VARS = DOTNET_STARTUP_PROJECT=CleanArchitecture.Api/CleanArchitecture.Api.csproj
test-e2e-s2i-dotnet: test-e2e-s2i

# runs the end-to-end tests for s2i-java
.PHONY: test-e2e-s2i-java
test-e2e-s2i-java: E2E_S2I_LANGUAGE = java
test-e2e-s2i-java: E2E_S2I_IMAGE_TAG = task-s2i-java:latest
test-e2e-s2i-java: E2E_S2I_PARAMS_URL = https://github.com/shashirajraja/shopping-cart
test-e2e-s2i-java: E2E_S2I_PARAMS_ENV_VARS = MAVEN_CLEAR_REPO=false
test-e2e-s2i-java: E2E_S2I_IMAGE_SCRIPTS_URL = image:///usr/local/s2i
test-e2e-s2i-java: test-e2e-s2i

# runs the end-to-end tests for s2i
.PHONY: test-e2e-s2i
test-e2e-s2i: E2E_TESTS = $(E2E_TEST_DIR)/*s2i*.bats
test-e2e-s2i: bats

.PHONY: test-e2e-s2i-openshift
test-e2e-s2i-openshift: REGISTRY_URL = image-registry.openshift-image-registry.svc.cluster.local:5000
test-e2e-s2i-openshift: REGISTRY_NAMESPACE = $(shell oc project -q)
test-e2e-s2i-openshift: E2E_TESTS = $(E2E_TEST_DIR)/*s2i*.bats
test-e2e-s2i-openshift: bats

# runs all the end-to-end tests against the current kubernetes context, it will required a cluster
# with Tekton Pipelines (OpenShift Pipelines) and a container registry instance
.PHONY: test-e2e
test-e2e: test-e2e-buildah test-e2e-skopeo-copy test-e2e-s2i


# Run all the end-to-end tests against the current openshift context.
# It is used mainly by the CI and ideally shouldn't differ that much from test-e2e
.PHONY: prepare-e2e-openshift
prepare-e2e-openshift:
	./hack/install-osp.sh $(OSP_VERSION)

.PHONY: test-e2e-openshift
test-e2e-openshift: prepare-e2e-openshift
test-e2e-openshift: REGISTRY_URL = image-registry.openshift-image-registry.svc.cluster.local:5000
test-e2e-openshift: REGISTRY_NAMESPACE = $(shell oc project -q)
test-e2e-openshift: test-e2e

# act runs the github actions workflows, so by default only running the test workflow (integration
# and end-to-end) to avoid running the release workflow accidentally
act: ARGS = --rm
act:
	act --workflows=$(ACT_WORKFLOWS) $(ARGS)
