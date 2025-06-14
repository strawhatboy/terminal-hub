#!/bin/bash

echo "🧪 Testing TerminalHub Smooth Interval Updates"
echo "This script tests TerminalHub's smooth update functionality for interval commands"
echo

# Start the server in background
echo "Starting Flask server..."
python server.py &
SERVER_PID=$!

# Wait for server to start
sleep 3

# Test with a fast interval command to see smooth updates
echo "Starting smooth test client with 2-second intervals..."
python client.py \
    --cmd "echo -e '\033[32m✓ GPU Status: OK\033[0m\n\033[34mTemperature: 45°C\033[0m\n\033[33mMemory: 8GB/12GB\033[0m\n\033[36mUtilization: 78%\033[0m'" \
    --server "localhost:30080" \
    --title "Smooth Update Test" \
    --interval 2 &
CLIENT_PID=$!

echo
echo "📱 Open your browser to: http://localhost:30080"
echo
echo "You should see:"
echo "- The terminal updates every 2 seconds"
echo "- NO blinking or flashing during updates"
echo "- Smooth transitions between refresh cycles"
echo "- The content should update in-place without clearing first"
echo
echo "Press Ctrl+C to stop the test..."

# Wait for interrupt
trap 'kill $CLIENT_PID $SERVER_PID 2>/dev/null; echo -e "\n✓ Test stopped"; exit 0' INT
wait $CLIENT_PID
