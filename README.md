# WB Bot - Wildberries Product Photo Fetcher

A Telegram bot that fetches product photos from Wildberries by article numbers.

## Features

- Fetches product photos from Wildberries API
- Supports multiple article numbers in one message
- Handles up to 100 articles per request
- Sends photos in media groups
- Provides detailed summary reports
- Runs in the background on your server

## Prerequisites

- Ubuntu 22.04 (or similar Linux distribution)
- Python 3.11 installed
- Telegram Bot Token (from [@BotFather](https://t.me/BotFather))
- Wildberries API Tokens (from your WB seller account)

## Installation

### 1. Install Python 3.11 (if not already installed)

```bash
sudo apt update
sudo apt install python3.11 python3.11-venv -y
```

### 2. Clone or upload the project files

Make sure you have these files in your project directory:
- `bot.py` - Main bot script
- `config.py` - Configuration file with API tokens
- `requirements.txt` - Python dependencies
- `bot_manager.sh` - Bot management script

### 3. Configure API tokens

Edit `config.py` and add your tokens:

```python
TELEGRAM_TOKEN = "YOUR_TELEGRAM_BOT_TOKEN"
WB_TOKEN_1 = "YOUR_WB_TOKEN_FOR_SHOP_1"
WB_TOKEN_2 = "YOUR_WB_TOKEN_FOR_SHOP_2"
```

**Important:** Never commit `config.py` to version control! It's already in `.gitignore`.

### 4. Make the management script executable

```bash
chmod +x bot_manager.sh
```

## Usage

### Using the Bot Manager Script

The `bot_manager.sh` script provides an easy way to manage your bot:

#### Start the bot

```bash
./bot_manager.sh start
```

This will:
- Create a virtual environment (if it doesn't exist)
- Install required dependencies
- Start the bot in the background
- Create log files (`bot.log` and `bot_error.log`)

#### Stop the bot

```bash
./bot_manager.sh stop
```

#### Restart the bot

```bash
./bot_manager.sh restart
```

#### Check bot status

```bash
./bot_manager.sh status
```

Shows:
- Whether the bot is running
- Process ID (PID)
- Start time
- CPU and memory usage

#### View logs

```bash
./bot_manager.sh logs
```

Shows the last 50 lines of logs and follows new entries in real-time. Press `Ctrl+C` to exit.

#### Show help

```bash
./bot_manager.sh
```

### Manual Usage (Alternative)

If you prefer to run the bot manually:

```bash
# Create virtual environment
python3.11 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Run the bot
python bot.py
```

To run in the background:
```bash
nohup python bot.py > bot.log 2>&1 &
```

## How the Bot Works

1. **User sends article numbers** - The bot extracts all numbers from the message
2. **Removes duplicates** - Each article number is processed only once
3. **Fetches photos** - For each article, the bot queries the Wildberries API
4. **Sends photos** - Photos are sent in groups of 10 (Telegram media group limit)
5. **Sends summary** - A detailed report with found/not found articles

### Example Usage

Send a message to your bot:
```
12345 67890 11111
```

The bot will:
1. Extract article numbers: `12345`, `67890`, `11111`
2. Search for photos in Wildberries
3. Send found photos
4. Send a summary report

## File Structure

```
wb_bot/
├── bot.py              # Main bot script
├── config.py           # API tokens (not in git)
├── config_example.py   # Example config file
├── requirements.txt    # Python dependencies
├── bot_manager.sh      # Management script
├── README.md          # This file
├── .gitignore         # Git ignore rules
├── venv/              # Virtual environment (created automatically)
├── bot.pid            # Process ID file (created automatically)
├── bot.log            # Bot output logs (created automatically)
└── bot_error.log      # Error logs (created automatically)
```

## Troubleshooting

### Bot won't start

1. **Check Python version:**
   ```bash
   python3.11 --version
   ```

2. **Check if config.py exists:**
   ```bash
   ls -la config.py
   ```

3. **Check error logs:**
   ```bash
   cat bot_error.log
   ```

4. **Verify tokens are correct** in `config.py`

### Bot stops unexpectedly

1. **Check logs:**
   ```bash
   ./bot_manager.sh logs
   ```

2. **Check system resources:**
   ```bash
   ./bot_manager.sh status
   ```

3. **Check if process is running:**
   ```bash
   ps aux | grep bot.py
   ```

### Virtual environment issues

If you need to recreate the virtual environment:

```bash
./bot_manager.sh stop
rm -rf venv
./bot_manager.sh start
```

### Permission denied

If you get "Permission denied" when running the script:

```bash
chmod +x bot_manager.sh
```

## Logs

- **bot.log** - Standard output and bot messages
- **bot_error.log** - Error messages and exceptions

View logs:
```bash
# View standard logs
tail -f bot.log

# View error logs
tail -f bot_error.log

# View both
tail -f bot.log bot_error.log
```

## Stopping the Bot

### Using the manager script (recommended)

```bash
./bot_manager.sh stop
```

### Manual stop

If you started the bot manually, find and kill the process:

```bash
# Find the process
ps aux | grep bot.py

# Kill by PID (replace XXXX with actual PID)
kill XXXX

# Or force kill
pkill -f bot.py
```

## Running on Server Startup

To automatically start the bot when the server boots, you can add it to cron or systemd.

### Using cron (simple)

Add to crontab:
```bash
crontab -e
```

Add this line (runs on reboot):
```
@reboot cd /path/to/wb_bot && ./bot_manager.sh start
```

### Using systemd (recommended for production)

Create a service file `/etc/systemd/system/wb-bot.service`:

```ini
[Unit]
Description=WB Telegram Bot
After=network.target

[Service]
Type=simple
User=your_username
WorkingDirectory=/path/to/wb_bot
ExecStart=/path/to/wb_bot/bot_manager.sh start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl enable wb-bot
sudo systemctl start wb-bot
sudo systemctl status wb-bot
```

## Security Notes

- **Never commit `config.py`** - It contains sensitive API tokens
- **Keep your tokens secret** - Don't share them publicly
- **Use strong passwords** - For your server and accounts
- **Regular updates** - Keep your system and dependencies updated

## Support

If you encounter issues:
1. Check the logs (`bot_error.log`)
2. Verify your API tokens are correct
3. Ensure Python 3.11 is installed
4. Check network connectivity

## License

This project is for personal use.

