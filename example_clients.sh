#!/bin/bash

# Example client connections script
# This script demonstrates how to connect multiple clients with different monitoring commands

if [ $# -eq 0 ]; then
    echo "Usage: $0 <server-ip:port>"
    echo "Example: $0 192.168.1.100:30080"
    exit 1
fi

SERVER=$1

echo "🔌 Connecting example clients to server: $SERVER"
echo ""

# Function to start a client in background
start_client() {
    local cmd="$1"
    local title="$2"
    local extra_args="$3"
    echo "Starting: $title"
    python client.py --cmd "$cmd" --server "$SERVER" --title "$title" $extra_args &
    echo "  PID: $!"
    echo ""
}

# Start various monitoring clients
start_client "date && echo '=== System Info ===' && uptime && echo '=== Memory ===' && free -h" "System Overview" "--interval 2"

start_client "ps aux --sort=-%cpu | head -10" "Top CPU Processes" "--interval 3"

start_client "df -h" "Disk Usage" "--interval 5"

start_client "cat /proc/loadavg && echo && cat /proc/meminfo | grep -E 'MemTotal|MemFree|MemAvailable'" "System Stats" "--interval 2"

# If nvidia-smi is available, start GPU monitoring
if command -v nvidia-smi &> /dev/null; then
    start_client "nvidia-smi" "NVIDIA GPU" "--interval 1"
fi

# If nvitop is available, start nvitop monitoring
if command -v nvitop &> /dev/null; then
    start_client "nvitop -1" "GPU Monitor (nvitop)" ""
fi

echo "✅ Example clients started!"
echo "📱 Open your browser to: http://$SERVER"
echo ""
echo "⚠️  To stop all clients, press Ctrl+C or run: pkill -f 'python client.py'"

# Wait for user input to keep script running
read -p "Press Enter to stop all clients..." 

# Kill all client processes
pkill -f "python client.py"
echo "🛑 All clients stopped."
