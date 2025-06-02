#!/bin/bash

# Directory to save recordings
SAVE_DIR="$HOME/FLOWARE/camera-test/test-020525/recordings"
mkdir -p "$SAVE_DIR"

# Duration of each segment (in seconds) — 30 minutes
#SEGMENT_DURATION=$((30 * 60))
SEGMENT_DURATION=30 

# Total recording time: 8 hours in seconds
TOTAL_DURATION=300
ELAPSED=0

# Start loop
while [ $ELAPSED -lt $TOTAL_DURATION ]; do
    # Timestamp for filenames
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

    # Output file paths
    OUT1="$SAVE_DIR/cam2_$TIMESTAMP.mp4"
    OUT2="$SAVE_DIR/cam4_$TIMESTAMP.mp4"

    echo "[$(date)] Recording 30-minute segment..."

    # Start both recordings in background
    gst-launch-1.0 -e \
      v4l2src device=/dev/video2 ! image/jpeg, width=2592, height=1944, framerate=30/1 ! jpegdec ! x264enc tune=zerolatency bitrate=5000 speed-preset=superfast ! mp4mux ! filesink location="$OUT1" &

    gst-launch-1.0 -e \
      v4l2src device=/dev/video4 ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegdec ! x264enc tune=zerolatency bitrate=5000 speed-preset=superfast ! mp4mux ! filesink location="$OUT2" &

    # Wait for 30 minutes
    sleep $SEGMENT_DURATION

    # Stop all gst-launch-1.0 processes
    pkill -INT gst-launch-1.0

    # Wait for graceful shutdown
    sleep 2

    # Update elapsed time
    ELAPSED=$((ELAPSED + SEGMENT_DURATION))
done

echo "✅ Finished 5-minute test recording."
