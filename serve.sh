#!/bin/bash
# serve.sh — MemPalace Book 本地阅读服务
# 启动中文版（默认）或英文版，自动处理端口冲突

set -euo pipefail

# ── 颜色 ─────────────────────────────────────────────────
GREEN='\033[0;32m'  YELLOW='\033[1;33m'  RED='\033[0;31m'
BLUE='\033[0;34m'   BOLD='\033[1m'       RESET='\033[0m'

info()  { echo -e "${BLUE}[INFO]${RESET}  $*" >&2; }
ok()    { echo -e "${GREEN}[ OK ]${RESET}  $*" >&2; }
warn()  { echo -e "${YELLOW}[WARN]${RESET}  $*" >&2; }
error() { echo -e "${RED}[ERR]${RESET}  $*" >&2; }

# ── 参数默认值 ───────────────────────────────────────────
EDITION=zh          # zh | en
PORT=3000
SHUTDOWN=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 帮助 ─────────────────────────────────────────────────
usage() {
    cat <<EOF
用法 / Usage:  ./serve.sh [OPTIONS]

选项 / Options:
  --en            启动英文版 / Start English edition
  -p, --port N    指定端口 / Set port (default: 3000)
  --shutdown      停止所有 mdbook 服务 / Stop all mdbook processes
  -h, --help      显示帮助 / Show this help

示例 / Examples:
  ./serve.sh              # 中文版 @ localhost:3000
  ./serve.sh --en         # English @ localhost:3000
  ./serve.sh -p 4000      # 中文版 @ localhost:4000
  ./serve.sh --en -p 4000 # English @ localhost:4000

停止 / Stop:
  运行中按 Ctrl+C，或运行 ./serve.sh --shutdown
  Press Ctrl+C while running, or run ./serve.sh --shutdown
EOF
    exit 0
}

# ── 解析参数 ─────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --en)       EDITION=en;    shift ;;
        -p|--port)  PORT="${2:?错误：-p 需要端口号}"; shift 2 ;;
        --shutdown)  SHUTDOWN=true; shift ;;
        -h|--help)  usage ;;
        *)          error "未知参数 / Unknown option: $1"; echo "运行 ./serve.sh --help 查看用法"; exit 1 ;;
    esac
done

# ── 版本配置 ─────────────────────────────────────────────
if [ "$EDITION" = "en" ]; then
    BOOK_DIR="$SCRIPT_DIR/book-en"
    LABEL="English edition"
    BANNER="MemPalace — First Principles of AI Memory"
else
    BOOK_DIR="$SCRIPT_DIR/book"
    LABEL="中文版"
    BANNER="MemPalace — AI 记忆的第一性原理"
fi

# ── 依赖检查 ─────────────────────────────────────────────
check_mdbook() {
    if ! command -v mdbook &>/dev/null; then
        error "未找到 mdbook / mdbook not found"
        echo "  cargo install mdbook"
        echo "  # 或 / or: brew install mdbook"
        exit 1
    fi
}

# ── 端口检测 ─────────────────────────────────────────────
is_port_free() {
    if command -v nc &>/dev/null; then
        ! nc -z 127.0.0.1 "$1" &>/dev/null
    else
        ! lsof -iTCP:"$1" -sTCP:LISTEN -t &>/dev/null
    fi
}

find_free_port() {
    local port=$1 tries=0
    while ! is_port_free "$port"; do
        warn "端口 $port 已占用，尝试 $((port + 1)) ..."
        port=$((port + 1))
        tries=$((tries + 1))
        if [ $tries -ge 20 ]; then
            error "连续 20 个端口均被占用，请用 -p 手动指定"
            exit 1
        fi
    done
    echo "$port"
}

# ── 退出清理 ─────────────────────────────────────────────
cleanup() {
    echo ""
    warn "正在停止 mdbook ..."
    kill "$MDBOOK_PID" 2>/dev/null || true
    wait "$MDBOOK_PID" 2>/dev/null || true
    ok "已停止，再见！"
}

# ── shutdown 模式 ────────────────────────────────────────
do_shutdown() {
    local count
    count=$(pgrep -f "mdbook serve" 2>/dev/null | wc -l | tr -d ' ') || count=0
    if [ "$count" -eq 0 ]; then
        warn "没有正在运行的 mdbook 服务 / No mdbook processes running"
    else
        pkill -f "mdbook serve" 2>/dev/null || true
        ok "已停止 $count 个 mdbook 进程 / Stopped $count mdbook process(es)"
    fi
    exit 0
}

# ── 主流程 ───────────────────────────────────────────────
main() {
    if [ "$SHUTDOWN" = "true" ]; then
        do_shutdown
    fi

    echo ""
    echo -e "  ${BOLD}$BANNER${RESET}"
    echo ""

    check_mdbook

    if [ ! -d "$BOOK_DIR" ]; then
        error "目录不存在 / Directory not found: $BOOK_DIR"
        exit 1
    fi

    local port
    port=$(find_free_port "$PORT")

    info "$LABEL → http://localhost:$port"

    mdbook serve "$BOOK_DIR" -p "$port" --open &>/dev/null &
    MDBOOK_PID=$!
    trap cleanup INT TERM

    # 等待服务就绪（最多 8 秒）
    local waited=0
    while ! curl -s -o /dev/null "http://localhost:$port" 2>/dev/null; do
        sleep 1
        waited=$((waited + 1))
        if [ $waited -ge 8 ]; then
            error "启动超时 / Timed out (PID $MDBOOK_PID)"
            exit 1
        fi
    done

    ok "$LABEL 已就绪 / Ready → ${BOLD}http://localhost:$port${RESET}"
    echo ""
    info "按 Ctrl+C 停止 / Press Ctrl+C to stop"
    echo ""

    wait "$MDBOOK_PID"
}

main
