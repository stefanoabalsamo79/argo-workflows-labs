YQ:=$(shell which yq)
JQ:=$(shell which jq)
KUBECTL:=$(shell which kubectl)
DOCKER:=$(shell which docker)
HELM:=$(shell which helm)
KIND:=$(shell which kind)

INFO_FILE:="../../deploy_charts/charts/producer/values.yaml"
APP_NAME:=$(shell ${YQ} e '.app.name' ${INFO_FILE})
VERSION:=$(shell ${YQ} e '.app.version' ${INFO_FILE})
NAMESPACE:=$(shell ${YQ} e '.app.namespace' ${INFO_FILE})
IMAGE_NAME_TAG:=$(APP_NAME):$(VERSION)
FULLY_QUALIFIED_IMAGE_URL:=$(ARTIFACT_REGISTRY)$(IMAGE_NAME_TAG)
CLUSTER_NAME:=$(shell ${YQ} e '.clusterName' ${INFO_FILE})
DEPLOYMENT_RELEASE_NAME:=$(shell ${YQ} e '.deployementReleaseName' ${INFO_FILE})

print_mk_var:
	@echo "YQ: [$(YQ)]"
	@echo "JQ: [$(JQ)]"
	@echo "KUBECTL: [$(KUBECTL)]"
	@echo "DOCKER: [$(DOCKER)]"
	@echo "HELM: [$(HELM)]"
	@echo "KIND: [$(KIND)]"
	@echo "INFO_FILE: [$(INFO_FILE)]"
	@echo "APP_NAME: [$(APP_NAME)]"
	@echo "VERSION: [$(VERSION)]"
	@echo "NAMESPACE: [$(NAMESPACE)]"
	@echo "FULLY_QUALIFIED_IMAGE_URL: [$(FULLY_QUALIFIED_IMAGE_URL)]"
	@echo "CLUSTER_NAME: [$(CLUSTER_NAME)]"
	@echo "DEPLOYMENT_RELEASE_NAME: [$(DEPLOYMENT_RELEASE_NAME)]"

build:
	$(DOCKER) build \
	-t $(IMAGE_NAME_TAG) \
	--pull \
	--no-cache \
	-f ./src/Dockerfile \
	./src

tag: 
	$(DOCKER) tag \
	$(IMAGE_NAME_TAG) \
	$(FULLY_QUALIFIED_IMAGE_URL)

load_image: 
	$(KIND) load \
	docker-image $(FULLY_QUALIFIED_IMAGE_URL) \
	--name $(CLUSTER_NAME)

deployment_manifest:
	$(HELM) template --debug \
	-f ../../deploy_charts/values.yaml \
	--set 'watcher.enabled=false' \
	--set 'producer.enabled=true' \
	--set 'workflow.enabled=false' \
	--set 'postgresdb.enabled=false' \
	../../deploy_charts	

deployment_install:
	$(HELM) upgrade --install \
	--debug \
	-n $(NAMESPACE) \
	-f ../../deploy_charts/values.yaml \
	--set 'watcher.enabled=false' \
	--set 'producer.enabled=true' \
	--set 'workflow.enabled=false' \
	--set 'postgresdb.enabled=false' \
	$(DEPLOYMENT_RELEASE_NAME) ../../deploy_charts

	