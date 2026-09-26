# =============================================================================
# FILE: R/plots.R
# PURPOSE: Creates all the charts and graphs used in the dashboard.
#          Uses ggplot2 to build static plots, then wraps them in Plotly
#          to make them interactive (hover tooltips, zoom, pan).
# =============================================================================

library(ggplot2)
library(plotly)
library(scales)

# -----------------------------------------------------------------------------
# Function: theme_demandsense
# What it does: Defines a consistent visual style for every chart —
#               font sizes, grid lines, background colour, margins.
#               Called inside every plot function so all charts look uniform.
# Output: A ggplot2 theme object
# -----------------------------------------------------------------------------
theme_demandsense <- function() {
  ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      # Titles are handled by the dashboard card headers, so we blank them here
      plot.title    = ggplot2::element_blank(),
      plot.subtitle = ggplot2::element_blank(),

      # Axis label styling
      axis.title.x = ggplot2::element_text(size = 11, face = "bold", color = "#475569",
                                           margin = ggplot2::margin(t = 10)),
      axis.title.y = ggplot2::element_text(size = 11, face = "bold", color = "#475569",
                                           margin = ggplot2::margin(r = 16)),
      axis.text.x  = ggplot2::element_text(size = 10, color = "#64748b"),
      axis.text.y  = ggplot2::element_text(size = 10, color = "#64748b"),

      # Light horizontal grid lines only
      panel.grid.major = ggplot2::element_line(color = "#f1f5f9", linewidth = 0.6),
      panel.grid.minor = ggplot2::element_blank(),

      # No legend by default (each plot can override if needed)
      legend.position = "none",

      # Transparent background so it blends with the dashboard card
      plot.background  = ggplot2::element_rect(fill = "transparent", color = NA),
      panel.background = ggplot2::element_rect(fill = "transparent", color = NA),

      # Spacing around the chart
      plot.margin = ggplot2::margin(t = 10, r = 15, b = 15, l = 15)
    )
}

# -----------------------------------------------------------------------------
# Function: format_plotly
# What it does: Applies common Plotly settings to every interactive chart —
#               tooltip style, margins, and which toolbar buttons to show.
# Input:  p           — a Plotly object
#         show_legend — TRUE/FALSE to show or hide the legend
# Output: The styled Plotly object
# -----------------------------------------------------------------------------
format_plotly <- function(p, show_legend = FALSE) {
  p <- p %>%
    plotly::layout(
      hoverlabel = list(
        bgcolor = "#1e293b",
        font    = list(color = "#ffffff", family = "Plus Jakarta Sans")
      ),
      margin     = list(l = 80, r = 25, t = 20, b = 50),
      showlegend = show_legend
    ) %>%
    plotly::config(
      displayModeBar = "hover",
      displaylogo    = FALSE,
      modeBarButtonsToRemove = c(
        "lasso2d", "select2d", "toggleSpikelines",
        "hoverCompareCartesian", "hoverClosestCartesian"
      )
    )
  return(p)
}

# -----------------------------------------------------------------------------
# Function: plot_revenue_over_time
# What it does: Draws a line chart showing total daily revenue across all
#               dates. An area fill under the line makes the trend easier
#               to read. Hovering shows exact date, revenue, and units.
# Input:  df          — cleaned data frame
#         interactive — if TRUE, return a Plotly chart; if FALSE, plain ggplot
# Output: A ggplot or Plotly chart object
# -----------------------------------------------------------------------------
plot_revenue_over_time <- function(df, interactive = TRUE) {

  # Aggregate all transactions into one revenue total per day
  daily <- df %>%
    dplyr::group_by(date) %>%
    dplyr::summarise(
      revenue = sum(revenue, na.rm = TRUE),
      units   = sum(quantity, na.rm = TRUE),
      .groups = "drop"
    )

  # Empty data guard
  if (nrow(daily) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 1, y = 1, label = "No data available") +
      theme_demandsense()
    return(if (interactive) format_plotly(plotly::ggplotly(p)) else p)
  }

  # Build the chart: area + line + points
  p <- ggplot2::ggplot(daily, ggplot2::aes(x = date, y = revenue)) +
    ggplot2::geom_area(fill = "#3b82f6", alpha = 0.15) +
    ggplot2::geom_line(color = "#2563eb", linewidth = 1.1) +
    ggplot2::geom_point(
      color = "#1d4ed8", size = 1.6, alpha = 0.85,
      ggplot2::aes(text = paste0(
        "Date: ", date,
        "<br>Revenue: Rs ", format(round(revenue), big.mark = ","),
        "<br>Units Sold: ", units
      ))
    ) +
    ggplot2::scale_y_continuous(labels = scales::dollar_format(prefix = "Rs ")) +
    ggplot2::scale_x_date(date_labels = "%b %d", date_breaks = "2 weeks") +
    ggplot2::labs(x = "Date", y = "Daily Revenue (Rs)") +
    theme_demandsense()

  if (interactive) format_plotly(plotly::ggplotly(p, tooltip = "text")) else p
}

# -----------------------------------------------------------------------------
# Function: plot_revenue_by_category
# What it does: Draws a horizontal bar chart showing total revenue per
#               product category. Categories are sorted from lowest to
#               highest so the biggest bar is at the top.
# -----------------------------------------------------------------------------
plot_revenue_by_category <- function(df, interactive = TRUE) {

  # Sum revenue per category
  cat_data <- df %>%
    dplyr::group_by(category) %>%
    dplyr::summarise(
      revenue = sum(revenue, na.rm = TRUE),
      units   = sum(quantity, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::arrange(revenue)

  if (nrow(cat_data) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 1, y = 1, label = "No data available") +
      theme_demandsense()
    return(if (interactive) format_plotly(plotly::ggplotly(p)) else p)
  }

  # Lock the category order for the axis
  cat_data$category <- factor(cat_data$category, levels = cat_data$category)

  p <- ggplot2::ggplot(cat_data, ggplot2::aes(x = category, y = revenue, fill = category)) +
    ggplot2::geom_col(
      width = 0.6, show.legend = FALSE,
      ggplot2::aes(text = paste0(
        "Category: ", category,
        "<br>Revenue: Rs ", format(round(revenue), big.mark = ","),
        "<br>Units: ", units
      ))
    ) +
    ggplot2::coord_flip() +
    ggplot2::scale_fill_brewer(palette = "Blues") +
    ggplot2::scale_y_continuous(labels = scales::dollar_format(prefix = "Rs ")) +
    ggplot2::labs(x = "", y = "Total Revenue (Rs)") +
    theme_demandsense()

  if (interactive) format_plotly(plotly::ggplotly(p, tooltip = "text")) else p
}

# -----------------------------------------------------------------------------
# Function: plot_product_trend
# What it does: Shows the daily units sold for a single product as a
#               combined bar + line chart. Useful for spotting whether a
#               specific product is selling more or less over time.
# Input:  daily_series — the $daily_series tibble from calc_product_performance()
#         product_name — the name of the product (used only if the chart is empty)
# -----------------------------------------------------------------------------
plot_product_trend <- function(daily_series, product_name, interactive = TRUE) {

  if (nrow(daily_series) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 1, y = 1, label = "No sales for this product") +
      theme_demandsense()
    return(if (interactive) format_plotly(plotly::ggplotly(p)) else p)
  }

  p <- ggplot2::ggplot(daily_series, ggplot2::aes(x = date, y = quantity)) +
    ggplot2::geom_col(fill = "#818cf8", alpha = 0.35, width = 0.8) +
    ggplot2::geom_line(color = "#4f46e5", linewidth = 1.2) +
    ggplot2::geom_point(
      color = "#3730a3", size = 2,
      ggplot2::aes(text = paste0(
        "Date: ", date,
        "<br>Units Sold: ", quantity,
        "<br>Revenue: Rs ", format(round(revenue), big.mark = ",")
      ))
    ) +
    ggplot2::scale_x_date(date_labels = "%b %d", date_breaks = "2 weeks") +
    ggplot2::labs(x = "Date", y = "Units Sold") +
    theme_demandsense()

  if (interactive) format_plotly(plotly::ggplotly(p, tooltip = "text")) else p
}

# -----------------------------------------------------------------------------
# Function: plot_product_comparison_chart
# What it does: Draws a horizontal bar chart comparing multiple products
#               side by side on either revenue or units sold.
# Input:  comp_summary — the $summary_table from compare_products()
#         metric       — "revenue" or "units_sold"
# -----------------------------------------------------------------------------
plot_product_comparison_chart <- function(comp_summary, metric = "revenue", interactive = TRUE) {

  if (nrow(comp_summary) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 1, y = 1, label = "Select products to compare") +
      theme_demandsense()
    return(if (interactive) format_plotly(plotly::ggplotly(p)) else p)
  }

  # Pick which column to plot based on the metric argument
  metric_col <- if (metric == "revenue") "total_revenue" else "units_sold"
  y_label    <- if (metric == "revenue") "Total Revenue (Rs)" else "Units Sold"

  p <- ggplot2::ggplot(comp_summary, ggplot2::aes(
    x = reorder(product, .data[[metric_col]]),
    y = .data[[metric_col]],
    fill = product
  )) +
    ggplot2::geom_col(
      width = 0.55, show.legend = FALSE,
      ggplot2::aes(text = paste0(
        "Product: ", product,
        "<br>Revenue: Rs ", format(round(total_revenue), big.mark = ","),
        "<br>Units Sold: ", units_sold,
        "<br>Daily Avg: ", round(avg_daily_units, 1)
      ))
    ) +
    ggplot2::coord_flip() +
    ggplot2::scale_fill_brewer(palette = "Set2") +
    ggplot2::labs(x = "", y = y_label) +
    theme_demandsense()

  # Add currency formatting only when showing revenue
  if (metric == "revenue") {
    p <- p + ggplot2::scale_y_continuous(labels = scales::dollar_format(prefix = "Rs "))
  }

  if (interactive) format_plotly(plotly::ggplotly(p, tooltip = "text")) else p
}

# -----------------------------------------------------------------------------
# Function: plot_weekday_analysis
# What it does: Bar chart of average daily revenue for each day of the week.
#               The highest bar is highlighted in a different colour.
# Input:  dow_data — the $day_of_week tibble from calc_time_analysis()
# -----------------------------------------------------------------------------
plot_weekday_analysis <- function(dow_data, interactive = TRUE) {

  if (nrow(dow_data) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 1, y = 1, label = "No time data") +
      theme_demandsense()
    return(if (interactive) format_plotly(plotly::ggplotly(p)) else p)
  }

  # Flag the peak day for colour highlighting
  max_val <- max(dow_data$avg_revenue, na.rm = TRUE)
  dow_data$is_peak <- (dow_data$avg_revenue == max_val)

  p <- ggplot2::ggplot(dow_data, ggplot2::aes(x = day_of_week, y = avg_revenue, fill = is_peak)) +
    ggplot2::geom_col(
      width = 0.55, show.legend = FALSE,
      ggplot2::aes(text = paste0(
        "Day: ", day_of_week,
        "<br>Avg Daily Revenue: Rs ", format(round(avg_revenue), big.mark = ","),
        "<br>Total Revenue: Rs ", format(round(total_revenue), big.mark = ","),
        "<br>Avg Units: ", round(avg_units, 1)
      ))
    ) +
    ggplot2::scale_fill_manual(values = c("FALSE" = "#94a3b8", "TRUE" = "#0ea5e9")) +
    ggplot2::scale_y_continuous(labels = scales::dollar_format(prefix = "Rs ")) +
    ggplot2::labs(x = "", y = "Average Daily Revenue (Rs)") +
    theme_demandsense()

  if (interactive) format_plotly(plotly::ggplotly(p, tooltip = "text")) else p
}

# -----------------------------------------------------------------------------
# Function: plot_anomalies_timeline
# What it does: Line chart of daily revenue with three horizontal reference
#               lines (mean, upper bound, lower bound). Days that fall outside
#               the bounds are shown as larger, differently coloured dots.
# Input:  anomaly_res — the full list output from detect_anomalies()
# -----------------------------------------------------------------------------
plot_anomalies_timeline <- function(anomaly_res, interactive = TRUE) {

  daily <- anomaly_res$daily

  if (nrow(daily) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 1, y = 1, label = "No anomaly data") +
      theme_demandsense()
    return(if (interactive) format_plotly(plotly::ggplotly(p)) else p)
  }

  p <- ggplot2::ggplot(daily, ggplot2::aes(x = date, y = revenue)) +
    # Revenue line
    ggplot2::geom_line(color = "#cbd5e1", linewidth = 0.9) +
    # Reference lines: mean (dashed), upper bound (red dotted), lower bound (amber dotted)
    ggplot2::geom_hline(yintercept = anomaly_res$mean_rev, linetype = "dashed", color = "#64748b", alpha = 0.8) +
    ggplot2::geom_hline(yintercept = anomaly_res$upper_bound, linetype = "dotted", color = "#ef4444", linewidth = 1) +
    ggplot2::geom_hline(yintercept = anomaly_res$lower_bound, linetype = "dotted", color = "#f59e0b", linewidth = 1) +
    # Data points — colour and size change for anomalies
    ggplot2::geom_point(ggplot2::aes(
      color = anomaly_type, size = is_anomaly,
      text = paste0(
        "Date: ", date, " (", day_of_week, ")",
        "<br>Revenue: Rs ", format(round(revenue), big.mark = ","),
        "<br>Status: ", anomaly_type,
        "<br>Z-score: ", round(z_score, 2)
      )
    )) +
    ggplot2::scale_color_manual(values = c(
      "Normal"     = "#3b82f6",
      "High Spike" = "#ef4444",
      "Low Drop"   = "#f59e0b"
    )) +
    ggplot2::scale_size_manual(values = c("FALSE" = 2, "TRUE" = 4.5), guide = "none") +
    ggplot2::scale_y_continuous(labels = scales::dollar_format(prefix = "Rs ")) +
    ggplot2::scale_x_date(date_labels = "%b %d", date_breaks = "2 weeks") +
    ggplot2::labs(x = "Date", y = "Daily Revenue (Rs)", color = "Classification") +
    theme_demandsense() +
    ggplot2::theme(
      legend.position = "top",
      legend.title = ggplot2::element_text(size = 9, face = "bold", color = "#475569"),
      legend.text  = ggplot2::element_text(size = 9, color = "#64748b")
    )

  if (interactive) format_plotly(plotly::ggplotly(p, tooltip = "text"), show_legend = TRUE) else p
}

# -----------------------------------------------------------------------------
# Function: plot_period_delta_chart
# What it does: Horizontal bar chart showing the percentage change in revenue
#               per product between Period A and Period B. Green bars mean
#               growth, red bars mean decline.
# Input:  change_stats — the full list from analyze_period_change()
# -----------------------------------------------------------------------------
plot_period_delta_chart <- function(change_stats, interactive = TRUE) {

  delta_df <- change_stats$product_delta

  if (is.null(delta_df) || nrow(delta_df) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 1, y = 1, label = "No comparison data") +
      theme_demandsense()
    return(if (interactive) format_plotly(plotly::ggplotly(p)) else p)
  }

  # Cap Inf values for display (can't plot infinite bars)
  # and create a human-readable label for the tooltip
  max_finite <- max(abs(delta_df$rev_pct[is.finite(delta_df$rev_pct)]), 100, na.rm = TRUE)
  cap_value <- max_finite * 1.3  # 30% beyond the biggest finite bar

  delta_df <- delta_df %>%
    dplyr::mutate(
      display_label = dplyr::case_when(
        is.infinite(rev_pct) & rev_pct > 0 ~ "New (no baseline)",
        is.infinite(rev_pct) & rev_pct < 0 ~ "Eliminated",
        TRUE ~ sprintf("%+.1f%%", rev_pct)
      ),
      rev_pct_display = dplyr::case_when(
        is.infinite(rev_pct) & rev_pct > 0 ~ cap_value,
        is.infinite(rev_pct) & rev_pct < 0 ~ -cap_value,
        TRUE ~ rev_pct
      )
    )

  # Flag whether each product grew or shrank
  delta_df$is_positive <- delta_df$rev_pct_display >= 0

  p <- ggplot2::ggplot(delta_df, ggplot2::aes(
    x = reorder(product, rev_pct_display), y = rev_pct_display, fill = is_positive
  )) +
    ggplot2::geom_col(
      width = 0.55, show.legend = FALSE,
      ggplot2::aes(text = paste0(
        "Product: ", product,
        "\n Change: ", display_label,
        "\n Period A: Rs ", format(round(rev_a), big.mark = ","),
        "\n Period B: Rs ", format(round(rev_b), big.mark = ",")
      ))
    ) +
    ggplot2::coord_flip() +
    ggplot2::geom_hline(yintercept = 0, color = "#475569", linewidth = 0.8) +
    ggplot2::scale_fill_manual(values = c("FALSE" = "#ef4444", "TRUE" = "#10b981")) +
    ggplot2::scale_y_continuous(labels = function(x) paste0(x, "%")) +
    ggplot2::labs(x = "", y = "Growth / Decline Rate (%)") +
    theme_demandsense()

  if (interactive) format_plotly(plotly::ggplotly(p, tooltip = "text")) else p
}

# -----------------------------------------------------------------------------
# Function: plot_forecast_chart
# What it does: Combines the last 21 days of actual revenue with a 7-day
#               forecast on the same chart. Actual data is a solid blue line;
#               the forecast is a dashed purple line.
# Input:  historical_df — the cleaned data frame (for recent actuals)
#         forecast_df   — the tibble from calc_simple_forecast()
# -----------------------------------------------------------------------------
plot_forecast_chart <- function(historical_df, forecast_df, interactive = TRUE) {

  if (nrow(historical_df) == 0 || nrow(forecast_df) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 1, y = 1, label = "No forecast data") +
      theme_demandsense()
    return(if (interactive) format_plotly(plotly::ggplotly(p)) else p)
  }

  # Get the most recent 21 days of actual data
  hist_recent <- historical_df %>%
    dplyr::group_by(date) %>%
    dplyr::summarise(revenue = sum(revenue, na.rm = TRUE), .groups = "drop") %>%
    dplyr::arrange(desc(date)) %>%
    dplyr::slice(1:21) %>%
    dplyr::arrange(date) %>%
    dplyr::mutate(type = "Actual")

  # Format the forecast data to match
  fc_formatted <- forecast_df %>%
    dplyr::transmute(date = date, revenue = forecast_revenue, type = "Projected (7-Day)")

  # Create a bridge point so the forecast line connects to the last actual point
  bridge_point <- data.frame(
    date    = max(hist_recent$date),
    revenue = hist_recent$revenue[hist_recent$date == max(hist_recent$date)],
    type    = "Projected (7-Day)"
  )

  # Combine actual + bridge + forecast into one data frame
  combined <- rbind(hist_recent, bridge_point, fc_formatted)

  p <- ggplot2::ggplot(combined, ggplot2::aes(x = date, y = revenue, color = type, group = type)) +
    ggplot2::geom_line(ggplot2::aes(linetype = type), linewidth = 1.1) +
    ggplot2::geom_point(
      size = 2.2,
      ggplot2::aes(text = paste0(
        "Date: ", date,
        "<br>Type: ", type,
        "<br>Revenue: Rs ", format(round(revenue), big.mark = ",")
      ))
    ) +
    ggplot2::scale_color_manual(values = c("Actual" = "#3b82f6", "Projected (7-Day)" = "#8b5cf6")) +
    ggplot2::scale_linetype_manual(values = c("Actual" = "solid", "Projected (7-Day)" = "dashed")) +
    ggplot2::scale_y_continuous(labels = scales::dollar_format(prefix = "Rs ")) +
    ggplot2::scale_x_date(date_labels = "%b %d", date_breaks = "5 days") +
    ggplot2::labs(x = "Date", y = "Daily Revenue (Rs)", color = "", linetype = "") +
    theme_demandsense() +
    ggplot2::theme(
      legend.position = "top",
      legend.title    = ggplot2::element_blank(),
      legend.text     = ggplot2::element_text(size = 9, color = "#64748b")
    )

  if (interactive) format_plotly(plotly::ggplotly(p, tooltip = "text"), show_legend = TRUE) else p
}
