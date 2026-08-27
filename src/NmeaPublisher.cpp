#include "NmeaPublisher.h"

#include <cmath>

#define ESP32_CAN_TX_PIN GPIO_NUM_6
#define ESP32_CAN_RX_PIN GPIO_NUM_7
#include <NMEA2000_CAN.h>
#include <N2kMessages.h>

namespace bs {

namespace {
const unsigned long kTransmitMessages[] PROGMEM = {127506L, 127508L, 0};

double clampSoc(double value) {
    if (value < 0.0) return 0.0;
    if (value > 100.0) return 100.0;
    return value;
}
}

void NmeaPublisher::begin(uint32_t uniqueNumber) {
    char serial[16];
    snprintf(serial, sizeof(serial), "%08lX", static_cast<unsigned long>(uniqueNumber));

    NMEA2000.SetProductInformation(
        serial,
        100,
        "BatterySentinel N2K",
        "0.1.0",
        "V1"
    );

    // Function 170 = Battery; class 35 = Electrical Generation.
    // Manufacturer code 2046 is deliberately used as a DIY/unregistered placeholder.
    NMEA2000.SetDeviceInformation(uniqueNumber & 0x1FFFFFu, 170, 35, 2046);
    NMEA2000.ExtendTransmitMessages(kTransmitMessages);
    NMEA2000.SetMode(tNMEA2000::N2km_NodeOnly, 25);
    NMEA2000.EnableForward(false);
    NMEA2000.Open();
}

void NmeaPublisher::process() {
    NMEA2000.ParseMessages();
}

void NmeaPublisher::publishFast(uint8_t batteryInstance,
                                const BatterySnapshot& state,
                                bool measurementValid) {
    tN2kMsg msg;
    const double voltage = measurementValid ? state.voltageV : N2kDoubleNA;
    const double current = measurementValid ? state.currentA : N2kDoubleNA;

    // No battery temperature sensor in V1, therefore temperature is NA.
    SetN2kDCBatStatus(msg, batteryInstance, voltage, current, N2kDoubleNA, sid_++);
    NMEA2000.SendMsg(msg);
}

void NmeaPublisher::publishDc(uint8_t batteryInstance,
                              const BatterySnapshot& state,
                              bool measurementValid) {
    if (!measurementValid || !state.socInitialized) return;

    tN2kMsg msg;
    const uint8_t soc = static_cast<uint8_t>(std::lround(clampSoc(state.socPct)));
    const double timeRemaining = state.timeRemainingS >= 0.0 ? state.timeRemainingS : N2kDoubleNA;

    // SOH and ripple voltage are not measured in V1 and are encoded as Not Available.
    SetN2kDCStatus(msg,
                   sid_++,
                   batteryInstance,
                   N2kDCt_Battery,
                   soc,
                   N2kUInt8NA,
                   timeRemaining,
                   N2kDoubleNA);
    NMEA2000.SendMsg(msg);
}

} // namespace bs
