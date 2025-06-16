#!/bin/bash

echo "🔄 Testing TerminalHub Keep-Alive & Auto-Reconnection"
echo "====================================================="
echo
echo "This script tests the new keep-alive functionality:"
echo "• Heartbeat mechanism (every 30 seconds)"
echo "• Automatic re-registration when server restarts"
echo "• Graceful handling of connection failures"
echo "• Stale client cleanup (after 5 minutes)"
echo

# Start the server in background
echo "Starting TerminalHub server..."
python server.py &
SERVER_PID=$!

# Wait for server to start
sleep 3

echo "Starting test client with heartbeat..."
python client.py \
    --cmd "date && echo 'Client alive at:' && date" \
    --server "localhost:30080" \
    --title "Keep-Alive Test Client" \
    --interval 10 &
CLIENT_PID=$!

echo
echo "📱 Open your browser to: http://localhost:30080"
echo
echo "🧪 Test Scenarios:"
echo "1. Watch the client in the web UI (should show regular updates)"
echo "2. Kill the server process (pkill -f server.py)"
echo "3. Restart the server (python server.py &)"
echo "4. The client should automatically re-register and appear in the UI again"
echo
echo "💡 The client sends heartbeats every 30 seconds"
echo "💡 The server removes stale clients after 5 minutes of no heartbeat"
echo "💡 Clients automatically re-register when the server restarts"
echo
echo "Press Ctrl+C to stop the test..."

# Function to restart server (for demonstration)
restart_server() {
    echo
    echo "🔄 Simulating server restart..."
    kill $SERVER_PID 2>/dev/null
    sleep 2
    echo "🚀 Restarting server..."
    python server.py &
    SERVER_PID=$!
    echo "✅ Server restarted. Client should re-register automatically."
}

# Set up trap for demonstration
trap 'echo -e "\n🔄 To test reconnection, run: kill \$SERVER_PID && python server.py &"' USR1

# Wait for interrupt
trap 'kill $CLIENT_PID $SERVER_PID 2>/dev/null; echo -e "\n✓ Test stopped"; exit 0' INT
wait $CLIENT_PID
