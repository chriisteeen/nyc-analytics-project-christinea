# Shared Earth Similarity Index Calculation

This folder contains the official ESI method and calculation used by Team R&P.

All four analyses must use the ESI values produced here. Team members should not create separate versions of the ESI calculation.

## Project Definition

For this project, a confirmed exoplanet is classified as a high-ESI Earth-like candidate when:

ESI >= 0.80

## Planned Files

- `calculate_esi.R`: Calculates the Earth Similarity Index.
- `esi_method.md`: Documents the formula, variables, weights, assumptions, and sources.
- `esi_validation.R`: Checks that the formula produces reasonable results.
- `esi_results.csv`: Contains the calculated ESI for eligible planets.
