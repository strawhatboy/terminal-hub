#!/bin/bash

# TerminalHub Server Startup Script

echo "🚀 TerminalHub Server"
echo "===================="

# Check if Python is available
if ! command -v python &> /dev/null; then
    echo "❌ Python is not installed or not in PATH"
    exit 1
fi

# Check if pip is available
if ! command -v pip &> /dev/null; then
    echo "❌ pip is not installed or not in PATH"
    exit 1
fi

# Install dependencies if requirements.txt exists
if [ -f "requirements.txt" ]; then
    echo "📦 Installing dependencies..."
    pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies"
        exit 1
    fi
    echo "✅ Dependencies installed successfully"
else
    echo "⚠️  requirements.txt not found, skipping dependency installation"
fi

# Get server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="localhost"
fi

echo ""
echo "🌐 Server Information:"
echo "   Local URL:    http://localhost:30080"
echo "   Network URL:  http://$SERVER_IP:30080"
echo ""
echo "📋 Example client commands:"
echo "   python client.py --cmd 'nvitop' --server $SERVER_IP:30080 --title 'GPU Node 1'"
echo "   python client.py --cmd 'watch -n 1 nvidia-smi' --server $SERVER_IP:30080 --title 'GPU Node 2'"
echo "   python client.py --cmd 'htop' --server $SERVER_IP:30080 --title 'System Monitor'"
echo ""
echo "⚡ Starting server..."
echo "   Press Ctrl+C to stop the server"
echo ""

# Start the server
python server.py
