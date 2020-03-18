#!/usr/bin/env bash
#
# Deploys services to OpenShift/Istio
# Assumes you are oc-login'd and istio is installed
#
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd -P)"
DEPLOYMENT_DIR="${PROJECT_ROOT}/gitops"

# name of project in which we are working
PROJECT=${PROJECT:-debugging-workshop}
ISTIO_NS=${ISTIO_NS:-istio-system}

oc new-project ${PROJECT} || true
oc adm policy add-scc-to-user privileged -z default -n ${PROJECT}
oc adm policy add-scc-to-user anyuid -z default -n ${PROJECT}
oc get ServiceMeshMemberRoll default -n ${ISTIO_NS} -o json | jq --arg PROJECT "${PROJECT}" '.spec.members[.spec.members | length] |= $PROJECT' | oc apply -f - -n ${ISTIO_NS}

# image
IKE_DOCKER_REGISTRY=quay.io IKE_DOCKER_REPOSITORY=bmajsak IKE_IMAGE_TAG=latest NAMESPACE=${PROJECT} ike install-operator -l -n ${PROJECT}

# deploy catalog
oc create -n ${PROJECT} -f ${DEPLOYMENT_DIR}/catalog.yml

# deploy inventory
oc create -n ${PROJECT} -f ${DEPLOYMENT_DIR}/inventory.yml

# deploy web
oc create -n ${PROJECT} -f ${DEPLOYMENT_DIR}/web.yml

# deploy gateway
oc create -n ${PROJECT} -f ${DEPLOYMENT_DIR}/gateway.yml