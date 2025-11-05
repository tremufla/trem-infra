#!/bin/bash
set -e

echo "🚀 Iniciando bootstrap do Argo CD..."

echo "Aguardando o Kubernetes ficar pronto..."
until kubectl version --output=json &>/dev/null; do sleep 5; done

echo "Verificando se o namespace 'argocd' existe..."
kubectl get namespace argocd &>/dev/null || {
  echo "Criando namespace 'argocd'..."
  kubectl create namespace argocd
}

echo "Instalando o Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Aguardando o Argo CD iniciar..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=180s || true

echo "📁 Aplicando manifests do diretório bootstrap/..."
if [ -d "bootstrap" ]; then
  echo "Aplicando 00-namespace.yaml..."
  kubectl apply -f bootstrap/00-namespace.yaml

  echo "Aplicando 01-application.yaml..."
  kubectl apply -f bootstrap/01-application.yaml
else
  echo "❌ Diretório 'bootstrap/' não encontrado. Abortando."
  exit 1
fi

echo "Aguardando o secret do admin ser criado..."
until kubectl -n argocd get secret argocd-initial-admin-secret &>/dev/null; do sleep 5; done

echo "Obtendo a senha inicial do Argo CD..."
ARGOCD_ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

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
