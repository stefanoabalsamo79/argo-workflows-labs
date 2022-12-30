#!/bin/sh
set -e

YQ=`which yq`
DOCKER=`which docker`
KIND=`which kind`
INFO_FILE="infra/info.yaml"
DEPLOYMENT_FILE="deploy_charts/charts/postgresdb/templates/deployment.yaml"

CLUSTER_NAME=`$YQ e ".clusterName" $INFO_FILE`
POSTGRESDB_IMAGE_SRC=`$YQ e ".spec.template.spec.containers[0].image" $DEPLOYMENT_FILE`
POSTGRESDB_FULLY_QUALIFIED_IMAGE_URL=${POSTGRESDB_IMAGE_SRC}

$DOCKER pull $POSTGRESDB_IMAGE_SRC
$DOCKER tag $POSTGRESDB_IMAGE_SRC $POSTGRESDB_IMAGE_SRC

$KIND load docker-image \
$POSTGRESDB_IMAGE_SRC \
--name $CLUSTER_NAME
