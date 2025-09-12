#!/bin/bash

# Launch the Node.js server in the background
node "server/index.js" &

# Get the PID of the server process
SERVER_PID=$!

# Wait 2 seconds for the server to start up
sleep 2

# Open Firefox to the local server
open -a "/Applications/Firefox Developer Edition.app/Contents/MacOS/firefox" "http://127.0.0.1:3000"

# Wait for the server process (optional - keeps script running until server stops)
wait $SERVER_PID