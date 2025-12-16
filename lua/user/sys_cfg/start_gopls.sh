#!/bin/bash
# ./start_gopls.sh 启动gopls守护进程，nvim和gopls守护进程通信
# GOPLS_BIN="/data00/home/lihao.hellohake/.local/share/nvim/mason/packages/gopls/gopls"
GOPLS_BIN="/data00/home/lihao.hellohake/.local/bin/trae-gopls"
SOCKET_FILE="/dev/shm/gopls-daemon-lihao.sock"
LOG_FILE="/tmp/gopls-daemon.log"

export GOMAXPROCS=64
export GOMEMLIMIT=150GiB
export GOGC=180

echo "========================================"
echo "Checking Gopls Binary..."

if [ ! -f "$GOPLS_BIN" ]; then
	echo "❌ Error: gopls binary not found at:"
	echo "   $GOPLS_BIN"
	exit 1
fi

echo "✅ Binary found. Version info:"
"$GOPLS_BIN" version
echo "========================================"

echo "Starting High-Performance Gopls Server..."
echo "Socket: $SOCKET_FILE"
rm -f "$SOCKET_FILE"

"$GOPLS_BIN" serve \
	-listen="unix;$SOCKET_FILE" \
	-listen.timeout=0
