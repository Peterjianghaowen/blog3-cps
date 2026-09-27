# How Did the COVID-19 Shock Differ Across U.S. States?

Blog Post 3 for AEDS 6400. Uses IPUMS CPS basic monthly microdata (January 2019 to August 2026) to compare the pandemic unemployment shock and recovery across states, and to test whether states more reliant on leisure and hospitality were hit harder.

## Repository structure

```
code/
  01_download.R   # Download CPS monthly samples via the IPUMS API
  02_clean.R      # Compute weighted unemployment rate, LFPR, and industry shares
  03_figures.R    # Produce the three figures
data/
  raw/            # IPUMS extract (not tracked; see below)
  processed/      # Aggregated series used for the figures
output/           # Figures (PNG) and interactive state map (HTML)
```

## How to replicate

1. Register for an IPUMS account at https://cps.ipums.org and create an API key at https://account.ipums.org/api_keys.
2. In R, save the key once: `ipumsr::set_ipums_api_key("YOUR_KEY", save = TRUE)`, then restart R.
3. Install packages: `install.packages(c("ipumsr", "dplyr", "tidyr", "ggplot2", "plotly"))`.
4. Open `blog3-cps.Rproj` and run the scripts in order: `01_download.R`, `02_clean.R`, `03_figures.R`.

Raw microdata are not included because of file size and IPUMS redistribution terms. `01_download.R` recreates the extract.

## Methods notes

- Sample: civilians aged 16+ (`AGE >= 16`, excluding armed forces).
- All statistics are weighted with the CPS final person weight `WTFINL`.
- Unemployment rate = unemployed / labor force; LFPR = labor force / population.
- Figures are not seasonally adjusted, so they differ slightly from BLS headline numbers.
- October 2025 was not collected due to the federal government shutdown. 2026 covers January to August.
- Leisure and hospitality = IPUMS `IND` codes 8560 to 8690.

## Data source

IPUMS CPS, University of Minnesota, www.ipums.org. Please cite according to the IPUMS CPS citation guidelines.