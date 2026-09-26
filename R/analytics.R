# =============================================================================
# FILE: R/analytics.R
# PURPOSE: Contains all the statistical calculation functions used in the
#          DemandSense dashboard. Each function takes a cleaned data frame
#          and returns computed metrics (KPIs, trends, anomalies, etc.).
# =============================================================================

library(dplyr)
library(tidyr)

# -----------------------------------------------------------------------------
# Function: calc_summary_kpis
# What it does: Calculates the top-level numbers shown on the dashboard
#               home page — total revenue, total units sold, best product,
#               best day of the week, etc.
# Input:  df — the cleaned and enriched sales data frame
# Output: A named list of KPI values
# -----------------------------------------------------------------------------
calc_summary_kpis <- function(df) {

  # If the data is empty, return all zeros / placeholders
  if (nrow(df) == 0) {
    return(list(
      total_revenue = 0,
      total_units = 0,
      avg_daily_revenue = 0,
      best_product_revenue = "N/A",
      best_product_name = "N/A",
      best_day_name = "N/A",
      best_day_avg_rev = 0,
      total_transactions = 0,
      total_days = 0
    ))
  }

  # --- Basic totals ---
  total_rev   <- sum(df$revenue, na.rm = TRUE)
  total_units <- sum(df$quantity, na.rm = TRUE)

  # Number of unique calendar days in the data
  n_days <- length(unique(df$date))

  # Average revenue per day = total revenue / number of days
  avg_daily_rev <- if (n_days > 0) total_rev / n_days else 0

  # --- Find the best-selling product (by revenue) ---
  # Group all rows by product, sum their revenue, then pick the top one
  prod_summary <- df %>%
    group_by(product) %>%
    summarise(rev = sum(revenue, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(rev))

  best_prod     <- if (nrow(prod_summary) > 0) prod_summary$product[1] else "N/A"
  best_prod_rev <- if (nrow(prod_summary) > 0) prod_summary$rev[1] else 0

  # --- Find the best day of the week (by average daily revenue) ---
  # First get total revenue per calendar date, then average by weekday
  dow_summary <- df %>%
    group_by(date, day_of_week) %>%
    summarise(day_rev = sum(revenue, na.rm = TRUE), .groups = "drop") %>%
    group_by(day_of_week) %>%
    summarise(avg_dow_rev = mean(day_rev, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(avg_dow_rev))

  best_dow     <- if (nrow(dow_summary) > 0) as.character(dow_summary$day_of_week[1]) else "N/A"
  best_dow_val <- if (nrow(dow_summary) > 0) dow_summary$avg_dow_rev[1] else 0

  # Return everything as a named list
  return(list(
    total_revenue       = total_rev,
    total_units         = total_units,
    avg_daily_revenue   = avg_daily_rev,
    best_product_name   = best_prod,
    best_product_revenue = best_prod_rev,
    best_day_name       = best_dow,
    best_day_avg_rev    = best_dow_val,
    total_transactions  = nrow(df),
    total_days          = n_days
  ))
}

# -----------------------------------------------------------------------------
# Function: calc_product_performance
# What it does: Gives detailed stats for one specific product — total units,
#               total revenue, daily average, share of store revenue, and
#               whether the product is trending up, down, or stable.
# Input:  df           — full cleaned data frame
#         product_name — name of the product to analyse (string)
# Output: A named list with metrics + a daily time-series table
# -----------------------------------------------------------------------------
calc_product_performance <- function(df, product_name) {

  # Filter to rows for this product only
  p_df <- df %>% filter(product == product_name)

  # If no data for this product, return empty results
  if (nrow(p_df) == 0) {
    return(list(
      product = product_name, units_sold = 0, revenue = 0,
      avg_daily_sales = 0, store_share_pct = 0,
      trend = "Insufficient Data", daily_series = tibble::tibble()
    ))
  }

  # Basic totals for this product
  total_p_units <- sum(p_df$quantity, na.rm = TRUE)
  total_p_rev   <- sum(p_df$revenue, na.rm = TRUE)

  # What percentage of the whole store's revenue comes from this product?
  total_store_rev <- sum(df$revenue, na.rm = TRUE)
  share_pct <- if (total_store_rev > 0) (total_p_rev / total_store_rev) * 100 else 0

  # Aggregate this product's sales by day
  daily <- p_df %>%
    group_by(date) %>%
    summarise(
      quantity = sum(quantity, na.rm = TRUE),
      revenue  = sum(revenue, na.rm = TRUE),
      .groups  = "drop"
    ) %>%
    arrange(date)

  n_days    <- nrow(daily)
  avg_daily <- if (n_days > 0) total_p_units / n_days else 0

  # --- Trend detection ---
  # Split the daily series into first half and second half.
  # If the second half sells more, the trend is "Increasing".
  if (n_days >= 4) {
    half       <- floor(n_days / 2)
    early_avg  <- mean(daily$quantity[1:half], na.rm = TRUE)
    recent_avg <- mean(daily$quantity[(half + 1):n_days], na.rm = TRUE)

    # Handle zero-baseline cases: percentage change from 0 is undefined
    if (early_avg == 0 && recent_avg > 0) {
      trend_label <- "Emerging (New Demand)"
    } else if (early_avg > 0 && recent_avg == 0) {
      trend_label <- "Discontinued (-100%)"
    } else if (early_avg == 0 && recent_avg == 0) {
      trend_label <- "No Activity"
    } else {
      pct_diff <- ((recent_avg - early_avg) / early_avg) * 100
      if (pct_diff > 8) {
        trend_label <- sprintf("Increasing (+%.1f%%)", pct_diff)
      } else if (pct_diff < -8) {
        trend_label <- sprintf("Decreasing (%.1f%%)", pct_diff)
      } else {
        trend_label <- sprintf("Stable (%+.1f%%)", pct_diff)
      }
    }
  } else {
    trend_label <- "Neutral"
  }

  return(list(
    product         = product_name,
    category        = unique(p_df$category)[1],
    units_sold      = total_p_units,
    revenue         = total_p_rev,
    avg_daily_sales = avg_daily,
    store_share_pct = share_pct,
    trend           = trend_label,
    daily_series    = daily
  ))
}

# -----------------------------------------------------------------------------
# Function: compare_products
# What it does: Given a list of product names, this function builds a
#               side-by-side comparison table showing units, revenue,
#               average price, and share of store revenue for each product.
# Input:  df            — full cleaned data frame
#         product_names — character vector of products to compare
# Output: A list with $summary_table and $daily_comparison
# -----------------------------------------------------------------------------
compare_products <- function(df, product_names) {

  if (length(product_names) == 0) {
    return(list(summary_table = tibble::tibble(), series = tibble::tibble()))
  }

  # Keep only the selected products
  sub_df <- df %>% filter(product %in% product_names)
  total_store_rev <- sum(df$revenue, na.rm = TRUE)
  total_days      <- max(1, length(unique(df$date)))

  # Build a summary row per product
  summary_tbl <- sub_df %>%
    group_by(product, category) %>%
    summarise(
      units_sold        = sum(quantity, na.rm = TRUE),
      total_revenue     = sum(revenue, na.rm = TRUE),
      avg_price         = mean(unit_price, na.rm = TRUE),
      avg_daily_units   = sum(quantity, na.rm = TRUE) / total_days,
      avg_daily_revenue = sum(revenue, na.rm = TRUE) / total_days,
      revenue_share     = if (total_store_rev > 0) (sum(revenue, na.rm = TRUE) / total_store_rev) * 100 else 0,
      .groups = "drop"
    ) %>%
    arrange(desc(total_revenue))

  # Daily time-series for overlay charts
  daily_comp <- sub_df %>%
    group_by(date, product) %>%
    summarise(
      revenue  = sum(revenue, na.rm = TRUE),
      quantity = sum(quantity, na.rm = TRUE),
      .groups  = "drop"
    ) %>%
    arrange(date)

  return(list(summary_table = summary_tbl, daily_comparison = daily_comp))
}

# -----------------------------------------------------------------------------
# Function: calc_time_analysis
# What it does: Analyses how demand varies by time — by day of the week
#               (e.g. Mondays vs Fridays) and by month (e.g. Jan vs Feb).
# Input:  df — cleaned data frame
# Output: A list with $day_of_week and $monthly summary tables
# -----------------------------------------------------------------------------
calc_time_analysis <- function(df) {

  if (nrow(df) == 0) return(list())

  # --- Day of week analysis ---
  # Step 1: Get total revenue and quantity per calendar date
  # Step 2: Average those daily totals by weekday name
  dow_agg <- df %>%
    group_by(date, day_of_week) %>%
    summarise(
      daily_rev = sum(revenue, na.rm = TRUE),
      daily_qty = sum(quantity, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    group_by(day_of_week) %>%
    summarise(
      avg_revenue   = mean(daily_rev, na.rm = TRUE),
      total_revenue = sum(daily_rev, na.rm = TRUE),
      avg_units     = mean(daily_qty, na.rm = TRUE),
      total_units   = sum(daily_qty, na.rm = TRUE),
      days_recorded = n(),
      .groups = "drop"
    ) %>%
    arrange(day_of_week)

  # --- Monthly analysis ---
  # Group by year-month and compute totals
  month_agg <- df %>%
    group_by(year_month, month) %>%
    summarise(
      total_revenue     = sum(revenue, na.rm = TRUE),
      total_units       = sum(quantity, na.rm = TRUE),
      active_days       = length(unique(date)),
      avg_daily_revenue = total_revenue / active_days,
      .groups = "drop"
    ) %>%
    arrange(year_month)

  return(list(day_of_week = dow_agg, monthly = month_agg))
}

# -----------------------------------------------------------------------------
# Function: classify_demand_patterns
# What it does: For every product, compares sales in the first half of the
#               date range to the second half. Classifies each product as
#               "Growing", "Stable", or "Declining" based on whether the
#               change exceeds +/- 10%.
# Input:  df — cleaned data frame
# Output: A tibble with one row per product showing old average, new average,
#         percentage change, and a status label
# -----------------------------------------------------------------------------
classify_demand_patterns <- function(df) {

  # Get all unique dates in order
  dates <- sort(unique(df$date))

  # Need at least 4 days of data to split meaningfully
  if (length(dates) < 4) {
    return(tibble::tibble(
      product = character(), category = character(),
      early_avg_daily = numeric(), recent_avg_daily = numeric(),
      change_pct = numeric(), status = character()
    ))
  }

  # Split the date range into two halves
  mid_idx      <- floor(length(dates) / 2)
  early_dates  <- dates[1:mid_idx]
  recent_dates <- dates[(mid_idx + 1):length(dates)]

  early_days_count  <- length(early_dates)
  recent_days_count <- length(recent_dates)

  # Sum quantity per product in each half
  early_p <- df %>%
    filter(date %in% early_dates) %>%
    group_by(product, category) %>%
    summarise(early_units = sum(quantity, na.rm = TRUE), .groups = "drop")

  recent_p <- df %>%
    filter(date %in% recent_dates) %>%
    group_by(product, category) %>%
    summarise(recent_units = sum(quantity, na.rm = TRUE), .groups = "drop")

  # Join the two halves and compute percentage change
  merged <- full_join(early_p, recent_p, by = c("product", "category")) %>%
    mutate(
      early_units  = replace_na(early_units, 0),
      recent_units = replace_na(recent_units, 0),
      early_avg    = early_units / early_days_count,
      recent_avg   = recent_units / recent_days_count,
      # Percentage change: handle zero-baseline cases properly
      # (division by zero is mathematically undefined, not 0%)
      change_pct   = case_when(
        early_avg == 0 & recent_avg == 0 ~ 0,       # No activity in either period
        early_avg == 0 & recent_avg > 0  ~ Inf,      # New/emerging demand (undefined %)
        early_avg > 0  & recent_avg == 0 ~ -100,     # Completely stopped
        TRUE ~ ((recent_avg - early_avg) / early_avg) * 100
      ),
      status       = case_when(
        early_avg == 0 & recent_avg > 0  ~ "Emerging",      # New demand appeared
        early_avg > 0  & recent_avg == 0 ~ "Discontinued",  # Demand vanished
        early_avg == 0 & recent_avg == 0 ~ "No Activity",   # Never sold in either half
        change_pct > 10                  ~ "Growing",
        change_pct < -10                 ~ "Declining",
        TRUE                             ~ "Stable"
      )
    ) %>%
    # Sort: Emerging first, then by change_pct descending, Discontinued/No Activity last
    arrange(desc(status == "Emerging"), desc(change_pct))

  return(merged)
}

# -----------------------------------------------------------------------------
# Function: detect_anomalies
# What it does: Finds unusual days where total revenue was much higher or
#               lower than normal. Uses the "mean +/- k * standard deviation"
#               rule (like a Z-score test). Days outside the band are flagged.
# Input:  df — cleaned data frame
#         k  — how many standard deviations away counts as unusual (default 2)
# Output: A list with $daily (all days with flags), $anomalies (unusual days
#         only), and the computed mean / SD / boundaries
# -----------------------------------------------------------------------------
detect_anomalies <- function(df, k = 2.0) {

  if (nrow(df) == 0) {
    return(list(
      daily = tibble::tibble(), anomalies = tibble::tibble(),
      mean_rev = 0, sd_rev = 0, upper_bound = 0, lower_bound = 0
    ))
  }

  # Step 1: Aggregate all transactions into one row per day
  daily <- df %>%
    group_by(date) %>%
    summarise(
      revenue     = sum(revenue, na.rm = TRUE),
      quantity    = sum(quantity, na.rm = TRUE),
      day_of_week = as.character(day_of_week[1]),
      .groups     = "drop"
    ) %>%
    arrange(date)

  # Step 2: Calculate the average (mean) and spread (standard deviation)
  mean_rev <- mean(daily$revenue, na.rm = TRUE)
  sd_rev   <- sd(daily$revenue, na.rm = TRUE)
  if (is.na(sd_rev) || sd_rev == 0) sd_rev <- 1

  # Step 3: Set the upper and lower boundaries
  upper_bound <- mean_rev + (k * sd_rev)
  lower_bound <- max(0, mean_rev - (k * sd_rev))

  # Step 4: Flag each day as normal, high spike, or low drop
  daily <- daily %>%
    mutate(
      z_score      = (revenue - mean_rev) / sd_rev,
      is_anomaly   = (revenue > upper_bound) | (revenue < lower_bound),
      anomaly_type = case_when(
        revenue > upper_bound ~ "High Spike",
        revenue < lower_bound ~ "Low Drop",
        TRUE                  ~ "Normal"
      )
    )

  anomalies_only <- daily %>% filter(is_anomaly)

  return(list(
    daily = daily, anomalies = anomalies_only,
    mean_rev = mean_rev, sd_rev = sd_rev,
    upper_bound = upper_bound, lower_bound = lower_bound
  ))
}

# -----------------------------------------------------------------------------
# Function: analyze_period_change
# What it does: Compares two user-defined time periods (Period A vs Period B).
#               Shows how total revenue and units changed, and which products
#               gained or lost the most between the two periods.
# Input:  df      — cleaned data frame
#         start_a, end_a — date range of period A
#         start_b, end_b — date range of period B
# Output: A list of summary stats and a product-by-product change table
# -----------------------------------------------------------------------------
analyze_period_change <- function(df, start_a, end_a, start_b, end_b) {

  # Filter data for each period
  df_a <- df %>% filter(date >= as.Date(start_a) & date <= as.Date(end_a))
  df_b <- df %>% filter(date >= as.Date(start_b) & date <= as.Date(end_b))

  # Compute totals for each period
  rev_a   <- sum(df_a$revenue, na.rm = TRUE)
  rev_b   <- sum(df_b$revenue, na.rm = TRUE)
  units_a <- sum(df_a$quantity, na.rm = TRUE)
  units_b <- sum(df_b$quantity, na.rm = TRUE)
  days_a  <- max(1, length(unique(df_a$date)))
  days_b  <- max(1, length(unique(df_b$date)))

  # Percentage change between the two periods
  # Handle zero-baseline: percentage change from 0 is undefined
  rev_change_pct <- case_when(
    rev_a == 0 & rev_b == 0 ~ 0,
    rev_a == 0 & rev_b > 0  ~ Inf,
    rev_a == 0 & rev_b < 0  ~ -Inf,
    TRUE ~ ((rev_b - rev_a) / rev_a) * 100
  )
  units_change_pct <- case_when(
    units_a == 0 & units_b == 0 ~ 0,
    units_a == 0 & units_b > 0  ~ Inf,
    TRUE ~ ((units_b - units_a) / units_a) * 100
  )

  # --- Product-level breakdown ---
  p_a <- df_a %>%
    group_by(product) %>%
    summarise(rev_a = sum(revenue, na.rm = TRUE), units_a = sum(quantity, na.rm = TRUE), .groups = "drop")

  p_b <- df_b %>%
    group_by(product) %>%
    summarise(rev_b = sum(revenue, na.rm = TRUE), units_b = sum(quantity, na.rm = TRUE), .groups = "drop")

  # Join and calculate differences with proper zero-baseline handling
  p_comp <- full_join(p_a, p_b, by = "product") %>%
    mutate(
      rev_a     = replace_na(rev_a, 0),
      rev_b     = replace_na(rev_b, 0),
      units_a   = replace_na(units_a, 0),
      units_b   = replace_na(units_b, 0),
      rev_diff  = rev_b - rev_a,
      # Proper zero-baseline: 0→0 is 0% change, not 100%
      rev_pct   = case_when(
        rev_a == 0 & rev_b == 0 ~ 0,
        rev_a == 0 & rev_b > 0  ~ Inf,
        rev_a == 0 & rev_b < 0  ~ -Inf,
        TRUE ~ ((rev_b - rev_a) / rev_a) * 100
      ),
      units_diff = units_b - units_a,
      units_pct = case_when(
        units_a == 0 & units_b == 0 ~ 0,
        units_a == 0 & units_b > 0  ~ Inf,
        TRUE ~ ((units_b - units_a) / units_a) * 100
      )
    ) %>%
    arrange(desc(rev_pct))

  # Identify the biggest winner and biggest loser
  # Filter out products with zero change in both periods (no real movement)
  meaningful <- p_comp %>% filter(rev_diff != 0)
  top_gain      <- if (nrow(meaningful) > 0) meaningful[1, ] else if (nrow(p_comp) > 0) p_comp[1, ] else NULL
  steepest_drop <- if (nrow(meaningful) > 0) meaningful[nrow(meaningful), ] else if (nrow(p_comp) > 0) p_comp[nrow(p_comp), ] else NULL

  return(list(
    rev_a = rev_a, rev_b = rev_b, rev_change_pct = rev_change_pct,
    units_a = units_a, units_b = units_b, units_change_pct = units_change_pct,
    days_a = days_a, days_b = days_b,
    product_delta = p_comp,
    top_gainer = top_gain, biggest_decline = steepest_drop
  ))
}

# -----------------------------------------------------------------------------
# Function: calc_simple_forecast
# What it does: Predicts the next N days of revenue using a simple method:
#               1. Calculate the average revenue for each weekday (Mon-Sun)
#                  from historical data.
#               2. Adjust that average up or down based on whether the most
#                  recent 14 days were stronger or weaker than the overall mean.
#               3. Apply each weekday's adjusted average to the future dates.
# Input:  df      — cleaned data frame
#         horizon — how many future days to forecast (default 7)
# Output: A tibble with columns: date, day_of_week, forecast_revenue,
#         forecast_units
# -----------------------------------------------------------------------------
calc_simple_forecast <- function(df, horizon = 7) {

  if (nrow(df) == 0) return(tibble::tibble())

  # The forecast starts the day after the last date in our data
  max_date     <- max(df$date, na.rm = TRUE)
  future_dates <- seq.Date(max_date + 1, max_date + horizon, by = "day")

  # --- Build weekday profiles ---
  # Average revenue and units sold for each weekday (Monday, Tuesday, etc.)
  dow_profiles <- df %>%
    group_by(date, day_of_week) %>%
    summarise(
      daily_rev = sum(revenue, na.rm = TRUE),
      daily_qty = sum(quantity, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    group_by(day_of_week) %>%
    summarise(
      profile_rev = mean(daily_rev, na.rm = TRUE),
      profile_qty = mean(daily_qty, na.rm = TRUE),
      .groups = "drop"
    )

  # --- Trend adjustment ---
  # Compare the last 14 days' average to the overall average.
  # If recent sales are higher, scale the forecast up (and vice versa).
  recent_cutoff <- max_date - 14
  overall_mean  <- mean(df$revenue, na.rm = TRUE)
  recent_mean   <- mean(df$revenue[df$date >= recent_cutoff], na.rm = TRUE)

  # Clamp the ratio between 0.7 and 1.3 to avoid extreme swings
  trend_ratio <- if (overall_mean > 0) pmax(0.7, pmin(1.3, recent_mean / overall_mean)) else 1.0

  # --- Generate the forecast table ---
  forecast_tbl <- tibble::tibble(
    date        = future_dates,
    day_of_week = factor(weekdays(future_dates), levels = levels(df$day_of_week))
  ) %>%
    left_join(dow_profiles, by = "day_of_week") %>%
    mutate(
      forecast_revenue = round(profile_rev * trend_ratio),
      forecast_units   = as.integer(round(profile_qty * trend_ratio))
    )

  return(forecast_tbl)
}
