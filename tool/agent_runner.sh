#!/bin/bash
# Lets Claude trigger two fixed jobs while you're away:
#   touch .agent/run     -> (re)start the app in the simulator (screenshot mode), log: .agent/run.log
#   touch .agent/upload  -> cd ios && fastlane beta,                               log: .agent/upload.log
# Nothing else is executed. Stop with Ctrl+C.
cd "$(dirname "$0")/.." || exit 1
mkdir -p .agent
DEVICE="${PIXI_DEVICE:-76B6E205-101D-4C88-8CC7-DA6796D891E1}"
RUN_PID=""
echo "Pixi agent runner ready ($(pwd)). Waiting for .agent/run or .agent/upload ..."
while true; do
  if [ -f .agent/run ]; then
    rm -f .agent/run
    [ -n "$RUN_PID" ] && kill "$RUN_PID" 2>/dev/null && sleep 2
    echo "$(date '+%H:%M:%S') starting flutter run"
    flutter run -d "$DEVICE" --dart-define=SCREENSHOT=true > .agent/run.log 2>&1 < /dev/null &
    RUN_PID=$!
  fi
  if [ -f .agent/upload ]; then
    rm -f .agent/upload
    echo "$(date '+%H:%M:%S') starting fastlane beta"
    ( cd ios && fastlane beta ) > .agent/upload.log 2>&1 < /dev/null
    echo "EXIT=$?" >> .agent/upload.log
    echo "$(date '+%H:%M:%S') fastlane done"
  fi
  sleep 5
done
