# 02_clean.R
# Compute weighted unemployment rate and LFPR from IPUMS CPS monthly data.
# Output: national monthly series and state-by-year series in data/processed/

library(ipumsr)
library(dplyr)

ddi <- read_ipums_ddi("data/raw/cps_00002.xml")
cps <- read_ipums_micro(ddi, vars = c(YEAR, MONTH, STATEFIP, AGE,
                                      EMPSTAT, LABFORCE, IND, WTFINL))

cps <- cps |>
  mutate(state = as.character(as_factor(STATEFIP))) |>
  haven::zap_labels() |>
  filter(AGE >= 16, EMPSTAT != 1) |>          # civilians aged 16+
  mutate(in_lf = LABFORCE == 2,
         unemp = EMPSTAT %in% 20:22)

# Weighted rates: unemployment = unemployed / labor force; LFPR = labor force / population
rates <- function(df) {
  summarise(df,
            ur   = sum(WTFINL * unemp) / sum(WTFINL * in_lf),
            lfpr = sum(WTFINL * in_lf) / sum(WTFINL),
            n    = n(),
            .groups = "drop")
}

national_monthly <- cps |> group_by(YEAR, MONTH) |> rates()
state_annual     <- cps |> group_by(state, YEAR) |> rates()

dir.create("data/processed", showWarnings = FALSE)
write.csv(national_monthly, "data/processed/national_monthly.csv", row.names = FALSE)
write.csv(state_annual,     "data/processed/state_annual.csv",     row.names = FALSE)
# Leisure & hospitality share of employment by state, 2019 (pre-pandemic)
# IND 8560-8690: arts/entertainment/recreation, accommodation, food services
lh_share_2019 <- cps |>
  filter(YEAR == 2019, EMPSTAT %in% c(10, 12)) |>   # employed
  group_by(state) |>
  summarise(lh_share = sum(WTFINL * (IND >= 8560 & IND <= 8690)) / sum(WTFINL),
            .groups = "drop")

write.csv(lh_share_2019, "data/processed/lh_share_2019.csv", row.names = FALSE)