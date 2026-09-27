# 03_figures.R
# Figure 1: national unemployment rate and LFPR over time
# Figure 2: state-by-year unemployment rate heatmap
# Figure 3: leisure & hospitality exposure vs. 2020 unemployment shock

library(dplyr)
library(tidyr)
library(ggplot2)

national <- read.csv("data/processed/national_monthly.csv") |>
  mutate(date = as.Date(sprintf("%d-%02d-01", YEAR, MONTH)))
state <- read.csv("data/processed/state_annual.csv")
lh    <- read.csv("data/processed/lh_share_2019.csv")

# ---- Figure 1: national trends ----
p1 <- national |>
  pivot_longer(c(ur, lfpr), names_to = "measure", values_to = "rate") |>
  mutate(measure = recode(measure,
                          ur   = "Unemployment rate",
                          lfpr = "Labor force participation rate")) |>
  ggplot(aes(date, rate)) +
  geom_line(linewidth = 0.8) +
  facet_wrap(~measure, ncol = 1, scales = "free_y") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(title = "U.S. labor market, 2019-2026",
       subtitle = "Civilians 16+, monthly, not seasonally adjusted, weighted by WTFINL",
       x = NULL, y = NULL,
       caption = "Source: IPUMS CPS basic monthly samples. October 2025 not collected.") +
  theme_minimal(base_size = 12)

# ---- Figure 2: state heatmap ----
state_order <- state |> filter(YEAR == 2020) |> arrange(ur) |> pull(state)

p2 <- state |>
  mutate(year_lab = ifelse(YEAR == 2026, "2026*", as.character(YEAR)),
         state = factor(state, levels = state_order)) |>
  ggplot(aes(year_lab, state, fill = ur)) +
  geom_tile(color = "white") +
  scale_fill_viridis_c(option = "magma", direction = -1,
                       labels = scales::percent_format(accuracy = 1)) +
  labs(title = "Unemployment rate by state and year",
       subtitle = "States ordered by 2020 unemployment rate",
       x = NULL, y = NULL, fill = "Unemployment\nrate",
       caption = "Annual averages of monthly CPS data, weighted by WTFINL.\n*2026 covers Jan-Aug. 2025 excludes October.") +
  theme_minimal(base_size = 10) +
  theme(panel.grid = element_blank())

# ---- Figure 3: leisure & hospitality exposure vs. 2020 shock ----
shock <- state |>
  filter(YEAR %in% c(2019, 2020)) |>
  select(state, YEAR, ur) |>
  pivot_wider(names_from = YEAR, values_from = ur, names_prefix = "ur_") |>
  mutate(ur_change = ur_2020 - ur_2019) |>
  left_join(lh, by = "state")

p3 <- ggplot(shock, aes(lh_share, ur_change)) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed", color = "grey50") +
  geom_point(size = 2) +
  geom_text(aes(label = state), size = 2.8, vjust = -0.8, check_overlap = TRUE) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(title = "States more reliant on leisure & hospitality were hit harder in 2020",
       x = "Leisure & hospitality share of employment, 2019",
       y = "Change in unemployment rate, 2019 to 2020 (pp)",
       caption = "Source: IPUMS CPS basic monthly samples, weighted by WTFINL. Annual averages.") +
  theme_minimal(base_size = 12)

# ---- Save ----
ggsave("output/fig1_national.png",      p1, width = 8, height = 6,  dpi = 300)
ggsave("output/fig2_state_heatmap.png", p2, width = 7, height = 11, dpi = 300)
ggsave("output/fig3_lh_shock.png",      p3, width = 8, height = 6,  dpi = 300)

print(p3)

# ---- Figure 2 (interactive map with year slider) ----
library(plotly)

state_abb <- c(setNames(state.abb, state.name), "District of Columbia" = "DC")

map_df <- state |>
  mutate(code = state_abb[state],
         year_lab = ifelse(YEAR == 2026, "2026*", as.character(YEAR)))

p_map <- plot_geo(map_df, locationmode = "USA-states") |>
  add_trace(
    type = "choropleth",
    locations = ~code, z = ~ur, frame = ~year_lab,
    zmin = min(map_df$ur), zmax = max(map_df$ur),     # same color scale every year
    colors = viridisLite::magma(100, direction = -1),
    text = ~sprintf("<b>%s, %s</b><br>Unemployment rate: %.1f%%<br>LFPR: %.1f%%<br>Sample size: %s",
                    state, year_lab, ur * 100, lfpr * 100, format(n, big.mark = ",")),
    hoverinfo = "text",
    marker = list(line = list(color = "white", width = 0.5)),
    colorbar = list(title = "Unemployment<br>rate", tickformat = ".0%")
  ) |>
  layout(title = "Unemployment rate by state, 2019-2026",
         geo = list(scope = "usa", projection = list(type = "albers usa"))) |>
  animation_opts(frame = 800, redraw = TRUE) |>
  animation_slider(currentvalue = list(prefix = "Year: "))

htmlwidgets::saveWidget(p_map, "output/fig2_state_map_interactive.html",
                        selfcontained = TRUE)
p_map