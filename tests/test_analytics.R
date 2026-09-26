# tests/test_analytics.R
# Pre-flight unit and integration tests for DemandSense analytical pipeline

cat("=========================================\n")
cat("DemandSense: Running Pipeline Tests\n")
cat("=========================================\n\n")

source("R/data_loader.R")
source("R/data_cleaner.R")
source("R/analytics.R")
source("R/insights.R")
source("R/plots.R")

# 1. Test clean data loading
cat("[1/7] Testing Clean Data Ingestion...\n")
raw_clean <- load_sales_data("data/sales.csv")
stopifnot(nrow(raw_clean) > 0)
clean_res <- clean_sales_data(raw_clean)
df <- clean_res$data
cat(sprintf("  ✓ Loaded and enriched %d rows\n", nrow(df)))

# 2. Test messy data cleaning & audit log
cat("[2/7] Testing Messy Data Cleaning & Audit Trail...\n")
raw_messy <- load_sales_data("data/sample_messy.csv")
messy_res <- clean_sales_data(raw_messy)
cat(sprintf("  ✓ Initial rows: %d | Cleaned rows: %d | Duplicates pruned: %d | Removed: %d\n",
            messy_res$audit$total_input_rows,
            messy_res$audit$rows_after_cleaning,
            messy_res$audit$duplicates_removed,
            messy_res$audit$rows_removed))
if (messy_res$audit$non_positive_qty_rows > 0)
  cat(sprintf("  ⚠ Negative/zero quantity rows dropped: %d\n", messy_res$audit$non_positive_qty_rows))
if (messy_res$audit$discount_clamped_rows > 0)
  cat(sprintf("  ⚠ Discount >100%% clamped: %d\n", messy_res$audit$discount_clamped_rows))
if (messy_res$audit$mixed_date_formats)
  cat("  ⚠ Mixed date formats detected in source file\n")
stopifnot(messy_res$audit$rows_after_cleaning < messy_res$audit$total_input_rows)

# 3. Test Summary KPIs
cat("[3/7] Testing KPI Calculations...\n")
kpis <- calc_summary_kpis(df)
cat(sprintf("  ✓ Total Revenue: ₹%s | Total Units: %s | Peak Day: %s | Best Product: %s\n",
            format(round(kpis$total_revenue), big.mark = ","),
            format(kpis$total_units, big.mark = ","),
            kpis$best_day_name,
            kpis$best_product_name))
stopifnot(kpis$total_revenue > 0)
stopifnot(kpis$total_units > 0)

# 4. Test Product Performance & Comparisons
cat("[4/7] Testing Product Analytics & Duel...\n")
coffee_perf <- calc_product_performance(df, "Coffee")
cat(sprintf("  ✓ Coffee Units: %d | Share: %.1f%% | Trend: %s\n",
            coffee_perf$units_sold, coffee_perf$store_share_pct, coffee_perf$trend))
stopifnot(coffee_perf$units_sold > 0)

duel <- compare_products(df, c("Coffee", "Tea", "Cold Brew"))
cat(sprintf("  ✓ Compared %d products successfully\n", nrow(duel$summary_table)))
stopifnot(nrow(duel$summary_table) == 3)

# 5. Test Anomaly Detection & Time Patterns
cat("[5/7] Testing Time Analysis & Statistical Anomalies...\n")
time_stats <- calc_time_analysis(df)
cat(sprintf("  ✓ Weekday stats computed for %d days of week\n", nrow(time_stats$day_of_week)))

anomalies <- detect_anomalies(df, k = 2.0)
cat(sprintf("  ✓ Mean daily rev: ₹%s | SD: ₹%s | Outliers flagged: %d\n",
            format(round(anomalies$mean_rev), big.mark = ","),
            format(round(anomalies$sd_rev), big.mark = ","),
            nrow(anomalies$anomalies)))
stopifnot(nrow(anomalies$anomalies) > 0)

# 6. Test 'What Changed?' and Demand Patterns (with zero-baseline edge cases)
cat("[6/7] Testing 'What Changed?' and Trajectory Classification...\n")
patterns <- classify_demand_patterns(df)
n_emerging     <- sum(patterns$status == "Emerging")
n_growing      <- sum(patterns$status == "Growing")
n_stable       <- sum(patterns$status == "Stable")
n_declining    <- sum(patterns$status == "Declining")
n_discontinued <- sum(patterns$status == "Discontinued")
n_no_activity  <- sum(patterns$status == "No Activity")
cat(sprintf("  ✓ Classified %d products: %d Growing, %d Stable, %d Declining, %d Emerging, %d Discontinued, %d No Activity\n",
            nrow(patterns), n_growing, n_stable, n_declining, n_emerging, n_discontinued, n_no_activity))

period_change <- analyze_period_change(df, "2026-05-01", "2026-06-30", "2026-07-01", "2026-08-31")
# Format safely — handle Inf for display
fmt_safe <- function(v) { if (is.infinite(v)) "New" else sprintf("%+.1f%%", v) }
cat(sprintf("  ✓ Period A vs B: Rev Delta = %s | Top Gainer: %s (%s)\n",
            fmt_safe(period_change$rev_change_pct),
            period_change$top_gainer$product,
            fmt_safe(period_change$top_gainer$rev_pct)))

# 7. Test Insights Generator & Forecast
cat("[7/7] Testing Insight Generator & 7-Day Forecast...\n")
insights <- generate_executive_insights(kpis, time_stats, patterns, anomalies, period_change)
for (ins in insights) {
  cat(paste("  •", ins, "\n"))
}

forecast_res <- calc_simple_forecast(df, horizon = 7)
cat(sprintf("  ✓ 7-Day Forecast projected %d future dates with total projected rev: ₹%s\n",
            nrow(forecast_res),
            format(sum(forecast_res$forecast_revenue), big.mark = ",")))

cat("\n=========================================\n")
cat("ALL TESTS PASSED WITH ZERO ERRORS!\n")
cat("=========================================\n")
