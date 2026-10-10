#include "BridgeFirmwareIdentity.h"

#include <esp_app_format.h>
#include <esp_attr.h>
#include <esp_idf_version.h>
#include <esp_ota_ops.h>
#include <sdkconfig.h>

#define ORION_STRINGIFY_INNER(value) #value
#define ORION_STRINGIFY(value) ORION_STRINGIFY_INNER(value)
#define ORION_IDF_VERSION ORION_STRINGIFY(ESP_IDF_VERSION_MAJOR) "." \
    ORION_STRINGIFY(ESP_IDF_VERSION_MINOR) "." ORION_STRINGIFY(ESP_IDF_VERSION_PATCH)

// Provide the descriptor and its IDF 4 compatibility APIs together, so the
// linker does not extract the generic descriptor from libapp_update.a.
// Normal esptool ELF-to-image conversion places it at image offset 32 and
// covers it with the appended SHA-256. Never patch a completed binary.
// Empty build time/date fields keep this metadata reproducible.
#if ESP_IDF_VERSION_MAJOR != 4
#error "Review the application descriptor API for this ESP-IDF version"
#endif

namespace {
// Panic handling can request this text while flash cache is disabled.
DRAM_ATTR char elfHashText[CONFIG_APP_RETRIEVE_LEN_ELF_SHA + 1] = {};
DRAM_ATTR bool elfHashReady = false;
}

extern "C" {
extern const esp_app_desc_t esp_app_desc __attribute__((section(".rodata_desc"), used)) = {
    ESP_APP_DESC_MAGIC_WORD,
    0, // Secure version: hardware anti-rollback is not enabled.
    {0, 0},
    ORION_FIRMWARE_VERSION,
    ORION_FIRMWARE_TARGET,
    "",
    "",
    ORION_IDF_VERSION,
    {0}, // esptool fills the ELF SHA-256 during its standard image conversion.
    {0},
};

const esp_app_desc_t* esp_ota_get_app_description() {
    return &esp_app_desc;
}

int IRAM_ATTR esp_ota_get_app_elf_sha256(char* destination, size_t capacity) {
    if (!elfHashReady) {
        // esptool replaces these bytes after compilation. Volatile prevents
        // the compiler from folding the descriptor's initial zero values.
        const volatile uint8_t* source = esp_app_desc.app_elf_sha256;
        for (size_t i = 0; i < CONFIG_APP_RETRIEVE_LEN_ELF_SHA; ++i) {
            const uint8_t value = (source[i / 2] >> (i % 2 ? 0 : 4)) & 15;
            elfHashText[i] = value < 10 ? '0' + value : 'a' + value - 10;
        }
        elfHashReady = true;
    }
    if (!destination || capacity == 0) return 0;
    size_t count = capacity - 1;
    if (count > CONFIG_APP_RETRIEVE_LEN_ELF_SHA) count = CONFIG_APP_RETRIEVE_LEN_ELF_SHA;
    count &= ~static_cast<size_t>(1); // Preserve complete hex byte pairs.
    for (size_t i = 0; i < count; ++i) destination[i] = elfHashText[i];
    destination[count] = '\0';
    return static_cast<int>(count + 1);
}

__attribute__((constructor)) void esp_ota_init_app_elf_sha256() {
    esp_ota_get_app_elf_sha256(nullptr, 0);
}
}

static_assert(sizeof(ORION_FIRMWARE_VERSION) <= sizeof(esp_app_desc.version), "Firmware version is too long");
static_assert(sizeof(ORION_FIRMWARE_TARGET) <= sizeof(esp_app_desc.project_name), "Firmware target is too long");
static_assert(CONFIG_APP_RETRIEVE_LEN_ELF_SHA <= 64 && CONFIG_APP_RETRIEVE_LEN_ELF_SHA % 2 == 0,
              "ELF hash text length must fit SHA-256 and complete byte pairs");
