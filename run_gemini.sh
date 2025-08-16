#!/bin/bash
if [ ! -f prompt.txt ]; then
  echo "Error: prompt.txt not found!"
  exit 1
fi

# Run Gemini CLI with the contents of prompt.txt
gemini --prompt "$(cat prompt.txt)"
