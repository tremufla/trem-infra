#!/bin/bash
set -e

echo "Aguardando o Kubernetes ficar pronto..."
until kubectl version --output=json &>/dev/null; do sleep 5; done

echo "Instalando o Argo CD..."
kubectl apply -n argocd --create-namespace \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Aplicando o bootstrap do repositório..."
kubectl apply -f https://raw.githubusercontent.com/tremufla/trem-infra/main/bootstrap/argo-bootstrap.yaml

echo "Aguardando o secret do admin ser criado..."
until kubectl -n argocd get secret argocd-initial-admin-secret &>/dev/null; do sleep 5; done

echo "Obtendo a senha inicial do Argo CD..."
ARGOCD_ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "✅ Bootstrap GitOps concluído!"
echo "----------------------------------------------------"
echo "Usuário: admin"
echo "Senha: $ARGOCD_ADMIN_PASSWORD"
echo "----------------------------------------------------"
echo ""

echo "Expondo o Argo CD localmente..."
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
sleep 5

echo "Argo CD disponível em: https://localhost:8080"
echo "Use o usuário e senha acima para acessar."
