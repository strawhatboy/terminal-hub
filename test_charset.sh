#!/bin/bash

echo "🔧 Testing TerminalHub Character Set Sequence Handling"
echo "This tests the (B character set sequences from top/htop in TerminalHub"
echo

# Start the server in background
echo "Starting Flask server..."
python server.py &
SERVER_PID=$!

# Wait for server to start
sleep 3

echo "Starting top command that generates (B sequences..."

# Test with top which generates the (B sequences
python client.py \
    --cmd "top -b -n 1" \
    --server "localhost:5000" \
    --title "Top with Character Sets" \
    --interval 3 &
CLIENT_PID1=$!

# Also test with a simple command that manually includes these sequences
python client.py \
    --cmd "echo -e 'Test \x1b(B ASCII mode \x1b)0 drawing chars \x1b(B back to ASCII'" \
    --server "localhost:5000" \
    --title "Character Set Test" \
    --interval 2 &
CLIENT_PID2=$!

echo
echo "📱 Open your browser to: http://localhost:5000"
echo
echo "You should see:"
echo "- Top command output WITHOUT visible (B characters"
echo "- Character set test output cleanly rendered"
echo "- All escape sequences properly handled by the terminal emulator"
echo
echo "If you still see (B characters, there may be additional sequences to handle."
echo
echo "Press Ctrl+C to stop the test..."

# Wait for interrupt
trap 'kill $CLIENT_PID1 $CLIENT_PID2 $SERVER_PID 2>/dev/null; echo -e "\n✓ Test stopped"; exit 0' INT
wait $CLIENT_PID1
