# Project-internal engineering records

This index is for project development. These records are not installation instructions, product releases or evidence that a hardware variant was built. The user-facing product is the current Orion Bridge with the ESP32-C3 SuperMini; start with the [project README](../../README.md) and its operating/assembly manuals.

Earlier hardware revision labels identify internal design iterations only. The measurement/shunt concept was never built and remains internal. Preserve source code, CAD, tests and records for engineering work without presenting them as available or previously released products.

## Preserved documentation

The following snapshots preserve the previous wording and its evidence. Current instructions supersede their recommendations and open-order statements.

- [Project overview before public cleanup](readme-before-public-cleanup-2026-09-26.md).
- [Orion investigation and chronological test record](orion-investigation-before-public-cleanup-2026-09-26.md).
- [Hardware planning overview](hardware-index-before-public-cleanup-2026-09-26.md).
- [Provisional enclosure record](../../hardware/altium-r5/enclosure/PROVISIONAL-ENCLOSURE-INTERNAL.md).
- [Firmware archives](../../output/internal/firmware/README.md) and [engineering release status](../../output/releases/RELEASE-STATUS.md).

## Hardware development

- [Initial interface study](../../hardware/orion-dongle-nmea2000.md), [initial PCB study](../../hardware/orion-pcb-r1.md) and [drawing PDF](../../output/internal/engineering/orion-bridge-schaltplan-pcb-entwurf.pdf).
- Internal Altium source iterations: [initial library](../../hardware/altium/README.md), [R2](../../hardware/altium-r2/README.md), [R3](../../hardware/altium-r3/README.md), [R4](../../hardware/altium-r4/README.md).
- Current engineering sources: [module selection](../../hardware/altium-r5/module-selection.md), [power review](../../hardware/altium-r5/power-review.md), [module study](../../hardware/altium-r5/supermini-review.md), [manufacturing workflow](../../hardware/altium-r5/manufacturing-workflow.md).
- [German manual production](../german-manual-production.md) and [enclosure manual production](../enclosure-manual-production.md).

## Firmware implementation and verification

- [OLED debug board, wiring and status guide](oled-debug.md) and [implementation plan](oled-debug-plan.md) — the explicitly requested integrated-display debug jig, its separate build and outstanding hardware checks.
- [Observations, notifications and network-time implementation](insights-implementation-2026-09-26.md) — firmware 1.2.0 behavior, configuration/API, verification and remaining physical checks.
- [Battery insights, timekeeping and notifications concept](battery-insights-concept.md) — feasibility and staged proposal; channel observations, local notifications and network time are implemented in 1.2.0. Full battery estimators remain outside the available measurements.
- [OTA hardware checks](../ota-hardware-test-2026-09-25.md) and [HTTP parsing notes](../ota-http-parser-notes.md).
- [Service Wi-Fi](../service-wifi-2026-09-25.md) and [portal performance](../portal-performance-2026-09-25.md).
- [Password recovery and LED implementation](../password-recovery-and-wifi-2026-09-26.md).
- [Login reliability follow-up](../login-reliability-2026-09-26.md).

Results belong to the dated firmware and test setup recorded in each note. They do not establish acceptance of the final assembled installation. The internal `orion_r4` firmware environment and its binaries are engineering targets, not alternate download choices for users.

## Unbuilt measurement concept

The `esp32c3` target, BatteryCore/BatteryProfiles/LogCore/StateCore, INA238/FRAM/logging sources and their tests remain development material. These models and source targets do not describe the Orion Bridge's capabilities.

- [Architecture](../architecture.md), [hardware concept](../hardware.md), [SOC model](../soc-model.md), [archived diagnostics/logging concept](diagnostics-logging-concept-archive.md) and [test strategy](../test-plan.md).
- [Simulation guide](../simulation.md), [simulator environments](../../sim/README.md) and [Wokwi model](../../sim/wokwi/README.md).

The browser simulator is project-internal. Its workflow runs syntax checks only and no longer publishes it to GitHub Pages. Existing hosting, if any, is not removed by this local change. The current Orion [portal preview](../web-preview.md) remains available for UI development.

## Cleanup verification — 2026-09-26

Public entry points, operating instructions and downloads now describe the current bridge. Both current PDFs were rebuilt and visually checked. Historical data are preserved here or in explicitly marked engineering records. The cleanup does not change firmware behavior, CAD geometry or the user's manufacturing files.
