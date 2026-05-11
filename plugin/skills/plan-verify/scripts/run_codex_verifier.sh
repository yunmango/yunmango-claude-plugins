#!/usr/bin/env bash
# Plan-Verify Codex Verifier Runner
# This script runs the Codex CLI with fixed model, reasoning effort, and fast mode.
# The subagent MUST call this script as-is — do NOT modify the model or flags.

set -euo pipefail

# --- Fixed Configuration (DO NOT MODIFY) ---
# Verified: `model_reasoning_effort` is a valid codex config key
# (see ~/.codex/config.toml schema, confirmed with codex-cli v0.116.0)
# `--enable fast_mode` toggles the fast_mode feature (equivalent to `-c features.fast_mode=true`).
MODEL="gpt-5.5"
REASONING_EFFORT="xhigh"
SANDBOX="read-only"
# -------------------------------------------

PROMPT_FILE="${1:?Usage: $0 <prompt_file> <output_file> [project_root]}"
OUTPUT_FILE="${2:?Usage: $0 <prompt_file> <output_file> [project_root]}"
PROJECT_ROOT="${3:-$(pwd)}"

STDERR_LOG="${OUTPUT_FILE%.md}.stderr.log"

cd "$PROJECT_ROOT"

echo "[codex-verifier] Model: $MODEL, Reasoning: $REASONING_EFFORT, Sandbox: $SANDBOX, Fast mode: on"
echo "[codex-verifier] Prompt: $PROMPT_FILE"
echo "[codex-verifier] Output: $OUTPUT_FILE"
echo "[codex-verifier] Project: $PROJECT_ROOT"

codex exec \
  -s "$SANDBOX" \
  -m "$MODEL" \
  -c "model_reasoning_effort=\"$REASONING_EFFORT\"" \
  --enable fast_mode \
  "$(cat "$PROMPT_FILE")" \
  -o "$OUTPUT_FILE" \
  2>"$STDERR_LOG"

EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ] || [ ! -s "$OUTPUT_FILE" ]; then
  echo "[codex-verifier] ERROR: Codex exited with code $EXIT_CODE" >&2
  echo "[codex-verifier] Stderr:" >&2
  cat "$STDERR_LOG" >&2
  exit 1
fi

echo "[codex-verifier] Success. Output written to $OUTPUT_FILE"
