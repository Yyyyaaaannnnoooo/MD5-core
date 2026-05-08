#!/bin/bash
# Display Node.js status on screen

while true; do
    clear
    echo "========================================"
    echo "    CIAO MD5"
    echo "========================================"
    echo ""
    
    # Check if Node.js is running
    if sudo systemctl is-active --quiet node-app.service; then
        sudo journalctl -u node-app.service -n 10 --no-pager -o cat
    else
        echo "❌ Node.js: STOPPED"
        echo ""
        echo "Last error:"
        sudo journalctl -u node-app.service -n 3 --no-pager -o cat
    fi    
    sleep 0.2
done