#include "NmeaPublisher.h"

#include <algorithm>
#include <cmath>

#include <N2kMessages.h>

#include "Nmea2000Twai.h"
#include "config.h"

namespace bs {

namespace {
Nmea2000Twai nmeaBus(static_cast<gpio_num_t>(config::PIN_CAN_TX),
                     static_cast<gpio_num_t>(config::PIN_CAN_RX));
const unsigned long kTransmitMessages[] PROGMEM = {127506L, 127508L, 0};
}

void NmeaPublisher::begin(uint32_t uniqueNumber) {
    char serial[16];
    snprintf(serial, sizeof(serial), "%08lX", static_cast<unsigned long>(uniqueNumber));

    nmeaBus.SetProductInformation(
        serial,
        100,
        "BatterySentinel N2K",
        "0.1.0",
        "V1"
    );

    // Function 170 = Battery; class 35 = Electrical Generation.
    // Manufacturer code 2046 is deliberately used as a DIY/unregistered placeholder.
    nmeaBus.SetDeviceInformation(uniqueNumber & 0x1FFFFFu, 170, 35, 2046);
    nmeaBus.ExtendTransmitMessages(kTransmitMessages);
    nmeaBus.SetMode(tNMEA2000::N2km_NodeOnly, 25);
    nmeaBus.EnableForward(false);
    nmeaBus.Open();
}

void NmeaPublisher::process() {
    nmeaBus.ParseMessages();
}

void NmeaPublisher::publishFast(uint8_t batteryInstance,
                                const BatterySnapshot& state,
                                bool measurementValid) {
    tN2kMsg msg;
    const double voltage = measurementValid ? state.voltageV : N2kDoubleNA;
    const double current = measurementValid ? state.currentA : N2kDoubleNA;

    SetN2kDCBatStatus(msg, batteryInstance, voltage, current, N2kDoubleNA, sid_++);
    nmeaBus.SendMsg(msg);
}

void NmeaPublisher::publishDc(uint8_t batteryInstance,
                              const BatterySnapshot& state,
                              bool measurementValid) {
    if (!measurementValid || !state.socInitialized) return;

    tN2kMsg msg;
    const uint8_t soc = static_cast<uint8_t>(std::lround(std::max(0.0, std::min(100.0, state.socPct))));
    const double timeRemaining = state.timeRemainingS >= 0.0 ? state.timeRemainingS : N2kDoubleNA;

    SetN2kDCStatus(msg,
                   sid_++,
                   batteryInstance,
                   N2kDCt_Battery,
                   soc,
                   N2kUInt8NA,
                   timeRemaining,
                   N2kDoubleNA);
    nmeaBus.SendMsg(msg);
}

} // namespace bs
