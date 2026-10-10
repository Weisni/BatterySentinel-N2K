#pragma once

// Bump this version for every released Orion firmware build.
#if defined(BATTERYSENTINEL_DEBUG_OLED)
#define ORION_FIRMWARE_VERSION "1.2.0-debug.1"
#else
#define ORION_FIRMWARE_VERSION "1.2.0"
#endif

#if defined(BATTERYSENTINEL_DEBUG_OLED)
#define ORION_FIRMWARE_TARGET "orion-debug-oled"
#elif defined(BATTERYSENTINEL_ORION_R4)
#define ORION_FIRMWARE_TARGET "orion-r4"
#else
#define ORION_FIRMWARE_TARGET "orion-dongle"
#endif

namespace bs {

inline constexpr char kBridgeFirmwareVersion[] = ORION_FIRMWARE_VERSION;
inline constexpr char kBridgeFirmwareTarget[] = ORION_FIRMWARE_TARGET;

} // namespace bs
