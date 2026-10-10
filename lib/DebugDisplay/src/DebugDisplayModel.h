#pragma once
#include <cmath>
#include <cstdio>
#include <cstdint>

namespace bs::debugdisplay
{
    struct Value
    {
        double number = 0;
        bool valid = false;
    };
    struct Channel
    {
        Value voltage, current;
    };
    enum class TimeQuality : uint8_t
    {
        Unknown,
        Synchronized,
        Holdover,
        Quarantined
    };
    struct Snapshot
    {
        uint32_t nowMs = 0;
        uint64_t uptimeMs = 0;
        bool serviceReady = false;
        // canReceived/lastReceivedMs concern a valid extended CAN data frame,
        // never successful queue submission. N+ does not prove Garmin delivery.
        bool canRunning = false, canBusOff = false, canRecovering = false, canReceived = false;
        uint32_t canLastReceivedMs = 0, canTxErrorCount = 0, canRxErrorCount = 0;
        uint64_t canReceivedFrames = 0, canTxFailures = 0;
        bool orionConfigured = false, orionReceived = false;
        uint32_t orionReceivedAtMs = 0;
        int16_t orionRssi = 0;
        uint64_t orionAccepted = 0, orionErrors = 0;
        Channel input, output;
        TimeQuality timeQuality = TimeQuality::Unknown;
        bool utcValid = false;
        uint64_t utcMs = 0, timeAgeMs = 0;
        uint32_t heapFree = 0, heapMinimum = 0, wifiClients = 0, httpsClients = 0;
        uint32_t activeAlerts = 0, unacknowledgedAlerts = 0;
        uint8_t chargerState = 255, chargerError = 255;
        bool notificationsEnabled = false;
    };
    struct Frame
    {
        char status[13]{};
        char rows[3][13]{};
    };
    class Pager
    {
    public:
        // The caller sends the complete Frame on every true result. The first call
        // always renders page zero. A late call advances once, without a catch-up
        // burst. Unsigned subtraction also handles the uint32_t millis rollover.
        bool due(uint32_t now)
        {
            if (!started_)
            {
                started_ = true;
                lastPageMs_ = now;
                return true;
            }
            if (uint32_t(now - lastPageMs_) < 2000)
                return false;
            lastPageMs_ = now;
            page_ = uint8_t((page_ + 1) % 7);
            return true;
        }
        uint8_t page() const { return page_; }
        void render(const Snapshot &s, Frame &frame) const
        {
            frame = Frame{};
            const bool fresh = s.orionConfigured && s.orionReceived &&
                               uint32_t(s.nowMs - s.orionReceivedAtMs) <= 10000;
            const char can = s.canBusOff || s.canRecovering || s.canTxErrorCount >= 128 ||
                                     s.canRxErrorCount >= 128
                                 ? '!'
                             : !s.canRunning                                                    ? '-'
                             : s.canReceived && uint32_t(s.nowMs - s.canLastReceivedMs) <= 5000 ? '+'
                                                                                                : '?';
            const char orion = !s.orionConfigured ? '-' : fresh ? '+'
                                                                : '?';
            const char time = s.timeQuality == TimeQuality::Synchronized ? '+' : s.timeQuality == TimeQuality::Holdover  ? '~'
                                                                             : s.timeQuality == TimeQuality::Quarantined ? '!'
                                                                                                                         : '-';
            line(frame.status, "W%c N%c O%c T%c", s.serviceReady ? '+' : '-', can, orion, time);
            switch (page_)
            {
            case 0:
                channel(s.input, "IN", fresh, frame);
                break;
            case 1:
                channel(s.output, "OUT", fresh, frame);
                break;
            case 2:
                if (fresh && s.orionRssi >= -127 && s.orionRssi <= 0)
                    line(frame.rows[0], "BLE %ddBm", int(s.orionRssi));
                else
                    line(frame.rows[0], "BLE --dBm");
                if (s.orionConfigured && s.orionReceived)
                    line(frame.rows[1], "Age %ss", count(uint32_t(s.nowMs - s.orionReceivedAtMs) / 1000, 999999).text);
                else
                    line(frame.rows[1], "Age --");
                line(frame.rows[2], "R%s E%s", count(s.orionAccepted, 999).text, count(s.orionErrors, 999).text);
                break;
            case 3:
                line(frame.rows[0], "RX %s", count(s.canReceivedFrames, 999999).text);
                line(frame.rows[1], "TXF %s", count(s.canTxFailures, 999999).text);
                line(frame.rows[2], "E%s/%s", count(s.canTxErrorCount, 999).text, count(s.canRxErrorCount, 999).text);
                break;
            case 4:
                if (s.utcValid && s.timeQuality != TimeQuality::Unknown && s.utcMs < 4133980800000ULL)
                {
                    const uint32_t seconds = uint32_t((s.utcMs / 1000) % 86400);
                    line(frame.rows[0], "UTC %02u:%02u:%02u", unsigned(seconds / 3600),
                         unsigned(seconds / 60 % 60), unsigned(seconds % 60));
                }
                else
                    line(frame.rows[0], "UTC --:--:--");
                line(frame.rows[1], "Up %ss", count(s.uptimeMs / 1000, 999999).text);
                if (s.utcValid && s.timeQuality != TimeQuality::Unknown)
                    line(frame.rows[2], "T age %ss", count(s.timeAgeMs / 1000, 9999).text);
                else
                    line(frame.rows[2], "T age --");
                break;
            case 5:
                line(frame.rows[0], "Heap %sKiB", count(s.heapFree / 1024, 999).text);
                line(frame.rows[1], "Min %sKiB", count(s.heapMinimum / 1024, 999).text);
                line(frame.rows[2], "W%s H%s", count(s.wifiClients, 99).text, count(s.httpsClients, 99).text);
                break;
            case 6:
                if (s.notificationsEnabled)
                    line(frame.rows[0], "Alerts %s", count(s.activeAlerts, 999).text);
                else
                    line(frame.rows[0], "Alerts off");
                line(frame.rows[1], "Unacked %s", count(s.unacknowledgedAlerts, 999).text);
                line(frame.rows[2], "St%s Err%s", code(s.chargerState, fresh).text, code(s.chargerError, fresh).text);
                break;
            }
        }

    private:
        // Numeric fields saturate with '+' instead of losing most-significant
        // digits, wrapping or silently dropping their unit to fit a 12-cell row.
        struct Number
        {
            char text[8]{};
        };
        static Number count(uint64_t value, uint32_t maximum)
        {
            Number result;
            std::snprintf(result.text, sizeof(result.text), "%lu%s",
                          static_cast<unsigned long>(value > maximum ? maximum : value), value > maximum ? "+" : "");
            return result;
        }
        static Number code(uint8_t value, bool fresh)
        {
            if (!fresh || value == 255)
            {
                Number result;
                line(result.text, "--");
                return result;
            }
            return count(value, 255);
        }
        template <size_t N, typename... Args>
        static void line(char (&out)[N], const char *format, Args... args)
        {
            std::snprintf(out, N, format, args...);
        }
        static void channel(const Channel &c, const char *name, bool fresh, Frame &frame)
        {
            const bool voltage = fresh && c.voltage.valid && std::isfinite(c.voltage.number) &&
                                 c.voltage.number >= 0 && c.voltage.number <= 65;
            const bool current = fresh && c.current.valid && std::isfinite(c.current.number) &&
                                 c.current.number >= -150 && c.current.number <= 150;
            if (voltage)
                line(frame.rows[0], "%s %.2fV", name, c.voltage.number);
            else
                line(frame.rows[0], "%s --V", name);
            if (current)
                line(frame.rows[1], "%s %.1fA", name, c.current.number);
            else
                line(frame.rows[1], "%s --A", name);
            if (voltage && current)
                line(frame.rows[2], "%s %.1fW", name, c.voltage.number * c.current.number);
            else
                line(frame.rows[2], "%s --W", name);
        }
        uint32_t lastPageMs_ = 0;
        uint8_t page_ = 0;
        bool started_ = false;
    };
} // namespace bs::debugdisplay
