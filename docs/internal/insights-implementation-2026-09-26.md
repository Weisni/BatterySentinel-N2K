# Orion observations, notifications and network time

Implementation record for firmware 1.2.0, 2026-09-26. The user authorized the feasible functions from the [concept](battery-insights-concept.md). User operation is described in [Diagnostics and notifications](../diagnostics-logging.md).

## Data and ownership

- `BridgeInsights` is a pure, bounded observation and alert engine. `BridgeDiagnostics` serializes main-loop updates and HTTPS configuration/acknowledgement using a task mutex. Large snapshots are caller-owned or heap-allocated to avoid exhausting the HTTPS task stack.
- The main loop evaluates at 100 ms intervals, using the actual accepted Orion arrival timestamps, not HTTP polling times. Counters plus arrival times reject duplicated records. All integration and qualification use 64-bit monotonic milliseconds.
- Both channels retain voltage extrema, positive transferred Ah/Wh, covered durations and observed time strictly below the configured low-voltage limit. A changed low limit resets its below-limit duration. The bounded trend history contains at most 60 consecutive samples no older than five minutes. Gaps over five seconds and invalid voltage reset the affected history/qualification; accumulated covered totals remain.
- No extrapolation fills gaps, reverse current is excluded from forward transfer, and the two channel currents do not constitute either battery's net current. No SOC, resistance, remaining-runtime or battery-life estimate is exposed.
- The six independently qualified incidents are input/output low and high voltage, missing Orion records and charger error. Active incidents survive unknown data; acknowledgement stops reminders without clearing the fault. Changed rules cancel their previous incident and require new qualifying observations.

## Configuration and API

- A versioned 44-byte CRC-protected blob uses the separate NVS key `notify_v1`. A single committed write precedes changing the runtime configuration. Missing settings use disabled defaults; invalid settings remain disabled and visibly require review. Existing account, radio, Orion and mapping keys are preserved.
- `/api/live` contains `bootId`, `insights`, `notifications`, `time` and dated `events`. `/api/events` supplies the event stream and time correlation. The event ring contains 64 records and is protected against concurrent main-loop/HTTPS access; it is not a persistent voyage log.
- Authenticated, CSRF-protected `POST /notifications` accepts strict decimal thresholds and bounded durations. `POST /notifications/ack` requires the slot and current incident generation, preventing an old acknowledgement from dismissing a new incident.
- The bilingual portal uses its existing single polling connection. Edits survive polling/language changes; saving or acknowledging pauses polling and prevents duplicate submission. A changed boot ID resets the browser's event cursor and time correlation.

## Network time

The configured NMEA bridge requests ISO NAME, GNSS PGN 129029 and System Time PGN 126992. Calendar time requires a claimed source identity, plausible date/time, eligible source/fix fields and three consistent advancing anchors. A fresh source remains selected across address changes. More than 30 seconds without a trusted anchor enters holdover; conflicting large clock changes are quarantined. Acquisition and retries never block startup.

The accepted UTC/monotonic correlation can date earlier events from the current boot. Uptime is always retained. Neither flash timestamps nor a saved last date can measure time while the device is unpowered; previous boots are not reconstructed. Received time is consistency-checked, not cryptographically authenticated. Calendar corrections cannot alter energy integration or alarm deadlines.

## Experimental alert delivery

PGNs 126983 and 126985 carry source-scoped local warning identities and English alert text. The NMEA option defaults off. Local acknowledgement is supported; incoming remote acknowledgements are deliberately ignored because a finite occurrence field cannot safely distinguish delayed acknowledgements across cold boots. Send acceptance never proves receiver receipt, display or sound.

The bounded sender retries failed submissions and reannounces current states plus retained withdrawals after address claims. Up to 24 previous identities remain in RAM for remaps or unresolved failed clears; exhausting the bound reports backlog rather than silently dropping a required withdrawal. Ordinary incidents with accepted normal clears do not consume this history.

Configuration changes, forgetting the Orion and successful OTA schedule a main-loop restart after returning the HTTP response. Normal telemetry publication stops during this phase. The sender tries each announced withdrawal three times and permits restart after completion or a five-second deadline. This does not guarantee receiver acknowledgement. The internal timeout flag is transient: the restart guard blocks live API requests and reboot clears RAM, so the portal cannot serve as evidence of final withdrawal success or failure. Abrupt power loss, a disconnected receiver or a reboot after the deadline can leave a stale receiver warning; the withdrawal history is not persistent across boots. This limitation is part of the experimental receiver acceptance test.

## Verification and physical acceptance

- Native suite: 147 cases passed, including 24 observation/incident cases, 10 storage/parser cases, 8 clock cases and 11 alert-codec/delivery cases. The storage tests inject failed writes and power loss on either side of the atomic commit; the parser tests every allowed centivolt value.
- HTTP tests execute extracted production handlers with hardware/transport adapters: 175 checks cover authentication/CSRF, malformed values, failed persistence, unavailable monitoring, incident generations, backdated events, deferred restart and preservation of unrelated settings. Restoring the original login bugs triggers the expected failures.
- Browser fixtures exercise the actual embedded scripts with synthetic data. They cannot establish radio, electrical or chartplotter behavior.
- All three existing firmware environments built successfully. The downloadable SuperMini image is 1,901,648 bytes, leaving 64,432 bytes in its existing OTA slot. Both Python image inspection and the production C++ streaming validator accepted target `orion-dongle`, version `1.2.0`, checksum and appended digest. Its complete-file SHA-256 is `c2b96ba69ca7142db643f30959de16e249fc8a669a1a8db22a60f1a0a7561ce3`.

Before relying on alerts on the boat, verify time reception after boot and late plotter startup; threshold/clear behavior with measured channel voltages; continued device and Orion power after ignition-off; Wi-Fi/BLE coexistence; repeated phone login; alert display/text/priority, local acknowledgement and withdrawal on the exact Garmin; bus loss, receiver restart, device restart and abrupt power loss. Local software checks do not complete these physical checks.
