import gi
import subprocess
import time

# Initialize GStreamer
gi.require_version('Gst', '1.0')
from gi.repository import Gst, GObject

Gst.init(None)

class CameraControl:
       
    def __init__(self, device='/dev/video2'):
     # Build the GStreamer pipeline
        self.device = device
        self.pipeline = Gst.parse_launch(
            f"v4l2src name=src device={self.device} ! image/jpeg, width=2592, height=1944, framerate=30/1 ! jpegdec ! autovideosink"
        )
        self.src = self.pipeline.get_by_name("src")

    def set_exposure(self, exposure_value):
        if self.src is not None:
            print(f"Setting manual exposure and value: {exposure_value}")
            subprocess.run(['v4l2-ctl', '-d', self.device, '-c', 'auto_exposure=1'], check=True) # Enable manual exposure
            subprocess.run(['v4l2-ctl', '-d', self.device, '-c', f'exposure_time_absolute={exposure_value}'], check=True) # Set exposure value

    def get_exposure(self):
        if self.src is not None:
            result = subprocess.run(['v4l2-ctl', '-d', self.device, '-C', 'exposure_time_absolute'],
                                    capture_output=True, text=True) # Get current exposure value
            # Check if the command was successful and parse the output
            if result.returncode == 0 and result.stdout:
                try:
                    return int(result.stdout.strip().split(":")[1]) # Extract the value after the colon
                except (IndexError, ValueError):
                    return None
        return None

    def set_brightness(self, brightness_value):
        if self.src is not None:
            subprocess.run(['v4l2-ctl', '-d', self.device, '-c', f'brightness={int(brightness_value)}'], check=True)    # Set brightness value

    def get_brightness(self):
        if self.src is not None:
            result = subprocess.run(['v4l2-ctl', '-d', self.device, '-C', 'brightness'],
                                    capture_output=True, text=True) # Get current brightness value
            if result.returncode == 0 and result.stdout:
                try:
                    return int(result.stdout.strip().split(":")[1]) # Extract the value after the colon
                except (IndexError, ValueError):
                    return None
        return None

    def start(self):
        print("Starting pipeline...")
        self.pipeline.set_state(Gst.State.PLAYING)

    def stop(self):
        print("Stopping pipeline...")
        self.pipeline.set_state(Gst.State.NULL)

if __name__ == "__main__":
    cam = CameraControl()
    cam.start()

    time.sleep(2)

    # Set and get exposure
    cam.set_exposure(1000)
    print("Exposure set to:", cam.get_exposure())

    # Set and get brightness
    cam.set_brightness(0.5)
    print("Brightness set to:", cam.get_brightness())

    input("Press Enter to stop...")
    cam.stop()