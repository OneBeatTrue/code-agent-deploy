#!/bin/bash
set -e

LOGFILE="/var/log/deploy.log"
PROJECT_DIR="/root/code-agent-global/code-agent"

echo "----- Deploy started at $(date) -----" >> "$LOGFILE" 2>&1

cd "$PROJECT_DIR" || {
  echo "Failed to cd to project dir" >> "$LOGFILE"
  exit 1
}

echo "Git status:" >> "$LOGFILE"
git status >> "$LOGFILE" 2>&1

echo "Git pull..." >> "$LOGFILE"
git pull origin main >> "$LOGFILE" 2>&1

echo "Docker compose down" >> "$LOGFILE"
docker compose down >> "$LOGFILE" 2>&1

echo "Docker compose up --build" >> "$LOGFILE"
docker compose up -d --build >> "$LOGFILE" 2>&1

echo "Docker compose ps" >> "$LOGFILE"
docker compose ps >> "$LOGFILE" 2>&1

echo "----- Deploy finished at $(date) -----" >> "$LOGFILE" 2>&1
