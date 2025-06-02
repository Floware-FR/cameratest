#include <gst/gst.h>
#include <iostream>
#include <thread>
#include <chrono>
#include <cstdlib>
#include <cstdio>
#include <string>

class CameraControl {
public:
    CameraControl(const std::string& device = "/dev/video2") : device(device), pipeline(nullptr) {
        gst_init(nullptr, nullptr);

        std::string pipeline_str = 
            "v4l2src name=src device=" + device +
            " ! image/jpeg, width=2592, height=1944, framerate=30/1 "
            "! jpegdec ! autovideosink";

        GError* error = nullptr;
        pipeline = gst_parse_launch(pipeline_str.c_str(), &error);
        if (!pipeline) {
            std::cerr << "Failed to create pipeline: " << error->message << std::endl;
            g_error_free(error);
        }
    }

    void set_exposure(int value) {
        std::cout << "Setting manual exposure to: " << value << std::endl;
        std::string cmd1 = "v4l2-ctl -d " + device + " -c auto_exposure=1";
        std::string cmd2 = "v4l2-ctl -d " + device + " -c exposure_time_absolute=" + std::to_string(value);
        system(cmd1.c_str());
        system(cmd2.c_str());
    }

    int get_exposure() {
        std::string cmd = "v4l2-ctl -d " + device + " -C exposure_time_absolute";
        FILE* pipe = popen(cmd.c_str(), "r");
        if (!pipe) return -1;

        char buffer[128];
        std::string result;
        while (fgets(buffer, sizeof buffer, pipe) != nullptr) {
            result += buffer;
        }
        pclose(pipe);

        size_t colon = result.find(":");
        if (colon != std::string::npos) {
            return std::stoi(result.substr(colon + 1));
        }
        return -1;
    }

    void set_brightness(float value) {
        int brightness = static_cast<int>(value);
        std::string cmd = "v4l2-ctl -d " + device + " -c brightness=" + std::to_string(brightness);
        system(cmd.c_str());
    }

    int get_brightness() {
        std::string cmd = "v4l2-ctl -d " + device + " -C brightness";
        FILE* pipe = popen(cmd.c_str(), "r");
        if (!pipe) return -1;

        char buffer[128];
        std::string result;
        while (fgets(buffer, sizeof buffer, pipe) != nullptr) {
            result += buffer;
        }
        pclose(pipe);

        size_t colon = result.find(":");
        if (colon != std::string::npos) {
            return std::stoi(result.substr(colon + 1));
        }
        return -1;
    }

    void start() {
        std::cout << "Starting pipeline..." << std::endl;
        gst_element_set_state(pipeline, GST_STATE_PLAYING);
    }

    void stop() {
        std::cout << "Stopping pipeline..." << std::endl;
        gst_element_set_state(pipeline, GST_STATE_NULL);
        gst_object_unref(pipeline);
    }

private:
    std::string device;
    GstElement* pipeline;
};

int main() {
    CameraControl cam;
    cam.start();

    std::this_thread::sleep_for(std::chrono::seconds(2));

    cam.set_exposure(900);
    std::cout << "Exposure set to: " << cam.get_exposure() << std::endl;

    cam.set_brightness(-60);
    std::cout << "Brightness set to: " << cam.get_brightness() << std::endl;

    std::cout << "Press Enter to stop..." << std::endl;
    std::cin.get();

    cam.stop();
    return 0;
}