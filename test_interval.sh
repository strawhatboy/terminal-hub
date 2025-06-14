#!/bin/bash

# Test script for TerminalHub interval functionality

echo "🧪 Testing TerminalHub with Interval Support"
echo "=============================================="

SERVER="localhost:30080"

# Test 1: Simple interval command
echo "Test 1: Simple date command with 2s interval"
python client.py --cmd "date && echo 'Test output with current time'" --server "$SERVER" --title "Date Test" --interval 2 &
TEST1_PID=$!

sleep 5

# Test 2: nvidia-smi if available
if command -v nvidia-smi &> /dev/null; then
    echo "Test 2: nvidia-smi with 3s interval"
    python client.py --cmd "nvidia-smi" --server "$SERVER" --title "GPU Test" --interval 3 &
    TEST2_PID=$!
else
    echo "Test 2: Skipped (nvidia-smi not available)"
fi

# Test 3: System info
echo "Test 3: System info with 4s interval"
python client.py --cmd "uptime && echo '---' && free -h | head -2" --server "$SERVER" --title "System Test" --interval 4 &
TEST3_PID=$!

echo ""
echo "✅ Test clients started!"
echo "📱 Open your browser to: http://$SERVER"
echo ""
echo "⏱️  Tests will run for 30 seconds..."

sleep 30

echo ""
echo "🛑 Stopping test clients..."
kill $TEST1_PID 2>/dev/null
kill $TEST2_PID 2>/dev/null 
kill $TEST3_PID 2>/dev/null

echo "✅ Tests completed!"
