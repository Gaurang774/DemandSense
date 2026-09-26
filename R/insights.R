# =============================================================================
# FILE: R/insights.R
# PURPOSE: Generates human-readable insight sentences from the analytics
#          results. These are displayed on the dashboard as key findings.
#          The logic is purely rule-based — it checks thresholds and builds
#          formatted text strings. No machine learning is involved.
# =============================================================================

# -----------------------------------------------------------------------------
# Function: generate_executive_insights
# What it does: Takes the output from all analytics functions and converts
#               the numbers into plain English sentences that summarise what
#               is happening in the data. Each "if" block checks a specific
#               condition and, if true, adds a sentence to the results.
#
# Input:  kpis         — list from calc_summary_kpis()
#         time_stats   — list from calc_time_analysis()       (optional)
#         patterns     — tibble from classify_demand_patterns() (optional)
#         anomalies    — list from detect_anomalies()          (optional)
#         change_stats — list from analyze_period_change()     (optional)
# Output: A character vector where each element is one insight sentence
# -----------------------------------------------------------------------------
generate_executive_insights <- function(kpis,
                                        time_stats   = NULL,
                                        patterns     = NULL,
                                        anomalies    = NULL,
                                        change_stats = NULL) {

  # Start with an empty list; we will append sentences as we go
  insights <- character()

  # ---- Insight 1: Best-selling product ----
  # If we know the best product, state its name, revenue, and share
  if (!is.null(kpis$best_product_name) && kpis$best_product_name != "N/A") {

    # Calculate what percentage of total revenue this product accounts for
    pct_share <- if (kpis$total_revenue > 0) {
      (kpis$best_product_revenue / kpis$total_revenue) * 100
    } else {
      0
    }

    insights <- c(insights, sprintf(
      "**Top Revenue Driver:** **%s** is your #1 product, generating **Rs %s** (%.1f%% of overall store revenue).",
      kpis$best_product_name,
      format(round(kpis$best_product_revenue), big.mark = ","),
      pct_share
    ))
  }

  # ---- Insight 2: Best day of the week ----
  # Show which weekday has the highest average revenue and how much above average it is
  if (!is.null(kpis$best_day_name) && kpis$best_day_name != "N/A" && kpis$avg_daily_revenue > 0) {

    # "Lift" = how much higher the best day is compared to the overall daily average
    day_lift <- ((kpis$best_day_avg_rev - kpis$avg_daily_revenue) / kpis$avg_daily_revenue) * 100

    insights <- c(insights, sprintf(
      "**Peak Sales Day:** **%s** produces the highest demand, averaging **Rs %s/day** (%.1f%% above the daily average).",
      kpis$best_day_name,
      format(round(kpis$best_day_avg_rev), big.mark = ","),
      day_lift
    ))
  }

  # ---- Insight 3: Growing, emerging, and declining products ----
  # If we have demand pattern data, highlight emerging, fastest grower and steepest decliner
  if (!is.null(patterns) && nrow(patterns) > 0) {

    emerging <- patterns %>% dplyr::filter(status == "Emerging")
    growing  <- patterns %>% dplyr::filter(status == "Growing")
    declining <- patterns %>% dplyr::filter(status == "Declining")
    discontinued <- patterns %>% dplyr::filter(status == "Discontinued")

    # Newly emerged products (were absent in early period, appeared in recent)
    if (nrow(emerging) > 0) {
      emerging_names <- paste(emerging$product, collapse = ", ")
      insights <- c(insights, sprintf(
        "**Emerging Demand:** **%s** — %s not present in the early period but appeared recently (%.1f avg daily units).",
        emerging_names,
        ifelse(nrow(emerging) == 1, "was", "were"),
        if (nrow(emerging) == 1) emerging$recent_avg[1] else mean(emerging$recent_avg)
      ))
    }

    # Fastest growing product (with a calculable percentage)
    if (nrow(growing) > 0) {
      top_grower <- growing[1, ]
      insights <- c(insights, sprintf(
        "**Fastest Growing Item:** **%s** experienced a **+%.1f%%** surge in recent daily units sold.",
        top_grower$product, top_grower$change_pct
      ))
    }

    # Steepest declining product
    if (nrow(declining) > 0) {
      top_decliner <- declining[nrow(declining), ]
      insights <- c(insights, sprintf(
        "**Demand Contraction Alert:** **%s** demand declined by **%.1f%%** between early and recent periods.",
        top_decliner$product, abs(top_decliner$change_pct)
      ))
    }

    # Discontinued products (had demand in early period, dropped to zero)
    if (nrow(discontinued) > 0) {
      disc_names <- paste(discontinued$product, collapse = ", ")
      insights <- c(insights, sprintf(
        "**Discontinued Demand:** **%s** had sales in the early period but dropped to zero recently.",
        disc_names
      ))
    }
  }

  # ---- Insight 4: Statistical anomalies (unusual days) ----
  if (!is.null(anomalies) && !is.null(anomalies$anomalies) && nrow(anomalies$anomalies) > 0) {

    spikes <- anomalies$anomalies %>% dplyr::filter(anomaly_type == "High Spike")
    drops  <- anomalies$anomalies %>% dplyr::filter(anomaly_type == "Low Drop")

    # Report the biggest spike
    if (nrow(spikes) > 0) {
      max_spike <- spikes %>% dplyr::arrange(desc(revenue)) %>% dplyr::slice(1)
      insights <- c(insights, sprintf(
        "**Unusual Sales Spike:** An abnormal revenue surge of **Rs %s** was recorded on **%s** (%s), exceeding the upper statistical boundary.",
        format(round(max_spike$revenue), big.mark = ","),
        as.character(max_spike$date), max_spike$day_of_week
      ))
    }

    # Report the biggest drop
    if (nrow(drops) > 0) {
      min_drop <- drops %>% dplyr::arrange(revenue) %>% dplyr::slice(1)
      insights <- c(insights, sprintf(
        "**Unusual Sales Drop:** An unexpected dip to **Rs %s** occurred on **%s** (%s), falling below statistical thresholds.",
        format(round(min_drop$revenue), big.mark = ","),
        as.character(min_drop$date), min_drop$day_of_week
      ))
    }

  } else if (!is.null(anomalies)) {
    # If the anomaly detector ran but found nothing unusual
    insights <- c(insights,
      "**Operational Stability:** Daily sales consistency is normal with zero outlier spikes or drops outside standard bounds."
    )
  }

  # ---- Insight 5: Period-over-period comparison ----
  # If the user compared two time periods, state how revenue changed
  if (!is.null(change_stats) && !is.null(change_stats$rev_change_pct)) {
    direction <- if (change_stats$rev_change_pct >= 0) "increased by" else "decreased by"

    insights <- c(insights, sprintf(
      "**Period Delta:** Revenue %s **%.1f%%** (Rs %s vs Rs %s) between the two compared horizons.",
      direction,
      abs(change_stats$rev_change_pct),
      format(round(change_stats$rev_a), big.mark = ","),
      format(round(change_stats$rev_b), big.mark = ",")
    ))
  }

  # If no insights could be generated, return a fallback message
  if (length(insights) == 0) {
    insights <- c("Filtered dataset is too narrow to extract high-confidence business insights.")
  }

  return(insights)
}
