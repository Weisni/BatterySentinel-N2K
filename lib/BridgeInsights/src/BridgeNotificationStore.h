#pragma once

#include <BridgeInsights.h>
#include <cstddef>
#include <cstdint>

namespace bs::insights {

inline constexpr char kNotificationEntry[] = "notify_v1";
enum class LoadResult { Missing, Current, Invalid };

// One versioned blob is committed by Preferences/NVS. Never remove the old
// entry before writing: a failed write must preserve the last saved settings.
template <typename Store>
LoadResult loadNotifications(Store& store, Config& config) {
    if (!store.isKey(kNotificationEntry)) return LoadResult::Missing;
    uint8_t bytes[kConfigBlobSize]{};
    if (store.getBytesLength(kNotificationEntry) != sizeof(bytes) ||
        store.getBytes(kNotificationEntry, bytes, sizeof(bytes)) != sizeof(bytes) ||
        !decodeConfig(bytes, sizeof(bytes), config)) return LoadResult::Invalid;
    return LoadResult::Current;
}

template <typename Store>
bool saveNotifications(Store& store, const Config& config) {
    uint8_t bytes[kConfigBlobSize]{};
    return encodeConfig(config, bytes, sizeof(bytes)) &&
           store.putBytes(kNotificationEntry, bytes, sizeof(bytes)) == sizeof(bytes);
}

} // namespace bs::insights
