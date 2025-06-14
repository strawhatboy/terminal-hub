#!/bin/bash

echo "🖥️ Testing TerminalHub Terminal Emulator"
echo "This script tests TerminalHub's advanced terminal emulator with escape sequence handling"
echo

# Start the server in background
echo "Starting Flask server..."
python server.py &
SERVER_PID=$!

# Wait for server to start
sleep 3

echo "Starting htop with raw terminal output..."
echo "The web UI should now properly render htop with all formatting!"
echo

# Test with htop - now with raw terminal sequences
python client.py \
    --cmd "htop -d 5" \
    --server "localhost:30080" \
    --title "System Monitor (htop)" \
    --interval 10 &
CLIENT_PID1=$!

# Also test with other terminal tools
python client.py \
    --cmd "top -b -n 1" \
    --server "localhost:30080" \
    --title "Process List (top)" \
    --interval 5 &
CLIENT_PID2=$!

# Test with a colorized command
python client.py \
    --cmd "ls -la --color=always" \
    --server "localhost:30080" \
    --title "Directory Listing" \
    --interval 3 &
CLIENT_PID3=$!

echo
echo "📱 Open your browser to: http://localhost:30080"
echo
echo "You should see:"
echo "- htop with proper terminal formatting and colors"
echo "- Real cursor positioning and screen clearing"
echo "- Interactive-style display in the web interface"
echo "- No more raw escape sequences visible"
echo
echo "Press Ctrl+C to stop the test..."

# Wait for interrupt
trap 'kill $CLIENT_PID1 $CLIENT_PID2 $CLIENT_PID3 $SERVER_PID 2>/dev/null; echo -e "\n✓ Test stopped"; exit 0' INT
wait $CLIENT_PID1
