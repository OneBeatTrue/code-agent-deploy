#!/bin/bash
set -e

LOGFILE="/var/log/deploy.log"

echo "----- Deploy started at $(date) -----" >> $LOGFILE 2>&1

cd /root/code-agent-global/code-agent || { echo "Failed to cd to repo" >> $LOGFILE; exit 1; }

echo "Current git status:" >> $LOGFILE
git status >> $LOGFILE 2>&1

echo "Trying git pull..." >> $LOGFILE
git pull origin main >> $LOGFILE 2>&1 || { echo "git pull failed" >> $LOGFILE; exit 1; }

echo "Git pull succeeded" >> $LOGFILE

git pull origin main

docker build --build-arg WEBHOOK_SECRET=$WEBHOOK_SECRET -t code-agent-container:latest .

docker stop code-agent-container || true
docker rm code-agent-container || true

docker run -d -p 8080:8080 -v $(pwd)/logs:/logs --name code-agent-container -e WEBHOOK_SECRET=$WEBHOOK_SECRET code-agent-container:latest

echo "----- Deploy finished at $(date) -----" >> $LOGFILE 2>&1
