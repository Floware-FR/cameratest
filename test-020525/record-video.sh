#!/bin/bash

# Directory to save recordings
SAVE_DIR="recordings"
mkdir -p "$SAVE_DIR"

# Duration of each segment (in seconds) — 30 minutes
#SEGMENT_DURATION=$((60 * 45)) 
SEGMENT_DURATION=900 #15 minutes
SEGMENT_PAUSE=2700 #45 minutes

# Total recording time: 24 hours in seconds
#TOTAL_DURATION=$((60 * 60 * 24))  
TOTAL_DURATION=86400 #24 hours 
ELAPSED=0

# Start loop
while [ $ELAPSED -lt $TOTAL_DURATION ]; do
    # Timestamp for filename
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

    # Output file path
    OUT="$SAVE_DIR/cam2_$TIMESTAMP.mp4"

    echo "[$(date)] Recording 15-minute segment..."

    # Start recording from /dev/video0
    gst-launch-1.0 -e v4l2src device=/dev/video0 ! image/jpeg, width=2592, height=1944, framerate=30/1 ! jpegdec ! x264enc tune=zerolatency bitrate=5000 speed-preset=superfast ! mp4mux ! filesink location="$OUT" &
    
    #echo "video saved at $OUT"
    
    # Wait for 1 minutes
    sleep $SEGMENT_DURATION

    # Stop the recording process
    pkill -INT gst-launch-1.0

    # Allow time for shutdown
    sleep 2
    
    sleep $SEGMENT_PAUSE
    
    # Update elapsed time
    ELAPSED=$((ELAPSED + SEGMENT_DURATION))
done

echo "Finished 24-hour single-camera recording session."
