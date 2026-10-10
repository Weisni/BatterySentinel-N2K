# Orion Bridge firmware updates

These instructions apply to the Orion Bridge with an ESP32-C3 SuperMini on the
Orion-R5 board. The web portal installs an application firmware file already
saved on your phone or computer. No internet connection or companion app is
needed while you are connected to the bridge.

## Download the firmware

Save [Orion Bridge 1.2.0](../output/firmware/1.2.0/orion-dongle-1.2.0.bin) in your
phone's Files or Downloads folder before joining the bridge Wi-Fi.

- Filename: `orion-dongle-1.2.0.bin`
- Portal device target: `orion-dongle`
- SHA-256: `8f14e3480ce6b0f8768657601d1f04fda5600d0f1214d4cf547e867e3599e979` ([checksum file](../output/firmware/1.2.0/SHA256SUMS.txt)).

Use the application `.bin` file directly. Do not upload a ZIP archive, bootloader,
partition table or complete flash backup. Obtain the file from a trusted release
source; a matching hash checks the file's contents but does not authenticate its
publisher.

## Install from a phone

1. Keep the bridge supplied with stable power throughout the update. Use one
   browser tab/device and close other open portal pages.
2. Connect directly to **`OrionBridge-XXXXXX`** and open
   [https://batterysentinel.local/](https://batterysentinel.local/). If the name
   does not resolve, use [https://192.168.4.1/](https://192.168.4.1/). Sign in as
   administrator; the [first-connection guide](erstverbindung.md) explains local
   access and password recovery.
3. Open **Settings → Firmware update**. Check the installed version and confirm
   that the displayed device target is **`orion-dongle`**.
4. Select **`orion-dongle-1.2.0.bin`** from the phone. Selecting a file shows its
   name and size; it does not install anything yet.
5. Tap **Upload and install**. Keep the browser in the foreground and remain on
   the bridge Wi-Fi while the progress indicator runs. Do not disconnect power.
6. After successful validation, the bridge restarts. Reconnect to its Wi-Fi if
   needed, reopen the portal, sign in and confirm installed version **1.2.0**.

The update preserves your administrator credentials, Wi-Fi password, Orion
connection, battery names, NMEA assignments and saved notification settings. It does not reset the device. Observation totals, the recent event log, active incidents and the network clock restart with the new boot. Notifications are globally disabled on first use; review the limits in **Alerts** before enabling them.

## If the update does not finish

| What you see | What to do |
| --- | --- |
| File rejected before installation | Check the filename and device target. Download the application file again if the checksum is invalid. |
| Session expired | Sign in again and select the file again. |
| Connection lost or result unknown | Reconnect and check the installed version before starting another upload. The browser never retries automatically. |
| Wi-Fi no longer visible | Allow the normal restart to finish. Hold BOOT for more than two seconds after startup to reopen service Wi-Fi if needed. |
| Upload unavailable | USB installation is required for the device's flash layout. Preserve stored settings; do not erase the whole flash to recover a password. |

If USB service is needed on the assembled bridge, select **SERVICE before
connecting USB** and **disconnect USB before selecting RUN**.

The blue SuperMini LED lights when service Wi-Fi and the web service are ready.
Your phone may refresh its network list slightly later. A connected client keeps
service Wi-Fi open; without connected clients it closes after five minutes.

## What the device checks

The bridge requires an authenticated administrator session, checks that the file
fits the available update space, and verifies the processor, device target,
image structure, checksum and SHA-256. It writes the unused application slot and
selects it for startup only after validation succeeds. A rejected or incomplete
transfer does not activate the candidate image. If the connection is lost near
the end, follow the version check above because the response may have been lost
after installation.

These checks detect incompatible or damaged files. They do not prove that a
compatible firmware image is free of bugs. Automatic recovery based on application
health is not implemented; a valid image that fails after startup may require
USB recovery. Portal updates do not replace the bootloader or flash layout.

## New in 1.2.0

The portal adds observed channel voltage history/trends, covered Orion Ah/Wh, configurable voltage/data/error notifications and validated network UTC for events. The master warning switch and experimental Garmin delivery default to off. These observations do not estimate battery state of charge or control charging. Read the [operating limits and defaults](diagnostics-logging.md) before enabling notifications.

## Release verification

Final 1.2.0 build, image/package checks and their results are recorded in the
[release details](../output/firmware/1.2.0/README.md). Physical acceptance of this
release remains outstanding. Phone/browser
coverage, power interruption during installation, and operation with the Orion,
NMEA network and Garmin must be verified on the assembled device.

For daily use and password recovery, keep the
[first-connection guide](erstverbindung.md) available offline.
