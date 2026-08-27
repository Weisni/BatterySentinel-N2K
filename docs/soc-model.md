# AGM SOC Model

BatterySentinel is intentionally switched with ignition, so it cannot count every coulomb while the boat is off. V1 therefore uses a **hybrid SOC estimator** rather than pretending that a pure coulomb counter is exact.

## Inputs

Per battery bank:

- terminal voltage from INA238 VBUS
- bidirectional current from the high-side shunt
- configured nominal capacity
- last persisted SOC from ESP32 NVS
- elapsed active time

V1 does not have a battery-temperature probe. Battery temperature and State of Health are therefore not invented and are published as `Not Available` where possible.

## Capacities

| Battery | Capacity |
|---|---:|
| System | 70 Ah |
| Bow thruster | 90 Ah |

## Current convention

- `I > 0`: charging
- `I < 0`: discharging

## Coulomb counting

For each valid time step:

```text
delta_Ah = I[A] * dt[s] / 3600
```

When charging:

```text
delta_Ah_effective = delta_Ah * charge_efficiency
```

V1 default charging efficiency is `0.93` for AGM. This is a commissioning parameter, not a universal chemistry constant.

```text
SOC_new = clamp(SOC_old + delta_Ah_effective / capacity_Ah * 100, 0, 100)
```

Discharge is integrated directly. Very large scheduler gaps (`dt > 5 s`) are **not** integrated because doing so after a reset/stall could fabricate a large charge transfer from one stale measurement.

## NVS persistence

SOC is persisted:

- every 60 s during normal operation
- immediately after a high-current event ends (starter / bow-thruster pulse)

The second rule specifically protects against this sequence:

1. bow thruster consumes significant current
2. user immediately switches ignition off
3. periodic NVS interval has not elapsed yet

Without event-end persistence, the next boot would restore a SOC value from before the thruster event.

## OCV correction

Generic V1 AGM resting-voltage curve:

| Resting V | Estimated SOC |
|---:|---:|
| <=11.90 V | 0 % |
| 12.00 V | 20 % |
| 12.15 V | 40 % |
| 12.30 V | 60 % |
| 12.45 V | 75 % |
| 12.60 V | 90 % |
| >=12.75 V | 100 % |

Linear interpolation is used between points.

OCV is considered only while:

- absolute battery current <= 0.8 A
- voltage is between 11.5 V and 12.95 V

Voltage above 12.95 V is deliberately rejected as OCV because it may be charger voltage or surface charge after charging.

### Startup

If no valid persisted SOC exists and the battery appears rested, OCV can initialize the SOC after a short validation period.

### Running correction

After a longer low-current/rest interval, OCV is blended into the coulomb estimate rather than replacing it:

```text
SOC = 0.80 * coulomb_SOC + 0.20 * OCV_SOC
```

The blend prevents an instantaneous SOC jump from minor AGM voltage variation.

## Full-charge synchronization

A battery is synchronized to 100 % when all of the following remain true for the configured delay:

- battery voltage >= 14.2 V
- current is charging or approximately zero, not discharging
- charging current is below C/50

C/50 thresholds:

- System 70 Ah: 1.4 A
- Bow 90 Ah: 1.8 A

Default hold time: 300 s.

The bow charger is current-limited. During the bulk/current-limit phase the measured charging current should remain above the tail threshold, so V1 will not incorrectly synchronize to 100 %. Synchronization happens only when voltage is high and the battery current has tapered.

## Heavy-load handling

The bow thruster can draw around 200 A. Terminal voltage can therefore sag dramatically even when SOC is healthy. V1 does **not** use voltage for SOC correction under load.

Example:

```text
rest:       12.6 V / 0 A      -> OCV may be useful
thruster:   10.2 V / -180 A   -> coulomb count only
recovery:   12.4 V / -0.2 A   -> wait for rest before OCV blending
```

## Low-voltage alarm strategy

A single voltage threshold would create false alarms during the bow-thruster pulse, so V1 uses two contexts:

- idle/light-load threshold, longer delay
- heavy-load threshold, substantially lower voltage and shorter delay

Initial values are deliberately conservative and must be tuned with real boat measurements.

## Known limitations

1. Charging/discharging while ignition is off is not coulomb-counted.
2. OCV is temperature-dependent; V1 has no battery-temperature measurement.
3. AGM aging changes real capacity from the nominal 70/90 Ah values.
4. Very high discharge rates have Peukert/recovery effects. V1 reports charge-based SOC rather than claiming to model short-term cranking capability.
5. Immediately after an off-state charge, surface charge may delay OCV correction.

These are acceptable for the requested 'as good as reasonably possible' family-use monitor. A later V2 could add an always-on low-power measurement domain, battery temperature and adaptive learned capacity.
