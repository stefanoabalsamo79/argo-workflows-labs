YQ:=$(shell which yq)
KUBECTL:=$(shell which kubectl)
DOCKER:=$(shell which docker)
HELM:=$(shell which helm)
KIND:=$(shell which kind)
HAS_YQ:=$(shell which yq > /dev/null 2> /dev/null && echo true || echo false)
HAS_KUBECTL:=$(shell which kubectl > /dev/null 2> /dev/null && echo true || echo false)
HAS_DOCKER:=$(shell which docker > /dev/null 2> /dev/null && echo true || echo false)
HAS_HELM:=$(shell which helm > /dev/null 2> /dev/null && echo true || echo false)
HAS_KIND:=$(shell which kind > /dev/null 2> /dev/null && echo true || echo false)
INFO_FILE:="./infra/info.yaml"
WORKFLOW_VALUES:="deploy_charts/charts/workflow/values.yaml"
WORKFLOW_RELEASE_NAME:=$(shell ${YQ} e '.deployementReleaseName' ${WORKFLOW_VALUES})
POSTGRESDB_VALUES:="deploy_charts/charts/postgresdb/values.yaml"
POSTGRESDB_RELEASE_NAME:=$(shell ${YQ} e '.deployementReleaseName' ${POSTGRESDB_VALUES})
CLUSTER_NAME:=$(shell ${YQ} e '.clusterName' ${INFO_FILE})
DEFAULT_CLUSTER_NAME:=$(shell ${YQ} e '.defaultClusterName' ${INFO_FILE})
NAMESPACE:=$(shell ${YQ} e '.namespace' ${INFO_FILE})

check_prerequisites:
ifeq ($(HAS_YQ),false) 
	$(info yq not installed!)
	@exit 1
endif
ifeq ($(HAS_KUBECTL),false) 
	$(info kubectl not installed!)
	@exit 1
endif
ifeq ($(HAS_DOCKER),false) 
	$(info docker not installed!)
	@exit 1
endif
ifeq ($(HAS_HELM),false) 
	$(info helm not installed!)
	@exit 1
endif
ifeq ($(HAS_KIND),false) 
	$(info kind not installed!)
	@exit 1
endif

print_mk_var: check_prerequisites
	@echo "YQ: [$(YQ)]"
	@echo "KUBECTL: [$(KUBECTL)]"
	@echo "DOCKER: [$(DOCKER)]"
	@echo "HELM: [$(HELM)]"
	@echo "KIND: [$(KIND)]"
	@echo "INFO_FILE: [$(INFO_FILE)]"
	@echo "WORKFLOW_VALUES: [$(WORKFLOW_VALUES)]"
	@echo "WORKFLOW_RELEASE_NAME: [$(WORKFLOW_RELEASE_NAME)]"
	@echo "POSTGRESDB_VALUES: [$(POSTGRESDB_VALUES)]"
	@echo "POSTGRESDB_RELEASE_NAME: [$(POSTGRESDB_RELEASE_NAME)]"
	@echo "CLUSTER_NAME: [$(CLUSTER_NAME)]"
	@echo "DEFAULT_CLUSTER_NAME: [$(DEFAULT_CLUSTER_NAME)]"
	@echo "NAMESPACE: [$(NAMESPACE)]"

cluster_start: check_prerequisites
	$(KIND) create cluster

cluster_delete: check_prerequisites
	$(KIND) delete cluster --name $(CLUSTER_NAME)
	$(KIND) delete cluster --name $(DEFAULT_CLUSTER_NAME)

create_cluster: check_prerequisites
	$(KIND) create \
	cluster --config=infra/cluster.yaml \
	--name $(CLUSTER_NAME)

set_context_cluster: check_prerequisites
	$(KUBECTL) config set-context $(CLUSTER_NAME)

cluster_info: check_prerequisites
	$(KUBECTL) cluster-info --context kind-$(CLUSTER_NAME)

ingress_controller_install: check_prerequisites
	$(KUBECTL) apply -f infra/ingress_controller.yaml
	@sleep 30
	$(MAKE) wait_for_ingress_controller
  
wait_for_ingress_controller: check_prerequisites
	$(KUBECTL) wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

handle_images: check_prerequisites
	./utils/handleArgoImages.sh local

create_namespace: check_prerequisites
	$(KUBECTL) create namespace $(NAMESPACE)

argo_workflows_install: check_prerequisites
	$(KUBECTL) apply \
	-n $(NAMESPACE) \
	-f infra/v3.3.10/install.yaml

wait_for_argo_server: check_prerequisites
	$(KUBECTL) wait --namespace $(NAMESPACE) \
  --for=condition=ready pod \
  --selector=app=argo-server \
  --timeout=90s
	
wait_for_argo_controller: check_prerequisites
	$(KUBECTL) wait --namespace $(NAMESPACE) \
  --for=condition=ready pod \
  --selector=app=workflow-controller \
  --timeout=90s

wait_for_postgres_deployment: check_prerequisites
	$(KUBECTL) wait --namespace $(NAMESPACE) \
  --for=condition=ready pod \
  --selector=app=postgres \
  --timeout=90s

patch_server_auth: check_prerequisites
	$(KUBECTL) patch deployment \
  argo-server \
  --namespace argo \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [ "server", "--auth-mode=server"]}]'
	
pv_pvc_install: check_prerequisites
	$(KUBECTL) apply -n $(NAMESPACE) -f infra/pv.yaml
	$(KUBECTL) apply -n $(NAMESPACE) -f infra/pvc.yaml

wait_for_pvc_bound: check_prerequisites
	kubectl wait \
	-n argo \
	--for=jsonpath='{.status.phase}'=Bound \
	pvc/pvc-1

producer_build_tag_push_image_apply: check_prerequisites
	$(MAKE) -C ./containers/producer print_mk_var build tag load_image deployment_install

watcher_build_tag_push_image_apply: check_prerequisites
	$(MAKE) -C ./containers/watcher print_mk_var build tag load_image deployment_install

file_handler_build_tag_push_image: check_prerequisites
	$(MAKE) -C ./containers/filehandler print_mk_var build tag load_image

file_filter_build_tag_push_image: check_prerequisites
	$(MAKE) -C ./containers/filefilter print_mk_var build tag load_image

file_loader_build_tag_push_image: check_prerequisites
	$(MAKE) -C ./containers/fileloader print_mk_var build tag load_image

wait_for_producer: check_prerequisites
	$(KUBECTL) wait --namespace $(NAMESPACE) \
  --for=condition=ready pod \
  --selector=app=producer \
  --timeout=90s

wait_for_watcher: check_prerequisites
	$(KUBECTL) wait --namespace $(NAMESPACE) \
  --for=condition=ready pod \
  --selector=app=watcher \
  --timeout=90s

sample_workflow_prerequisites_install: check_prerequisites
	$(KUBECTL) create role event-role -n $(NAMESPACE) --verb=list,update --resource=workflows.argoproj.io
	$(KUBECTL) create sa event-role -n $(NAMESPACE)
	$(KUBECTL) create rolebinding event-role -n $(NAMESPACE) --role=event-role --serviceaccount=argo:event-role
	$(KUBECTL) apply -n $(NAMESPACE) -f infra/role.yaml
	$(KUBECTL) apply -n $(NAMESPACE) -f infra/secret.yaml
	@sleep 10

sample_workflow_install: check_prerequisites
	$(HELM) upgrade --install \
	--debug \
	-n $(NAMESPACE) \
	-f ./deploy_charts/values.yaml \
	--set 'watcher.enabled=false' \
	--set 'producer.enabled=false' \
	--set 'workflow.enabled=true' \
	--set 'postgresdb.enabled=false' \
	$(WORKFLOW_RELEASE_NAME) ./deploy_charts	

postgresdb_install: check_prerequisites
	./utils/handlePostgresImages.sh
	$(HELM) upgrade --install \
	--debug \
	-n $(NAMESPACE) \
	-f ./deploy_charts/values.yaml \
	--set 'watcher.enabled=false' \
	--set 'producer.enabled=false' \
	--set 'workflow.enabled=false' \
	--set 'postgresdb.enabled=true' \
	$(POSTGRESDB_RELEASE_NAME) ./deploy_charts
	./utils/handlePostgresSvc.sh

all:
	$(MAKE) print_mk_var \
	cluster_start \
	create_cluster \
	set_context_cluster \
	cluster_info \
	ingress_controller_install \
	wait_for_ingress_controller \
	handle_images \
	create_namespace \
	postgresdb_install \
	wait_for_postgres_deployment \
	argo_workflows_install \
	wait_for_argo_controller \
	wait_for_argo_server \
	patch_server_auth \
	wait_for_argo_server \
	pv_pvc_install \
	wait_for_pvc_bound \
	sample_workflow_prerequisites_install \
	file_handler_build_tag_push_image \
	file_filter_build_tag_push_image \
	file_loader_build_tag_push_image \
	sample_workflow_install \
	watcher_build_tag_push_image_apply \
	wait_for_watcher \
	producer_build_tag_push_image_apply \
	wait_for_producer \

clean_up: cluster_delete
