#!/bin/bash

# Demo script showing the new interval-based monitoring

echo "🎯 TerminalHub Demo - Real-time Terminal Monitoring"
echo "================================================="
echo ""
echo "🔧 Key Features:"
echo "   ✅ Real-time terminal output streaming"
echo "   ✅ Full ANSI color and escape sequence support" 
echo "   ✅ Interval-based command execution"
echo "   ✅ Multi-client tabbed interface"
echo "   ✅ Advanced terminal emulation"
echo ""

SERVER="localhost:30080"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <start|test|stop>"
    echo ""
    echo "Commands:"
    echo "  start  - Start the server"
    echo "  test   - Run demo clients"
    echo "  stop   - Stop all processes"
    exit 1
fi

case "$1" in
    "start")
        echo "🚀 Starting server on port 30080..."
        python3 server.py &
        SERVER_PID=$!
        echo "Server PID: $SERVER_PID"
        echo ""
        echo "📱 Web interface will be available at:"
        echo "   http://localhost:30080"
        echo ""
        echo "⏱️  Waiting 3 seconds for server to start..."
        sleep 3
        echo "✅ Server should be ready!"
        ;;
        
    "test")
        echo "🧪 Starting demo clients..."
        echo ""
        
        # Demo 1: GPU monitoring (if nvidia-smi is available)
        if command -v nvidia-smi &> /dev/null; then
            echo "📊 Starting GPU Monitor (nvidia-smi every 2s) - with colors!"
            python3 client.py --cmd "nvidia-smi" --server "$SERVER" --title "🔥 GPU Monitor" --interval 2 &
            echo "   PID: $!"
        else
            echo "⚠️  nvidia-smi not available, using colorful GPU demo"
            python3 client.py --cmd 'echo -e "🔥 \033[1;31mGPU Monitor Demo\033[0m\n\033[32m✅ GPU 0: RTX 4090\033[0m - \033[33mTemp: 45°C\033[0m - \033[36mMem: 8GB/24GB\033[0m\n\033[32m✅ GPU 1: RTX 3080\033[0m - \033[33mTemp: 52°C\033[0m - \033[36mMem: 6GB/10GB\033[0m\n\033[1;35mUtilization: 75%\033[0m"' --server "$SERVER" --title "🔥 GPU Demo" --interval 3 &
            echo "   PID: $!"
        fi
        
        # Demo 2: System monitoring with obvious refresh
        echo "💻 Starting System Monitor (every 3s) - watch it clear and refresh!"
        python3 client.py --cmd "echo '🕐 Current time:' && date && echo && echo '📊 System load:' && uptime && echo && echo '💾 Memory usage:' && free -h | head -2 && echo && echo '🔢 Random number:' && echo \$RANDOM" --server "$SERVER" --title "💻 System Monitor" --interval 3 &
        echo "   PID: $!"
        
        # Demo 3: Network stats
        echo "🌐 Starting Network Monitor (every 5s)"
        python3 client.py --cmd "echo '=== Network Interfaces ===' && ip -brief addr && echo && echo '=== Network Stats ===' && cat /proc/net/dev | head -3" --server "$SERVER" --title "🌐 Network Stats" --interval 5 &
        echo "   PID: $!"
        
        # Demo 4: ANSI Color showcase
        echo "🎨 Starting Color Demo (every 4s)"
        python3 client.py --cmd 'echo -e "🎨 \033[1;37mANSI Color Test\033[0m\n\033[31m■ Red\033[0m \033[32m■ Green\033[0m \033[33m■ Yellow\033[0m \033[34m■ Blue\033[0m \033[35m■ Magenta\033[0m \033[36m■ Cyan\033[0m\n\033[1;91m■ Bright Red\033[0m \033[1;92m■ Bright Green\033[0m \033[1;93m■ Bright Yellow\033[0m \033[1;94m■ Bright Blue\033[0m\n\033[1mBold\033[0m \033[4mUnderline\033[0m \033[7mReverse\033[0m \033[3mItalic\033[0m"' --server "$SERVER" --title "🎨 Color Demo" --interval 4 &
        echo "   PID: $!"
        
        echo ""
        echo "✅ Demo clients started!"
        echo "📱 Open your browser to: http://$SERVER"
        echo "🎉 You should see 4 tabs with different monitoring data"
        echo ""
        echo "💡 Features to notice:"
        echo "   • 🎨 Rich ANSI color support (nvidia-smi colors preserved!)"
        echo "   • 📐 Full terminal width display (no header pane)"
        echo "   • ✨ Clean output without ANSI artifacts"
        echo "   • 🔄 Interval commands CLEAR and refresh (not accumulate!)"
        echo "   • 🎯 Color-coded status indicators and GPU information"
        echo "   • ⏰ Watch timestamps update to see clearing in action"
        echo ""
        echo "⏹️  Run '$0 stop' to stop all demo clients"
        ;;
        
    "stop")
        echo "🛑 Stopping all demo processes..."
        pkill -f "python3 client.py" 2>/dev/null
        pkill -f "python3 server.py" 2>/dev/null
        echo "✅ All processes stopped"
        ;;
        
    *)
        echo "❌ Invalid command: $1"
        echo "Usage: $0 <start|test|stop>"
        exit 1
        ;;
esac
