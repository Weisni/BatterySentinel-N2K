#pragma once

#include <Arduino.h>
#include <NMEA2000.h>
#include <driver/gpio.h>
#include <driver/twai.h>

namespace bs {

// Minimal NMEA2000 hardware backend for ESP32-C3's native TWAI controller.
// The external ISO1042 provides the physical CAN transceiver/isolation;
// this class only owns the ESP32-C3 controller and its FreeRTOS queues.
class Nmea2000Twai final : public tNMEA2000 {
public:
    Nmea2000Twai(gpio_num_t txPin, gpio_num_t rxPin);

    bool driverReady() const { return driverReady_; }
    uint32_t txFailures() const { return txFailures_; }
    uint32_t rxDroppedFrames() const { return rxDroppedFrames_; }

protected:
    bool CANSendFrame(unsigned long id,
                      unsigned char len,
                      const unsigned char* buf,
                      bool waitSent = true) override;
    bool CANOpen() override;
    bool CANGetFrame(unsigned long& id,
                     unsigned char& len,
                     unsigned char* buf) override;

private:
    gpio_num_t txPin_;
    gpio_num_t rxPin_;
    bool driverReady_ = false;
    uint32_t txFailures_ = 0;
    uint32_t rxDroppedFrames_ = 0;
};

} // namespace bs
