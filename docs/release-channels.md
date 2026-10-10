# Orion release channels

| Channel | Firmware version / Git tag | GitHub publication |
| --- | --- | --- |
| Official | `X.Y.Z` / `vX.Y.Z` | Release, marked Latest |
| Release candidate | `X.Y.Z-rc.N` / `vX.Y.Z-rc.N`, N >= 1 | Prerelease, never Latest |

[Latest official release](https://github.com/Weisni/BatterySentinel-N2K/releases/latest)
and [all releases including candidates](https://github.com/Weisni/BatterySentinel-N2K/releases)
are separate from ordinary `main` snapshots and internal debug builds. Channels
control publication; they do not add an automatic updater or reset device data.

## Publishing

1. Set the standard version in `src/BridgeFirmwareIdentity.h` and add matching
   English notes in `docs/releases/<version>.md`. Keep the internal OLED identity
   separate. Update the German manual and provisioning documents when behavior
   changes; retain private device credentials outside Git.
2. Commit and push to `main`. Confirm the complete **BatterySentinel CI** run for
   that exact commit succeeds. CI builds with pinned platform/framework/NMEA
   dependencies, validates application images, and uploads a checksummed package.
3. Tag that checked commit, for example `git tag v1.3.0-rc.1 <commit>`, then
   `git push origin v1.3.0-rc.1`. Use `v1.3.0` for an official release. Tags must
   match the firmware version and refer to commits already on `main`.
4. **Orion release channels** runs the complete reusable CI again at the tag's
   exact commit. Its publisher receives only the resulting package. It creates a
   draft, uploads assets, checks remote metadata/digests, downloads every asset,
   verifies the package and rechecks the tag before publication. Stable sets
   Latest; RC explicitly sets prerelease and disables Latest.
5. Inspect the published version, target, commit, checksums and downloads. The
   workflow can also be dispatched manually with an existing tag to retry a
   failed publication. A matching draft may resume; a published release is never
   overwritten. Fixes require a new firmware version and tag.

Creating/pushing a release tag authorizes publication. Normal branch pushes and
pull requests run CI without publishing. Permissions are read-only during
validation and `contents: write` only in the publication job. No external token
secret or additional approval environment is required.

## Public assets

- Standard Orion application `.bin` for phone OTA.
- Segmented USB ZIP with bootloader, partition table, OTA initialization image,
  application, flash offsets, checksums and instructions. No full-flash erase.
- German operating/installation PDF.
- English release notes, `release-manifest.json` and `SHA256SUMS.txt`.

Source archives are supplied by GitHub for the tag. Internal board/debug images,
discarded experiments and private Wi-Fi labels are excluded from public assets.
Software checks and an official publication do not replace physical commissioning.

GitHub's [release documentation](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
defines prereleases and Latest; [reusable workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)
keep the branch and release validation paths aligned.
