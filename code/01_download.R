# 01_download.R
# Download IPUMS CPS basic monthly samples (2019-present) via the IPUMS API.
# Requires an IPUMS API key saved with ipumsr::set_ipums_api_key().

library(ipumsr)
library(dplyr)

# All basic monthly samples from Jan 2019 onward (excludes ASEC)
month_pattern <- paste(month.name, collapse = "|")
samples <- get_sample_info("cps") |>
  filter(grepl(paste0("^IPUMS-CPS, (", month_pattern, ") (2019|202\\d)$"),
               description)) |>
  pull(name)

extract <- define_extract_micro(
  collection  = "cps",
  description = "State unemployment 2019-present",
  samples     = samples,
  variables   = c("STATEFIP", "AGE", "EMPSTAT", "LABFORCE", "IND", "WTFINL")
)

extract |>
  submit_extract() |>
  wait_for_extract() |>
  download_extract(download_dir = "data/raw")