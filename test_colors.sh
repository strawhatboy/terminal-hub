#!/bin/bash

# Test script for ANSI color support

echo "🎨 Testing ANSI Color Support"
echo "=============================="

SERVER="localhost:30080"

echo "Starting test client with nvidia-smi..."

# Test with nvidia-smi to see colors

# Fallback test with ANSI colors
python3 client.py --cmd 'echo -e "\033[31mRed text\033[0m \033[32mGreen text\033[0m \033[33mYellow text\033[0m \033[34mBlue text\033[0m \033[35mMagenta text\033[0m \033[36mCyan text\033[0m \033[1mBold text\033[0m"' --server "$SERVER" --title "🎨 Color Test" --interval 2 &
CLIENT_PID=$!
echo "Color test client started (PID: $CLIENT_PID)"


echo ""
echo "✅ Test client running!"
echo "📱 Open browser to: http://$SERVER"
echo "🎨 You should see proper colors in the output"
echo ""
echo "⏹️  Press Ctrl+C to stop the test client"

# Wait for interrupt
trap "kill $CLIENT_PID 2>/dev/null; echo '🛑 Test client stopped'; exit 0" INT
wait $CLIENT_PID
