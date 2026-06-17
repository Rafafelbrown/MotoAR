#!/bin/bash
# ── deploy.sh ────────────────────────────────────────────────────────────────
# Script de deploy completo do MotoAR no Kubernetes
#
# Uso:
#   ./deploy.sh           → deploy completo
#   ./deploy.sh build     → apenas build das imagens
#   ./deploy.sh apply     → apenas aplica os manifests
#   ./deploy.sh status    → mostra o status de todos os recursos
#   ./deploy.sh delete    → remove tudo do cluster
# ─────────────────────────────────────────────────────────────────────────────

set -e

REGISTRY="motoar"
TAG="${TAG:-latest}"
NAMESPACE="motoar"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERRO]${NC} $1"; exit 1; }

# ── Verificações ──────────────────────────────────────────────────────────────
check_deps() {
    command -v kubectl >/dev/null || error "kubectl não encontrado"
    command -v docker  >/dev/null || error "docker não encontrado"
    kubectl cluster-info >/dev/null 2>&1 || error "Cluster k8s não acessível"
    info "Dependências OK"
}

# ── Build das imagens Docker ──────────────────────────────────────────────────
build_images() {
    info "Build: motoar/pipeline:${TAG}"
    docker build -f Dockerfile.pipeline \
        -t "${REGISTRY}/pipeline:${TAG}" . || error "Falha no build do pipeline"

    info "Build: motoar/streamlit:${TAG}"
    docker build -f Dockerfile.streamlit \
        -t "${REGISTRY}/streamlit:${TAG}" . || error "Falha no build do streamlit"

    info "Build: motoar/frontend:${TAG}"
    docker build -f Dockerfile.frontend \
        -t "${REGISTRY}/frontend:${TAG}" . || error "Falha no build do frontend"

    info "Todas as imagens construídas com sucesso"
}

# ── Aplica os manifests Kubernetes ───────────────────────────────────────────
apply_manifests() {
    info "Criando namespace e recursos base..."
    kubectl apply -f k8s/base/namespace.yaml
    kubectl apply -f k8s/base/configmap.yaml
    kubectl apply -f k8s/base/storage.yaml

    info "Aguardando PVC ficar bound..."
    kubectl wait --for=condition=Bound pvc/motoar-data-pvc \
        -n ${NAMESPACE} --timeout=60s || warning "PVC pode demorar mais"

    info "Executando pipeline inicial (Job manual)..."
    kubectl apply -f k8s/pipeline/cronjob.yaml
    # Roda o job manual para popular os dados na primeira vez
    kubectl create job --from=cronjob/motoar-pipeline \
        motoar-pipeline-init -n ${NAMESPACE} 2>/dev/null || true

    info "Fazendo deploy dos serviços..."
    kubectl apply -f k8s/streamlit/deployment.yaml
    kubectl apply -f k8s/frontend/deployment.yaml
    kubectl apply -f k8s/frontend/hpa.yaml
    kubectl apply -f k8s/mlflow/deployment.yaml

    info "Aplicando Ingress..."
    kubectl apply -f k8s/base/ingress.yaml

    info "Manifests aplicados com sucesso"
}

# ── Status dos recursos ───────────────────────────────────────────────────────
show_status() {
    echo ""
    echo "════════════════════════════════════════"
    echo "  STATUS DO CLUSTER — MotoAR"
    echo "════════════════════════════════════════"
    echo ""
    echo "── Pods ──"
    kubectl get pods -n ${NAMESPACE} -o wide
    echo ""
    echo "── Services ──"
    kubectl get svc -n ${NAMESPACE}
    echo ""
    echo "── Ingress ──"
    kubectl get ingress -n ${NAMESPACE}
    echo ""
    echo "── CronJobs ──"
    kubectl get cronjob -n ${NAMESPACE}
    echo ""
    echo "── PVC ──"
    kubectl get pvc -n ${NAMESPACE}
    echo ""
    echo "── HPA ──"
    kubectl get hpa -n ${NAMESPACE}
}

# ── Remove tudo ───────────────────────────────────────────────────────────────
delete_all() {
    warning "Removendo todos os recursos MotoAR do cluster..."
    kubectl delete namespace ${NAMESPACE} --ignore-not-found=true
    kubectl delete pv motoar-data-pv --ignore-not-found=true
    info "Recursos removidos"
}

# ── Logs rápidos ──────────────────────────────────────────────────────────────
show_logs() {
    SERVICE="${1:-pipeline}"
    echo "── Logs: ${SERVICE} ──"
    kubectl logs -n ${NAMESPACE} \
        -l "app=motoar-${SERVICE}" \
        --tail=50 --follow
}

# ── Main ──────────────────────────────────────────────────────────────────────
CMD="${1:-all}"

case "${CMD}" in
    build)
        check_deps; build_images ;;
    apply)
        check_deps; apply_manifests ;;
    status)
        show_status ;;
    logs)
        show_logs "${2}" ;;
    delete)
        read -p "Tem certeza? (s/N): " confirm
        [[ "${confirm}" == "s" ]] && delete_all || echo "Cancelado" ;;
    all|*)
        check_deps
        build_images
        apply_manifests
        echo ""
        info "Deploy completo! Aguardando pods ficarem prontos..."
        kubectl wait --for=condition=Ready pods \
            -l "app.kubernetes.io/part-of=motoar-platform" \
            -n ${NAMESPACE} --timeout=120s || true
        show_status
        echo ""
        info "Acesse: http://motoar.local          (Dashboard React)"
        info "Acesse: http://motoar.local/app      (Streamlit)"
        info "Acesse: http://motoar.local/mlflow   (MLflow UI)"
        ;;
esac
