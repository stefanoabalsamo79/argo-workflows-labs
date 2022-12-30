#!/bin/sh
set -e

YQ=`which yq`
KUBECTL=`which kubectl`
DOCKER=`which docker`
KIND=`which kind`
INFO_FILE="infra/info.yaml"
MANIFEST_FILE="infra/v3.3.10/install.yaml"

ENV=$1

CLUSTER_NAME=`$YQ e ".clusterName" $INFO_FILE`

ARGO_CLI_IMAGE_SRC=`$YQ e ".argocli.$ENV.imageSrc" $INFO_FILE`
ARGO_CLI_IMAGE_DEST=`$YQ e ".argocli.$ENV.imageDest" $INFO_FILE`
ARGO_CLI_IMAGE_TAG_DEST=`$YQ e ".argocli.$ENV.imageTagDest" $INFO_FILE`

# updating image
ARGO_CLI_FULLY_QUALIFIED_IMAGE_URL=${ARGO_CLI_IMAGE_DEST}:${ARGO_CLI_IMAGE_TAG_DEST}
$YQ e -i "select(.kind == \"Deployment\" and .metadata.name == \"argo-server\").spec.template.spec.containers[0].image |= \"$ARGO_CLI_FULLY_QUALIFIED_IMAGE_URL\"" $MANIFEST_FILE

$DOCKER pull $ARGO_CLI_IMAGE_SRC
$DOCKER tag $ARGO_CLI_IMAGE_SRC $ARGO_CLI_FULLY_QUALIFIED_IMAGE_URL

$KIND load docker-image \
$ARGO_CLI_FULLY_QUALIFIED_IMAGE_URL \
--name $CLUSTER_NAME

WORKFLOW_CONTROLLER_IMAGE_SRC=`$YQ e ".workflow-controller.$ENV.imageSrc" $INFO_FILE`
WORKFLOW_CONTROLLER_IMAGE_DEST=`$YQ e ".workflow-controller.$ENV.imageDest" $INFO_FILE`
WORKFLOW_CONTROLLER_IMAGE_TAG_DEST=`$YQ e ".workflow-controller.$ENV.imageTagDest" $INFO_FILE`

# updating image
WORKFLOW_CONTROLLER_FULLY_QUALIFIED_IMAGE_URL=${WORKFLOW_CONTROLLER_IMAGE_DEST}:${WORKFLOW_CONTROLLER_IMAGE_TAG_DEST}
$YQ e -i "select(.kind == \"Deployment\" and .metadata.name == \"workflow-controller\").spec.template.spec.containers[0].image |= \"$WORKFLOW_CONTROLLER_FULLY_QUALIFIED_IMAGE_URL\"" $MANIFEST_FILE

$DOCKER pull $WORKFLOW_CONTROLLER_IMAGE_SRC
$DOCKER tag $WORKFLOW_CONTROLLER_IMAGE_SRC $WORKFLOW_CONTROLLER_FULLY_QUALIFIED_IMAGE_URL

$KIND load docker-image \
$WORKFLOW_CONTROLLER_FULLY_QUALIFIED_IMAGE_URL \
--name $CLUSTER_NAME

ARGO_EXEC_IMAGE_SRC=`$YQ e ".argoexec.$ENV.imageSrc" $INFO_FILE`
ARGO_EXEC_IMAGE_DEST=`$YQ e ".argoexec.$ENV.imageDest" $INFO_FILE`
ARGO_EXEC_IMAGE_TAG_DEST=`$YQ e ".argoexec.$ENV.imageTagDest" $INFO_FILE`

# updating image
ARGO_EXEC_FULLY_QUALIFIED_IMAGE_URL=${ARGO_EXEC_IMAGE_DEST}:${ARGO_EXEC_IMAGE_TAG_DEST}
$YQ e -i "select(.kind == \"Deployment\" and .metadata.name == \"workflow-controller\").spec.template.spec.containers[0].args[3] |= \"$ARGO_EXEC_FULLY_QUALIFIED_IMAGE_URL\"" $MANIFEST_FILE

$DOCKER pull $ARGO_EXEC_IMAGE_SRC
$DOCKER tag $ARGO_EXEC_IMAGE_SRC $ARGO_EXEC_FULLY_QUALIFIED_IMAGE_URL

$KIND load docker-image \
$ARGO_EXEC_FULLY_QUALIFIED_IMAGE_URL \
--name $CLUSTER_NAME
