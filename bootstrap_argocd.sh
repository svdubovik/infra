#! /bin/bash
# set -x

# The list of the variables
RELEASE_NAME="argocd"
ARGOCD_NAMESPACE="argocd"
GITHUB_SECRET="github-repo-secret.json"
ARGOCD_NOTIFICATIONS_SECRET="argocd-notifications-secret.json"

function usage {
    echo "usage: $0 [-h] -c kubecontext"
    echo "  -h      display help"
    echo "  -c      kubecontext   mandatory argument to specify the kubecontext where execute deploy"
    echo "  -e      environment   mandatory argument to specify the values file for specific environment"
}

# Parse arguments
while getopts "c:e:h" opt; do
  case $opt in
    c) kubecontext=$OPTARG;; # set kubecontext
    e) env_name=$OPTARG;; # set environment name
    h) usage && exit 1
  esac
done

# Avoid script execution without set kubecontext
if [[ -z $kubecontext ]]
then
  echo "Use the mandatory argument -c to set kubecontext" && exit 1
fi

if [[ -z $env_name ]]
then
  echo "Use the mandatory argument -e to set environment" && exit 1
fi

# Set k8s context
kubectl config use-context $kubecontext

echo "Prepare HELM repo and dependencies..."
helm repo add argo-cd https://argoproj.github.io/argo-helm > /dev/null
helm dep update charts/argocd/ > /dev/null

echo "Install argocd..."
helm upgrade $RELEASE_NAME charts/argocd/ \
  --install \
  --atomic \
  --wait \
  --create-namespace \
  --namespace $ARGOCD_NAMESPACE \
  --values ./charts/argocd//values-$env_name.yaml \
  --set argo-cd.installCRDs=false

# Remove helm deployment from k8s. ArgoCD managed by itself
kubectl delete secrets -l name=argocd,owner=helm
