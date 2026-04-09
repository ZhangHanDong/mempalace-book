#!/bin/bash
# serve.sh — 本地启动 MemPalace Book 阅读服务
# 自动检测端口冲突，冲突时自动递增端口

set -euo pipefail

# ── 颜色输出 ──────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${RESET}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${RESET}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $*"; }
log_section() { echo -e "\n${BOLD}$*${RESET}"; }

# ── 参数 ──────────────────────────────────────────────────
ZH_PORT_START=${1:-3000}   # 中文版起始端口（可传参覆盖）
EN_PORT_START=${2:-3001}   # 英文版起始端口（可传参覆盖）
MAX_RETRY=20               # 最多尝试 20 个端口

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 检查依赖 ──────────────────────────────────────────────
check_mdbook() {
    if ! command -v mdbook &>/dev/null; then
        log_error "未找到 mdbook，请先安装："
        echo "       cargo install mdbook"
        echo "       # 或 brew install mdbook"
        exit 1
    fi
    log_ok "mdbook $(mdbook --version)"
}

# ── 端口检测 ──────────────────────────────────────────────
is_port_free() {
    local port=$1
    ! lsof -iTCP:"$port" -sTCP:LISTEN -t &>/dev/null
}

find_free_port() {
    local port=$1
    local count=0
    while ! is_port_free "$port"; do
        log_warn "端口 $port 已被占用，尝试 $((port + 1))..."
        port=$((port + 1))
        count=$((count + 1))
        if [ $count -ge $MAX_RETRY ]; then
            log_error "连续 $MAX_RETRY 个端口均被占用，请手动指定端口"
            exit 1
        fi
    done
    echo "$port"
}

# ── 启动单个 mdbook ───────────────────────────────────────
start_book() {
    local label=$1       # 显示名称
    local dir=$2         # book 目录（相对项目根）
    local start_port=$3  # 起始端口

    log_section "▶ 启动 $label"

    local book_path="$SCRIPT_DIR/$dir"
    if [ ! -d "$book_path" ]; then
        log_error "目录不存在：$book_path"
        return 1
    fi

    local port
    port=$(find_free_port "$start_port")
    log_info "使用端口：$port"

    mdbook serve "$book_path" -p "$port" --open &>/dev/null &
    local pid=$!

    # 等待服务就绪（最多 8 秒）
    local waited=0
    while ! curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" 2>/dev/null | grep -q "200"; do
        sleep 1
        waited=$((waited + 1))
        if [ $waited -ge 8 ]; then
            log_error "$label 启动超时（PID $pid），请检查日志"
            return 1
        fi
    done

    log_ok "$label 已就绪 → http://localhost:$port  (PID $pid)"
    echo "$pid"
}

# ── 退出清理 ──────────────────────────────────────────────
cleanup() {
    echo ""
    log_warn "正在停止服务..."
    pkill -f "mdbook serve" 2>/dev/null || true
    log_ok "已停止全部 mdbook 服务，再见！"
}
trap cleanup INT TERM

# ── 主流程 ────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}║   MemPalace Book — 本地阅读服务       ║${RESET}"
    echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}"
    echo ""

    check_mdbook

    local zh_pid en_pid

    zh_pid=$(start_book "中文版 (book)" "book" "$ZH_PORT_START")
    en_pid=$(start_book "英文版 (book-en)" "book-en" "$EN_PORT_START")

    echo ""
    echo -e "${GREEN}${BOLD}✓ 全部服务已启动${RESET}"
    echo ""
    log_info "按 Ctrl+C 停止所有服务"
    echo ""

    # 保持前台运行，等待用户中断
    wait
}

main "$@"
