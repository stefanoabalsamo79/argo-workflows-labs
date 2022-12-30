#!/bin/sh

set -e

YQ=`which yq`
JQ=`which jq`
KUBECTL=`which kubectl`
INFO_FILE="./infra/info.yaml"
NAMESPACE=`$YQ e ".namespace" $INFO_FILE`
VALUES_FILE="deploy_charts/charts/workflow/values.yaml"

CIP=`$KUBECTL get svc -n $NAMESPACE postgres  -o json | $JQ -r '.spec.clusterIP'`
CPORT=`$KUBECTL get svc -n $NAMESPACE postgres  -o json | $JQ -r '.spec.ports[0].port'`

$YQ e ".postgresdb.ip=\"$CIP\"" \
$VALUES_FILE > "${VALUES_FILE}.tmp" && \
mv "${VALUES_FILE}.tmp" $VALUES_FILE

$YQ e ".postgresdb.port=\"$CPORT\"" \
$VALUES_FILE > "${VALUES_FILE}.tmp" && \
mv "${VALUES_FILE}.tmp" $VALUES_FILE