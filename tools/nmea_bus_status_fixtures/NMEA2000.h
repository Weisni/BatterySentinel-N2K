#pragma once

// Dispatch through the same virtual callbacks used by the real NMEA2000 base.
// No private production state is exposed or changed for these tests.
class tNMEA2000 {
public:
    virtual ~tNMEA2000() = default;
    bool openTest() { return CANOpen(); }
    bool getTest(unsigned long& id, unsigned char& length, unsigned char* data) {
        return CANGetFrame(id, length, data);
    }
    bool sendTest(unsigned long id, unsigned char length,
                  const unsigned char* data, bool waitSent = true) {
        return CANSendFrame(id, length, data, waitSent);
    }
protected:
    virtual bool CANOpen() = 0;
    virtual bool CANGetFrame(unsigned long&, unsigned char&, unsigned char*) = 0;
    virtual bool CANSendFrame(unsigned long, unsigned char, const unsigned char*, bool) = 0;
};
