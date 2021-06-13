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
}

# Parse arguments
while getopts "c:h" opt; do
  case $opt in
    c) kubecontext=$OPTARG;; # set kubecontext
    h) usage && exit 1
  esac
done

# Avoid script execution without set kubecontext
if [[ -z $kubecontext ]]
then
  echo "Use the mandatory argument -c to set kubecontext" && exit 1
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
  --set argo-cd.installCRDs=false

# TODO Add removing helm deployment from k8s. ArgoCD managed by itself
