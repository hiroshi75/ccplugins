#!/bin/bash
# stop-worker.sh - 作業用 claude を終了
#
# 使用例:
#   ./stop-worker.sh recommendation-api

set -e

TASK_NAME="${1:?タスク名を指定してください}"

echo "作業用 claude を終了します: ${TASK_NAME}"
tmux send-keys -t "${TASK_NAME}" C-c C-c

echo "終了コマンドを送信しました"
