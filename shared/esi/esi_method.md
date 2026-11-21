# Earth Similarity Index Method

## Purpose

This document defines the Earth Similarity Index method that will be used by Team R&P.

All four specific-question analyses must use the same final ESI calculation.

## Project Classification Rule

For this project, a confirmed exoplanet will be classified as a high-ESI Earth-like candidate when:

ESI >= 0.80

The ESI measures physical similarity to Earth. It does not prove that a planet is habitable or contains life.

## Published Formula

For each planetary characteristic, the individual similarity score is:

ESI_x = (1 - abs((x - x_earth) / (x + x_earth))) ^ w

Where:

- `x` is the planet’s value.
- `x_earth` is Earth’s reference value.
- `w` is the published weight for that characteristic.

The overall ESI is the geometric mean of four component scores:

ESI = (ESI_radius * ESI_density * ESI_escape * ESI_temperature) ^ (1/4)

## Components

| Component | NASA Variable or Calculation | Earth Reference | Weight |
|---|---|---:|---:|
| Planet radius | `pl_rade` | 1 Earth radius | 0.57 |
| Planet density | `pl_dens` | 5.514 g/cm³ | 1.07 |
| Escape velocity | Derived from `pl_bmasse` and `pl_rade` | 1 Earth escape velocity | 0.70 |
| Surface temperature | Must be estimated or approximated | 288 K | 5.58 |

## Escape-Velocity Calculation

Because mass and radius are already expressed in Earth units, the planet’s escape velocity relative to Earth can be calculated as:

escape_velocity_ratio = sqrt(pl_bmasse / pl_rade)

## ## Temperature Method

The NASA Exoplanet Archive provides planetary equilibrium temperature (`pl_eqt`) rather than directly measured surface temperature. For this project, we use `pl_eqt` as a proxy for surface temperature and compare it with Earth’s reference temperature of 288 K. Because these temperatures are not directly equivalent, our calculated measure will be described as an **adapted Earth Similarity Index (ESI)**. This limitation will be acknowledged when interpreting and reporting the results.

## Density Rule

The preferred density variable is NASA’s `pl_dens`.

If density is missing but mass and radius are available, density may be estimated using:

density_earth_ratio = pl_bmasse / (pl_rade ^ 3)

Any estimated density must be identified using a separate `density_source` column.

## Missing-Data Rules

- A final ESI will not be calculated when a required input is missing unless an approved estimation method is used.
- Missing measurements will not automatically be replaced with Earth values.
- Every estimated value must be identified.
- Excluded planets must receive an exclusion reason.
- The number of included and excluded planets will be reported.

## Planned Output Columns

The ESI results should eventually include:

- `pl_name`
- `pl_rade`
- `pl_bmasse`
- `pl_dens`
- `density_source`
- `pl_eqt`
- `surface_temp_k`
- `surface_temp_method`
- `escape_velocity_ratio`
- `esi_radius`
- `esi_density`
- `esi_escape`
- `esi_temperature`
- `esi`
- `high_esi`
- `esi_eligible`
- `esi_exclusion_reason`

## Validation Rules

The completed calculation must satisfy these checks:

- Earth’s reference values produce an ESI of 1.
- Every ESI result falls between 0 and 1.
- `high_esi` is TRUE only when ESI is at least 0.80.
- A planet with an incomplete calculation is not labeled high-ESI.
- Estimated and reported measurements remain distinguishable.

## Sources

- Schulze-Makuch et al. (2011), “A Two-Tiered Approach to Assessing the Habitability of Exoplanets”: https://doi.org/10.1089/ast.2010.0592
- NASA Exoplanet Archive PS and PSCompPars Column Definitions: https://exoplanetarchive.ipac.caltech.edu/docs/API_PS_columns.html
