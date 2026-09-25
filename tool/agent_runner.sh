#!/bin/bash
# Lets Claude trigger a few fixed jobs while you're away:
#   touch .agent/run      -> (re)start the app in the simulator (screenshot mode), log: .agent/run.log
#                            device = content of .agent/device (name or UDID) if present, else $PIXI_DEVICE
#   touch .agent/upload   -> cd ios && fastlane beta,                               log: .agent/upload.log
#   touch .agent/devices  -> xcrun simctl list devices available,                  log: .agent/devices.log
# Nothing else is executed. Stop with Ctrl+C.
cd "$(dirname "$0")/.." || exit 1
mkdir -p .agent
DEFAULT_DEVICE="${PIXI_DEVICE:-76B6E205-101D-4C88-8CC7-DA6796D891E1}"
RUN_PID=""
echo "Pixi agent runner ready ($(pwd)). Waiting for .agent/run, .agent/upload or .agent/devices ..."
while true; do
  if [ -f .agent/devices ]; then
    rm -f .agent/devices
    xcrun simctl list devices available > .agent/devices.log 2>&1
    echo "$(date '+%H:%M:%S') simulator list written"
  fi
  if [ -f .agent/run ]; then
    rm -f .agent/run
    DEVICE="$DEFAULT_DEVICE"
    [ -s .agent/device ] && DEVICE="$(head -n1 .agent/device | tr -d '\r\n')"
    [ -n "$RUN_PID" ] && kill "$RUN_PID" 2>/dev/null && sleep 2
    # boot the simulator if it is not running yet (works with name or UDID)
    xcrun simctl boot "$DEVICE" >/dev/null 2>&1
    open -a Simulator >/dev/null 2>&1
    echo "$(date '+%H:%M:%S') starting flutter run on '$DEVICE'"
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
