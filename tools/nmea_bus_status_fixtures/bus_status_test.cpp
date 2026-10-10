#include <Nmea2000Twai.h>
#include <cstdio>
#include <cstring>
#include <deque>
#include <stdexcept>

uint32_t testMillis = 0;
TestSerial Serial;

namespace {
struct FakeDriver {
    esp_err_t installResult = ESP_OK, startResult = ESP_OK;
    esp_err_t statusResult = ESP_OK, transmitResult = ESP_OK;
    uint32_t installs = 0, starts = 0, uninstalls = 0;
    uint32_t statusReads = 0, receives = 0, transmits = 0;
    twai_status_info_t status{};
    twai_message_t lastTransmit{};
    std::deque<twai_message_t> queue;
} driver;

void require(bool value, const char* message) {
    if (!value) throw std::runtime_error(message);
}

void noController(const bs::BusStatus& status) {
    require(!status.running && !status.busOff && !status.recovering,
            "Unavailable controller has an active state");
    require(status.txErrors == 0 && status.rxErrors == 0 && status.txFailed == 0,
            "Unavailable controller exposes invalid counters");
}

void noReception(const bs::BusStatus& status) {
    require(!status.received && status.rxFrames == 0 && status.lastRxMs == 0,
            "Reception was invented without a valid extended data frame");
}

void open(bs::Nmea2000Twai& bus) {
    require(bus.openTest() && bus.driverReady(), "Healthy driver did not open");
    driver.status.state = TWAI_STATE_RUNNING;
}

void enqueue(uint32_t id = 0x18ff0001U, uint8_t length = 2,
             uint32_t flags = TWAI_MSG_FLAG_EXTD) {
    twai_message_t frame{};
    frame.identifier = id;
    frame.data_length_code = length;
    frame.flags = flags;
    frame.data[0] = 0x12;
    frame.data[1] = 0x34;
    driver.queue.push_back(frame);
}

void receive(bs::Nmea2000Twai& bus) {
    unsigned long id = 0;
    unsigned char length = 0, data[8]{};
    require(bus.getTest(id, length, data), "Valid receive callback failed");
}

void uninstalled(bs::Nmea2000Twai& bus) {
    const auto status = bus.busStatus();
    noController(status);
    noReception(status);
    unsigned long id = 0;
    unsigned char length = 0, data[8]{};
    require(!bus.getTest(id, length, data) && !bus.sendTest(1, 1, data),
            "Uninstalled driver accepted traffic");
    require(driver.statusReads == 0 && driver.installs == 0 && driver.starts == 0 &&
            driver.receives == 0 && driver.transmits == 0,
            "Uninstalled backend accessed or started the driver");
}

void installFailure(bs::Nmea2000Twai& bus) {
    driver.installResult = -1;
    require(!bus.openTest() && !bus.driverReady(), "Install failure was ignored");
    noController(bus.busStatus());
    noReception(bus.busStatus());
    require(driver.installs == 1 && driver.starts == 0 && driver.uninstalls == 0 &&
            driver.statusReads == 0, "Install failure entered a later driver stage");
}

void startFailure(bs::Nmea2000Twai& bus) {
    driver.startResult = -1;
    require(!bus.openTest() && !bus.driverReady(), "Start failure was ignored");
    noController(bus.busStatus());
    require(driver.installs == 1 && driver.starts == 1 && driver.uninstalls == 1 &&
            driver.statusReads == 0, "Start failure cleanup/status query is incorrect");
}

void states(bs::Nmea2000Twai& bus) {
    open(bus);
    require(bus.openTest(), "Repeated open failed");
    enqueue();
    for (auto state : {TWAI_STATE_STOPPED, TWAI_STATE_RUNNING,
                       TWAI_STATE_BUS_OFF, TWAI_STATE_RECOVERING}) {
        driver.status.state = state;
        const auto status = bus.busStatus();
        require(status.running == (state == TWAI_STATE_RUNNING), "Wrong running state");
        require(status.busOff == (state == TWAI_STATE_BUS_OFF), "Wrong bus-off state");
        require(status.recovering == (state == TWAI_STATE_RECOVERING), "Wrong recovery state");
        noReception(status);
    }
    require(driver.statusReads == 4, "Snapshot did not query current controller state");
    require(driver.installs == 1 && driver.starts == 1 && driver.uninstalls == 0 &&
            driver.transmits == 0 && driver.receives == 0 && driver.queue.size() == 1,
            "Read-only snapshots changed controller state or consumed traffic");
}

void counters(bs::Nmea2000Twai& bus) {
    open(bus);
    driver.status = {TWAI_STATE_RUNNING, 127, 128, 5678};
    const unsigned char data[] = {0x12, 0x34};
    driver.transmitResult = -1;
    require(!bus.sendTest(0x18ff0001U, 2, data), "Enqueue failure was ignored");
    require(bus.txFailures() == 1, "Enqueue failure counter did not advance");
    auto status = bus.busStatus();
    require(status.txErrors == 127 && status.rxErrors == 128 && status.txFailed == 5678,
            "Controller counters were replaced by enqueue failures or truncated");
    driver.transmitResult = ESP_OK;
    require(bus.sendTest(0x18ff0001U, 2, data, false), "Healthy send callback failed");
    require(driver.lastTransmit.identifier == 0x18ff0001U &&
            driver.lastTransmit.flags == TWAI_MSG_FLAG_EXTD &&
            driver.lastTransmit.data_length_code == 2 &&
            driver.lastTransmit.data[0] == 0x12 && driver.lastTransmit.data[1] == 0x34,
            "Send callback did not preserve the extended data frame");
    driver.status.tx_error_counter = 1;
    driver.status.rx_error_counter = 2;
    status = bus.busStatus();
    require(status.txErrors == 1 && status.rxErrors == 2 && status.txFailed == 5678,
            "Snapshot did not reflect decreasing live error counters");
    require(bus.txFailures() == 1, "Successful enqueue changed failure count");
    noReception(status);
}

void validReceive(bs::Nmea2000Twai& bus) {
    open(bus);
    enqueue();
    enqueue(0x18ff0002U, 0);
    noReception(bus.busStatus());
    require(driver.queue.size() == 2, "Status polling consumed queued traffic");
    unsigned long id = 0;
    unsigned char length = 0, data[8]{};
    testMillis = 100;
    require(bus.getTest(id, length, data), "Valid frame was rejected");
    require(id == 0x18ff0001U && length == 2 && data[0] == 0x12 && data[1] == 0x34,
            "Receive callback changed the frame payload");
    auto status = bus.busStatus();
    require(status.received && status.rxFrames == 1 && status.lastRxMs == 100,
            "First valid frame did not update receive history");
    testMillis = 200;
    require(bus.getTest(id, length, data) && length == 0,
            "Valid zero-length extended data frame was rejected");
    testMillis = 5201;
    require(!bus.getTest(id, length, data), "Empty queue invented a frame");
    status = bus.busStatus();
    require(status.received && status.rxFrames == 2 && status.lastRxMs == 200,
            "Empty queue or status polling refreshed stale receive history");
    require(uint32_t(testMillis - status.lastRxMs) == 5001,
            "Receive timestamp no longer supports caller freshness checks");
}

void malformed(bs::Nmea2000Twai& bus) {
    open(bus);
    unsigned long id = 0;
    unsigned char length = 0, data[8]{};
    enqueue(1, 2, 0); // Standard frame.
    enqueue(2, 2, TWAI_MSG_FLAG_EXTD | TWAI_MSG_FLAG_RTR);
    enqueue(3, 9); // Invalid classic CAN payload length.
    testMillis = 10;
    require(!bus.getTest(id, length, data), "Malformed-only queue reported reception");
    noReception(bus.busStatus());
    require(bus.rxDroppedFrames() == 3, "Invalid receive frames were not counted separately");
    enqueue(4, 2, 0);
    enqueue(0x18ff0001U);
    testMillis = 20;
    receive(bus);
    auto status = bus.busStatus();
    require(status.received && status.rxFrames == 1 && status.lastRxMs == 20 &&
            bus.rxDroppedFrames() == 4, "Invalid prefix hid or inflated valid reception");
    enqueue(5, 2, TWAI_MSG_FLAG_EXTD | TWAI_MSG_FLAG_RTR);
    testMillis = 1000;
    require(!bus.getTest(id, length, nullptr) && driver.queue.size() == 1,
            "Null caller buffer consumed traffic");
    require(!bus.getTest(id, length, data), "Remote frame reported valid reception");
    status = bus.busStatus();
    require(status.rxFrames == 1 && status.lastRxMs == 20,
            "Rejected frames refreshed previous reception");
}

void rollover(bs::Nmea2000Twai& bus) {
    open(bus);
    testMillis = 0xfffffff0U;
    enqueue();
    receive(bus);
    testMillis = 0x10;
    auto status = bus.busStatus();
    require(status.received && status.rxFrames == 1 && status.lastRxMs == 0xfffffff0U &&
            uint32_t(testMillis - status.lastRxMs) == 32, "Receive age broke across millis rollover");
    enqueue();
    receive(bus);
    status = bus.busStatus();
    require(status.received && status.rxFrames == 2 && status.lastRxMs == 0x10,
            "Post-rollover frame did not refresh reception");
}

void statusFailure(bs::Nmea2000Twai& bus) {
    open(bus);
    testMillis = 42;
    enqueue();
    receive(bus);
    driver.status = {TWAI_STATE_BUS_OFF, 256, 128, 99};
    driver.statusResult = -1;
    const auto status = bus.busStatus();
    noController(status);
    require(status.received && status.rxFrames == 1 && status.lastRxMs == 42,
            "Failed controller query lost valid receive history");
    require(driver.statusReads == 1 && driver.installs == 1 && driver.starts == 1 &&
            driver.uninstalls == 0 && driver.transmits == 0,
            "Failed status query attempted a controller mutation");
}
} // namespace

esp_err_t twai_driver_install(const twai_general_config_t*, const twai_timing_config_t*,
                             const twai_filter_config_t*) {
    ++driver.installs;
    return driver.installResult;
}
esp_err_t twai_start() { ++driver.starts; return driver.startResult; }
esp_err_t twai_driver_uninstall() { ++driver.uninstalls; return ESP_OK; }
esp_err_t twai_transmit(const twai_message_t* message, TickType_t) {
    ++driver.transmits;
    driver.lastTransmit = *message;
    return driver.transmitResult;
}
esp_err_t twai_receive(twai_message_t* message, TickType_t timeout) {
    require(timeout == 0, "Receive callback introduced a blocking wait");
    ++driver.receives;
    if (driver.queue.empty()) return -1;
    *message = driver.queue.front();
    driver.queue.pop_front();
    return ESP_OK;
}
esp_err_t twai_get_status_info(twai_status_info_t* status) {
    ++driver.statusReads;
    // Write fields even on failure: production must reject them with the error.
    *status = driver.status;
    return driver.statusResult;
}

int main(int argc, char** argv) {
    try {
        require(argc == 2, "Expected scenario");
        struct Scenario { const char* name; void (*run)(bs::Nmea2000Twai&); };
        const Scenario scenarios[] = {
            {"uninstalled", uninstalled}, {"install-failure", installFailure},
            {"start-failure", startFailure}, {"states", states}, {"counters", counters},
            {"receive", validReceive}, {"malformed", malformed}, {"rollover", rollover},
            {"status-failure", statusFailure}
        };
        for (const auto& scenario : scenarios) {
            if (std::strcmp(argv[1], scenario.name) != 0) continue;
            bs::Nmea2000Twai bus(4, 7);
            scenario.run(bus);
            std::printf("PASS %s\n", scenario.name);
            return 0;
        }
        throw std::runtime_error("Unknown scenario");
    } catch (const std::exception& error) {
        std::fprintf(stderr, "%s: %s\n", argc > 1 ? argv[1] : "test", error.what());
        return 1;
    }
}
