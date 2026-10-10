# Awesome AI process presets for Bambu P2S

Two importable process presets for the **Bambu P2S with a 0.4 mm nozzle**:

- `0.2mm Optimized @BBL P2S - Awesome AI.json`
- `0.12mm Optimized @BBL P2S - Awesome AI.json`

These combine the enclosure process with the user's regular Bambu Studio `0.20mm Standard @BBL P2S - Smooth Surface` surface settings. The account copy in QuackSlicer matches that source. Same-name presets in Bambu Studio Beta, OrcaSlicer and QuackSlicer's default user folder differ; they were not blended into this release. The source choice was stated to the user while awaiting optional clarification.

The user reports excellent results from the previous enclosure profile except for surface finish. This feedback supports retaining its core settings; these newly combined profiles have not yet been physically printed.

## Import and use

1. In Bambu Studio or QuackSlicer, use **File > Import > Import Configs** and select the two JSON files in this directory. Do not import the source or validation JSON files.
2. Select **Bambu Lab P2S 0.4 nozzle** and choose the new process name. For the current enclosure, use the 0.2-mm preset first to compare the changed surface finish directly.
3. Select your calibrated filament preset and actual build plate, then re-slice. These are process-only files; they do not replace nozzle/bed temperatures, filament flow calibration, cooling, pressure advance, machine limits or printer connection settings.
4. Existing object/plate overrides in a loaded 3MF take precedence over matching global process fields. The enclosure's TPU objects have separate speed, wall and infill overrides. These general presets describe the rigid-part process, not a replacement TPU calibration. Keep the enclosure's TPU seal workflow at 0.20 mm when evaluating the new 0.12-mm rigid-part option.

The current enclosure 3MF and existing user presets were not overwritten. Importing creates the two newly named presets; no print has been sent to the printer.

## Merge comparison

| Setting | Previous enclosure | Smooth Surface source, Standard nozzle | Awesome AI, both heights |
|---|---:|---:|---:|
| Top surface speed | 35 mm/s | 15 mm/s | **15 mm/s** |
| Top surface acceleration | 2,000 mm/s² | 500 mm/s² | **500 mm/s²** |
| Top surface line width | 0.42 mm | 0.30 mm | **0.30 mm** |
| Wall generator | Classic | Arachne | **Arachne** |
| Arachne minimum bead width | Inherited; inactive with Classic | 50% | **50%** |
| Arachne wall transition angle | Inherited; inactive with Classic | 40° | **40°** |
| Top surface pattern | Monotonic line | Monotonic line | Monotonic line |
| Top surface flow ratio | 1.00 | 1.00 | 1.00 |
| Ironing | Off | Off | Off |
| Wall loops | 5 | 2 | **5** |
| Infill | 35% gyroid | 15% gyroid | **35% gyroid** |
| Outer / inner wall speed | 40 / 80 mm/s | 200 / 300 mm/s | **40 / 80 mm/s** |
| Sparse / solid infill speed | 100 / 80 mm/s | 270 / 250 mm/s | **100 / 80 mm/s** |
| First layer / first-layer infill | 20 / 25 mm/s | 30 / 60 mm/s | **20 / 25 mm/s** |
| Normal / outer-wall acceleration | 3,000 / 1,000 mm/s² | 10,000 / 6,000 mm/s² | **3,000 / 1,000 mm/s²** |
| Bridge speed | 25 mm/s | 50 mm/s | **25 mm/s** |
| Elephant-foot compensation | 0.10 mm | 0.15 mm | **0.10 mm** |
| Supports / brim | Off / none | Off / inherited | Off / none |
| Prime tower | On in current colour project | Off | **On**, retaining the colour project's choice |

Arachne also affects side-wall path generation, not just the final top layer. Its two associated parameters are copied with it so the user's surface strategy stays coherent. First-layer speeds remain at the enclosure values because the request was to preserve its other successful settings. A surface printed against the build plate still reflects that plate's texture; slower top-surface settings do not change the plate-facing exterior finish of the face-down lid.

The source's second speed-array entries are `nil`, meaning inherited High Flow values. The new profiles intentionally apply **15 mm/s and 500 mm/s² to both Standard and High Flow variants**, avoiding a return to the much faster factory top surface in the second variant. No additional flow multiplier or ironing pass was introduced.

## Layer-height conversion

| Setting | 0.2-mm preset | 0.12-mm preset |
|---|---:|---:|
| Normal layer height | 0.20 mm | 0.12 mm |
| First layer height | 0.20 mm | 0.20 mm |
| Top / bottom solid layers | 6 / 6 | 10 / 10 |
| Minimum top / bottom thickness fields | Original 1.0 / 0 mm; six layers govern | Explicit 1.2 / 1.2 mm |
| Nominal top solid thickness | 1.20 mm | 1.20 mm |
| Bottom stack including first layer | 1.20 mm | At least 1.20 mm; ten layers nominally 1.28 mm |
| Support top / bottom contact gap, if manually enabled later | 0.20 / 0.20 mm | 0.12 / 0.12 mm |

Wall count, fill, surface line width, speeds and the selected accelerations remain the same at both layer heights. The 0.12-mm preset inherits the official high-quality parent but explicitly preserves the remaining enclosure choices, preventing hidden speed changes caused by switching the parent alone. Its layer count preserves the shell thickness instead of reducing it to 0.72 mm.

## Compatibility and verification

- Both files have unique names, process IDs, printer compatibility and Standard/High Flow variant metadata. System/cloud IDs are not copied.
- Native QuackSlicer slicing of the actual fit coupon succeeded for **both profiles**, followed by ZIP integrity, toolpath presence and readback of the merged surface, shell and core process fields. See [validation-report.json](validation-report.json).
- The thin deliverables were resolved against the installed QuackSlicer parents for validation. No support sentinel overrides were injected into that successful test: Quack inherits its valid automatic-support-wall value of 0.
- Native Bambu Studio validation could not run: its executable exited with -2 and no diagnostic output on this host. Bambu profile inheritance and JSON reconstruction were checked, but a Bambu GUI import or native Bambu slice is not claimed.
- The shared bottom-surface pattern, arc fitting and prime-tower ironing fields are explicit because the Bambu and Quack parents differ there. Bambu's `reduce_infill_retraction_mode=Auto` has no direct verified mapping to Quack's boolean setting, so that app-specific inherited behavior is retained. No claim of identical toolpaths across slicers is made.
- The generic PETG file used for the validation coupon is only test input. The delivered presets contain no filament settings.
- [comparison.json](comparison.json) records the full process-field comparison; [sources](sources) contains source snapshots and official profile hashes. Validation toolpaths are disposable QA artifacts, not a prepared replacement enclosure project.

## Progress and remaining work

- [x] Inspect the distinct same-name user profiles and choose the regular Bambu/account Quack source.
- [x] Create both requested names and preserve the intended enclosure core settings.
- [x] Preserve at least 1.2 mm solid skin thickness at 0.12 mm.
- [x] Validate native slicing and exported key settings at both heights.
- [ ] Import into the user's active GUI and compare the new top finish on a physical print with the chosen filament.
- [ ] Recheck fit where Arachne changes thin-wall paths; mechanical sealing acceptance remains separate.

Rebuild with `tools/build_awesome_ai_profiles.py`, then validate with `tools/validate_awesome_ai_profiles.py`, using the bundled Python runtime. Existing source presets and the enclosure 3MF are read-only inputs.
