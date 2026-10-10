#pragma once

#if defined(BATTERYSENTINEL_DEBUG_OLED)
#include <DebugDisplayModel.h>

namespace bs {

// Main-loop only. A missing/faulted display is disabled until the next boot.
class BridgeDebugDisplay {
public:
    bool begin();
    void boot(const char* stage);
    bool due(uint32_t now);
    void show(const debugdisplay::Snapshot& snapshot);
private:
    bool ready_ = false;
    debugdisplay::Pager pager_;
};

} // namespace bs
#endif
