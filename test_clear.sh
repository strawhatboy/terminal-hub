#!/bin/bash

# Test script for interval clearing functionality

echo "🔄 Testing Interval Output Clearing"
echo "===================================="

SERVER="localhost:30080"

echo "Starting test client with short interval..."

# Test with a simple command that shows timestamp
python3 client.py --cmd 'echo "Current time: $(date)" && echo "Random number: $RANDOM" && echo "--- End of output ---"' --server "$SERVER" --title "🔄 Clear Test" --interval 2 &
CLIENT_PID=$!

echo "Test client started (PID: $CLIENT_PID)"
echo ""
echo "✅ What to observe:"
echo "   • Output should CLEAR every 2 seconds"
echo "   • You should see timestamp updating"
echo "   • Random number should change"
echo "   • Previous output should disappear"
echo ""
echo "📱 Open browser to: http://$SERVER"
echo "🔍 Watch the 'Clear Test' tab - output should refresh, not accumulate"
echo ""
echo "⏹️  Press Ctrl+C to stop the test"

# Wait for interrupt
trap "kill $CLIENT_PID 2>/dev/null; echo '🛑 Test client stopped'; exit 0" INT
wait $CLIENT_PID
