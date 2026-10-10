# Orion Bridge 1.1.4

Application firmware for the Orion Bridge with ESP32-C3 SuperMini on the Orion-R5
board: [Download orion-dongle-1.1.4.bin](orion-dongle-1.1.4.bin).

Save the file on your phone, then install it through **Settings → Firmware
update** while keeping device power stable. The portal device target is
`orion-dongle`. Follow the [installation instructions](../../../docs/firmware-update.md).

File checksum: [SHA256SUMS.txt](SHA256SUMS.txt). SHA-256:

```text
499026c1693867061fed74c80720619d695a46305b7d95c6ae81dd4834091161
```

This release improves sign-in navigation and releases completed HTTPS connections
before the next request. Duplicate login submissions are blocked, and Browser
Back restores the sign-in button without automatically resending credentials.

Password changes, physical BOOT-confirmed password recovery and the status-based
blue Wi-Fi LED are included. Saved settings, credentials and assignments are
preserved. Recovery instructions and the published recovery password are in the
[offline first-connection guide](../../../docs/erstverbindung.md#administrator-passwort-vergessen).

Builds, native tests, portal/browser tests and independent application-image
validation passed. This release has not been flashed or physically accepted
during this task; repeated login checks on the reporting phone remain outstanding.
