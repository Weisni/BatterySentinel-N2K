#include "OrionBleReceiver.h"

#include <BLEDevice.h>
#include <mbedtls/aes.h>
#include <cstring>

namespace bs {

bool OrionBleReceiver::begin(const String& mac, const uint8_t key[16]) {
    if (mac.length() != 17 || !key) {
        lastProblem_ = "Invalid BLE settings";
        ++startupFailures_;
        return false;
    }
    mac_ = mac;
    mac_.toLowerCase();
    std::memcpy(key_, key, sizeof(key_));
    queue_ = xQueueCreate(8, sizeof(Frame));
    if (!queue_) {
        lastProblem_ = "BLE queue allocation failed";
        ++startupFailures_;
        return false;
    }
    BLEDevice::init("");
    scan_ = BLEDevice::getScan();
    scan_->setAdvertisedDeviceCallbacks(this, true);
    scan_->setActiveScan(false);
    scan_->setInterval(160);
    scan_->setWindow(120);
    ready_ = scan_->start(0, nullptr, false);
    if (!ready_) {
        lastProblem_ = "BLE scan failed";
        ++startupFailures_;
    }
    return ready_;
}

void OrionBleReceiver::onResult(BLEAdvertisedDevice device) {
    if (!ready_ || !device.haveManufacturerData()) return;
    String address(device.getAddress().toString().c_str());
    address.toLowerCase();
    if (address != mac_) return;
    const std::string data = device.getManufacturerData();
    if (data.size() < 24 || data.size() > sizeof(Frame::bytes)) return;
    Frame frame;
    frame.length = static_cast<uint8_t>(data.size());
    std::memcpy(frame.bytes, data.data(), data.size());
    frame.atMs = millis();
    frame.rssi = static_cast<int16_t>(device.getRSSI());
    if (xQueueSend(queue_, &frame, 0) != pdTRUE) ++droppedFrames_;
}

bool OrionBleReceiver::poll(orion::Telemetry& telemetry) {
    if (!ready_) return false;
    Frame frame;
    bool accepted = false;
    while (xQueueReceive(queue_, &frame, 0) == pdTRUE) {
        switch (decode(frame, telemetry)) {
        case DecodeResult::Accepted: accepted = true; break;
        case DecodeResult::Duplicate: ++duplicateFrames_; break;
        case DecodeResult::Rejected: ++rejectedFrames_; break;
        }
    }
    return accepted;
}

orion::Telemetry OrionBleReceiver::snapshot(const orion::Telemetry& telemetry) const {
    portENTER_CRITICAL(&telemetryMux_);
    const orion::Telemetry result = telemetry;
    portEXIT_CRITICAL(&telemetryMux_);
    return result;
}

OrionBleReceiver::DecodeResult OrionBleReceiver::decode(const Frame& frame,
                                                        orion::Telemetry& telemetry) {
    const uint8_t* b = frame.bytes;
    // Arduino BLE includes the two-byte Bluetooth company identifier.
    if (b[0] != 0xe1 || b[1] != 0x02 || b[2] != 0x10 ||
        orion::little16(b + 4) != 0xa3f1 || b[6] != 0x0f) {
        lastProblem_ = "Unsupported advertisement";
        return DecodeResult::Rejected;
    }
    if (b[9] != key_[0]) {
        lastProblem_ = "Encryption key mismatch";
        return DecodeResult::Rejected;
    }
    const uint16_t counter = orion::little16(b + 7);
    if (haveCounter_ && counter == lastCounter_) return DecodeResult::Duplicate;
    const size_t encryptedLength = frame.length - 10;
    if (encryptedLength < 14 || encryptedLength > 22) {
        lastProblem_ = "Truncated or oversized record";
        return DecodeResult::Rejected;
    }

    uint8_t plaintext[22]{};
    uint8_t nonceCounter[16]{};
    uint8_t streamBlock[16]{};
    nonceCounter[0] = b[7];
    nonceCounter[1] = b[8];
    size_t offset = 0;
    mbedtls_aes_context aes;
    mbedtls_aes_init(&aes);
    const int keyResult = mbedtls_aes_setkey_enc(&aes, key_, 128);
    const int cryptResult = keyResult == 0 ?
        mbedtls_aes_crypt_ctr(&aes, encryptedLength, &offset, nonceCounter,
                              streamBlock, b + 10, plaintext) : keyResult;
    mbedtls_aes_free(&aes);
    if (cryptResult != 0) {
        lastProblem_ = "AES decode failed";
        return DecodeResult::Rejected;
    }

    orion::Telemetry candidate;
    if (!orion::decodeXsRecord(plaintext, encryptedLength, candidate)) {
        lastProblem_ = "Record decode failed";
        return DecodeResult::Rejected;
    }
    // CTR does not authenticate the packet. Basic bounds prevent a wrong key
    // from becoming a plausible measurement, but a real device comparison is
    // still required before use on a live vessel.
    const auto plausibleVoltage = [](const orion::Value& v) {
        return !v.valid || (v.number >= 0.0 && v.number <= 65.0);
    };
    const auto plausibleCurrent = [](const orion::Value& v) {
        return !v.valid || (v.number >= -2.0 && v.number <= 150.0);
    };
    if (!plausibleVoltage(candidate.inputVoltage) ||
        !plausibleVoltage(candidate.outputVoltage) ||
        !plausibleCurrent(candidate.inputCurrent) ||
        !plausibleCurrent(candidate.outputCurrent)) {
        lastProblem_ = "Implausible decoded values";
        return DecodeResult::Rejected;
    }
    candidate.counter = counter;
    candidate.receivedAtMs = frame.atMs;
    candidate.rssi = frame.rssi;
    candidate.received = true;
    portENTER_CRITICAL(&telemetryMux_);
    telemetry = candidate;
    portEXIT_CRITICAL(&telemetryMux_);
    lastCounter_ = counter;
    haveCounter_ = true;
    lastProblem_ = "Receiving";
    ++receivedFrames_;
    return DecodeResult::Accepted;
}

} // namespace bs
