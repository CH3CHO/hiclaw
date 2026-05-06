#!/bin/bash
# hiclaw-restart.sh - Restart all HiClaw component containers
#
# Usage:
#   ./hiclaw-restart.sh          # Full restart (default)
#   ./hiclaw-restart.sh --help   # Show this help
#
# Restart order:
#   Stop:  hiclaw-manager → hiclaw-worker-* → hiclaw-controller
#   Start: hiclaw-controller → hiclaw-manager → hiclaw-worker-*

# NOTE: Do NOT use `set -e`. The spec requires error handling that continues on failure.

# ============================================================
# Help
# ============================================================

if [ "${1:-}" = "--help" ]; then
    head -9 "$0"
    exit 0
fi

# ============================================================
# Utility functions (match hiclaw-install.sh style)
# ============================================================

log() {
    echo -e "\033[36m[HiClaw]\033[0m $1"
}

warn() {
    echo -e "\033[33m[HiClaw WARNING]\033[0m $1" >&2
}

error() {
    echo -e "\033[31m[HiClaw ERROR]\033[0m $1" >&2
    exit 1
}

# ============================================================
# Pre-flight: detect container runtime
# ============================================================

if command -v docker >/dev/null 2>&1; then
    DOCKER_CMD="docker"
elif command -v podman >/dev/null 2>&1; then
    DOCKER_CMD="podman"
else
    error "docker or podman command not found. Please install Docker Desktop or Podman Desktop first."
fi

if ! ${DOCKER_CMD} info >/dev/null 2>&1; then
    error "Docker/Podman is not running. Please start Docker Desktop or Podman Desktop."
fi

log "Using container runtime: ${DOCKER_CMD}"

# ============================================================
# Load env file
# ============================================================

ENV_FILE="${HOME}/hiclaw-manager.env"
[ ! -f "${ENV_FILE}" ] && [ -f "./hiclaw-manager.env" ] && ENV_FILE="./hiclaw-manager.env"

if [ -f "${ENV_FILE}" ]; then
    log "Loading config from: ${ENV_FILE}"
    set -a
    source "${ENV_FILE}"
    set +a
else
    warn "Env file not found: ${ENV_FILE} (using defaults)"
fi

# ============================================================
# Collect components
# ============================================================

# Manager
MANAGER_EXISTS=0
if ${DOCKER_CMD} ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^hiclaw-manager$"; then
    MANAGER_EXISTS=1
fi

# Controller
CONTROLLER_EXISTS=0
if ${DOCKER_CMD} ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^hiclaw-controller$"; then
    CONTROLLER_EXISTS=1
fi

# Workers (all hiclaw-worker-* containers, stopped or running)
WORKERS=$(${DOCKER_CMD} ps -a --format '{{.Names}}' 2>/dev/null | grep "^hiclaw-worker-" || true)

# Legacy proxy
PROXY_EXISTS=0
if ${DOCKER_CMD} ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^hiclaw-docker-proxy$"; then
    PROXY_EXISTS=1
fi

log "Found components:"
[ "${MANAGER_EXISTS}" = "1" ] && log "  - hiclaw-manager"
[ "${CONTROLLER_EXISTS}" = "1" ] && log "  - hiclaw-controller"
[ "${PROXY_EXISTS}" = "1" ] && log "  - hiclaw-docker-proxy (legacy)"
if [ -n "${WORKERS}" ]; then
    while read -r w; do log "  - ${w}"; done <<< "${WORKERS}"
fi

# ============================================================
# STOP PHASE
# Order: hiclaw-manager → hiclaw-worker-* → hiclaw-controller → hiclaw-docker-proxy
# ============================================================

log "Stopping HiClaw components..."

FAILED_STOPS=""

# Stop manager
if [ "${MANAGER_EXISTS}" = "1" ]; then
    if ${DOCKER_CMD} stop hiclaw-manager >/dev/null 2>&1; then
        log "  Stopped: hiclaw-manager"
    else
        warn "  Failed to stop: hiclaw-manager"
        FAILED_STOPS="${FAILED_STOPS} hiclaw-manager"
    fi
fi

# Stop workers (do NOT remove — preserve configuration)
if [ -n "${WORKERS}" ]; then
    while read -r w; do
        if ${DOCKER_CMD} stop "${w}" >/dev/null 2>&1; then
            log "  Stopped: ${w}"
        else
            warn "  Failed to stop: ${w}"
            FAILED_STOPS="${FAILED_STOPS} ${w}"
        fi
    done <<< "${WORKERS}"
fi

# Stop controller
if [ "${CONTROLLER_EXISTS}" = "1" ]; then
    if ${DOCKER_CMD} stop hiclaw-controller >/dev/null 2>&1; then
        log "  Stopped: hiclaw-controller"
    else
        warn "  Failed to stop: hiclaw-controller"
        FAILED_STOPS="${FAILED_STOPS} hiclaw-controller"
    fi
fi

# Stop legacy proxy
if [ "${PROXY_EXISTS}" = "1" ]; then
    if ${DOCKER_CMD} stop hiclaw-docker-proxy >/dev/null 2>&1; then
        log "  Stopped: hiclaw-docker-proxy"
    else
        warn "  Failed to stop: hiclaw-docker-proxy"
        FAILED_STOPS="${FAILED_STOPS} hiclaw-docker-proxy"
    fi
fi

log "All components stopped."

# ============================================================
# START PHASE
# Order: hiclaw-controller → hiclaw-manager → hiclaw-worker-*
# ============================================================

log "Starting HiClaw components..."

FAILED_STARTS=""

# Start controller first (it provides MinIO/Higress that manager depends on)
if [ "${CONTROLLER_EXISTS}" = "1" ]; then
    if ${DOCKER_CMD} start hiclaw-controller >/dev/null 2>&1; then
        log "  Started: hiclaw-controller"
    else
        warn "  Failed to start: hiclaw-controller"
        FAILED_STARTS="${FAILED_STARTS} hiclaw-controller"
    fi
fi

# Start manager
if [ "${MANAGER_EXISTS}" = "1" ]; then
    if ${DOCKER_CMD} start hiclaw-manager >/dev/null 2>&1; then
        log "  Started: hiclaw-manager"
    else
        warn "  Failed to start: hiclaw-manager"
        FAILED_STARTS="${FAILED_STARTS} hiclaw-manager"
    fi
fi

# Start workers one-by-one (use docker start to reuse existing configuration)
if [ -n "${WORKERS}" ]; then
    while read -r w; do
        if ${DOCKER_CMD} start "${w}" >/dev/null 2>&1; then
            log "  Started: ${w}"
        else
            warn "  Failed to start: ${w}"
            FAILED_STARTS="${FAILED_STARTS} ${w}"
        fi
    done <<< "${WORKERS}"
fi

# Start legacy proxy last
if [ "${PROXY_EXISTS}" = "1" ]; then
    if ${DOCKER_CMD} start hiclaw-docker-proxy >/dev/null 2>&1; then
        log "  Started: hiclaw-docker-proxy"
    else
        warn "  Failed to start: hiclaw-docker-proxy"
        FAILED_STARTS="${FAILED_STARTS} hiclaw-docker-proxy"
    fi
fi

# ============================================================
# SUMMARY
# ============================================================

echo ""
log "Restart complete."

if [ -n "${FAILED_STOPS}" ] || [ -n "${FAILED_STARTS}" ]; then
    echo ""
    warn "Some operations failed:"
    for c in ${FAILED_STOPS} ${FAILED_STARTS}; do
        echo "  - ${c}"
    done
    echo ""
    error "Restart completed with errors."
fi

log "All containers restarted successfully."
exit 0
