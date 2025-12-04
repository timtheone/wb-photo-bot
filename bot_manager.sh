#!/bin/bash

# Bot Manager Script
# Usage: ./bot_manager.sh {start|stop|restart|status|logs}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VENV_DIR="$SCRIPT_DIR/venv"
BOT_SCRIPT="$SCRIPT_DIR/bot.py"
PID_FILE="$SCRIPT_DIR/bot.pid"
LOG_FILE="$SCRIPT_DIR/bot.log"
ERROR_LOG="$SCRIPT_DIR/bot_error.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if bot is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Function to start the bot
start_bot() {
    if is_running; then
        echo -e "${YELLOW}Bot is already running (PID: $(cat $PID_FILE))${NC}"
        return 1
    fi

    # Check if virtual environment exists
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${RED}Virtual environment not found. Creating it...${NC}"
        python3.11 -m venv "$VENV_DIR"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to create virtual environment${NC}"
            return 1
        fi
    fi

    # Activate venv
    source "$VENV_DIR/bin/activate"
    
    # Check if dependencies are installed
    if ! python3.11 -c "import telegram" 2>/dev/null; then
        echo -e "${YELLOW}Installing dependencies...${NC}"
        pip install --upgrade pip -q
        pip install -r requirements.txt -q
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to install dependencies${NC}"
            return 1
        fi
    fi

    # Check if config.py exists
    if [ ! -f "$SCRIPT_DIR/config.py" ]; then
        echo -e "${RED}config.py not found! Please create it with your API tokens.${NC}"
        return 1
    fi

    echo -e "${GREEN}Starting bot...${NC}"
    
    # Start bot in background using Python 3.11
    nohup python3.11 "$BOT_SCRIPT" > "$LOG_FILE" 2> "$ERROR_LOG" &
    PID=$!
    echo $PID > "$PID_FILE"
    
    # Wait a moment to check if it started successfully
    sleep 2
    if is_running; then
        echo -e "${GREEN}Bot started successfully (PID: $PID)${NC}"
        echo -e "${GREEN}Logs: $LOG_FILE${NC}"
        echo -e "${GREEN}Errors: $ERROR_LOG${NC}"
        return 0
    else
        echo -e "${RED}Bot failed to start. Check $ERROR_LOG for details${NC}"
        rm -f "$PID_FILE"
        return 1
    fi
}

# Function to stop the bot
stop_bot() {
    if ! is_running; then
        echo -e "${YELLOW}Bot is not running${NC}"
        return 1
    fi

    PID=$(cat "$PID_FILE")
    echo -e "${YELLOW}Stopping bot (PID: $PID)...${NC}"
    
    kill "$PID" 2>/dev/null
    sleep 2
    
    # Force kill if still running
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}Force killing bot...${NC}"
        kill -9 "$PID" 2>/dev/null
        sleep 1
    fi
    
    rm -f "$PID_FILE"
    
    if ! ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${GREEN}Bot stopped successfully${NC}"
        return 0
    else
        echo -e "${RED}Failed to stop bot${NC}"
        return 1
    fi
}

# Function to restart the bot
restart_bot() {
    echo -e "${YELLOW}Restarting bot...${NC}"
    stop_bot
    sleep 1
    start_bot
}

# Function to show status
show_status() {
    if is_running; then
        PID=$(cat "$PID_FILE")
        echo -e "${GREEN}Bot is running (PID: $PID)${NC}"
        echo -e "Started: $(ps -p $PID -o lstart= 2>/dev/null || echo 'N/A')"
        echo -e "CPU: $(ps -p $PID -o %cpu= 2>/dev/null || echo 'N/A')%"
        echo -e "Memory: $(ps -p $PID -o %mem= 2>/dev/null || echo 'N/A')%"
        return 0
    else
        echo -e "${RED}Bot is not running${NC}"
        return 1
    fi
}

# Function to show logs
show_logs() {
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${YELLOW}No log file found${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Showing last 50 lines of bot.log (Ctrl+C to exit):${NC}"
    tail -f -n 50 "$LOG_FILE"
}

# Main command handler
case "$1" in
    start)
        start_bot
        ;;
    stop)
        stop_bot
        ;;
    restart)
        restart_bot
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the bot in the background"
        echo "  stop    - Stop the running bot"
        echo "  restart - Restart the bot"
        echo "  status  - Show bot status and process info"
        echo "  logs    - Show and follow bot logs (Ctrl+C to exit)"
        exit 1
        ;;
esac

exit $?

