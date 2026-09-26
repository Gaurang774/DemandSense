# =============================================================================
# FILE: app.R
# PURPOSE: This is the main entry point for the DemandSense Shiny application.
#          It defines two things:
#          1. The UI (User Interface) — what the user sees (layout, tabs, buttons)
#          2. The Server — the behind-the-scenes logic that reacts to user
#             actions and generates charts, tables, and insights.
# =============================================================================

# --- Load required R packages ---
library(shiny)     # Core web-app framework
library(bslib)     # Bootstrap 5 theming for modern UI
library(dplyr)     # Data manipulation (filter, group, summarise)
library(tidyr)     # Reshaping data (replace_na, pivot)
library(readr)     # Fast CSV reading
library(ggplot2)   # Static chart creation
library(plotly)    # Makes ggplot charts interactive (hover, zoom)
library(DT)        # Renders interactive data tables
library(scales)    # Number formatting (currency, percentages)

# --- Load our custom R modules ---
# Each file contains a specific set of functions (see their individual headers)
source("R/data_loader.R")    # Reads the CSV file
source("R/data_cleaner.R")   # Cleans and validates the raw data
source("R/analytics.R")      # Calculates KPIs, trends, anomalies
source("R/insights.R")       # Generates human-readable insight sentences
source("R/plots.R")          # Creates all charts and graphs

# --- Define the visual theme for the app ---
# Uses Bootstrap 5 with the "flatly" colour scheme and Google's Plus Jakarta Sans font
app_theme <- bslib::bs_theme(
  version      = 5,
  bootswatch   = "flatly",
  primary      = "#2563eb",
  base_font    = bslib::font_google("Plus Jakarta Sans"),
  heading_font = bslib::font_google("Plus Jakarta Sans")
)

# =============================================================================
# SECTION: USER INTERFACE (UI)
# What it does: Defines the entire layout — the navigation bar at the top,
#               the sidebar with filters on the left, and the six content tabs.
# =============================================================================
ui <- bslib::page_navbar(
  theme = app_theme,

  # --- Navbar title with logo ---
  title = div(
    class = "navbar-brand d-flex align-items-center",
    tags$img(src = "logo.png", height = "36",
             style = "margin-right: 12px; border-radius: 6px;", alt = "DemandSense"),
    tags$span(style = "font-weight: 800; font-size: 1.35rem; color: #ffffff; letter-spacing: -0.03em;",
              "DemandSense"),
    tags$span(class = "badge-pill ms-2", "Sales & Demand Analytics")
  ),
  id = "nav_tabs",

  # --- Include the external CSS stylesheet ---
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
    tags$style(HTML(paste(readLines("www/style.css", warn = FALSE), collapse = "\n")))
  ),

  # ---------------------------------------------------------------------------
  # Sidebar: Global Filters
  # What it does: Lets the user narrow down the data by date range, category,
  #               or switch between different datasets (clean, messy, or upload)
  # ---------------------------------------------------------------------------
  sidebar = bslib::sidebar(
    width = 300,
    div(class = "sidebar-title", "Global Filters"),

    # Date range picker — dynamically set from the data
    uiOutput("ui_date_filter"),

    # Category multi-select dropdown
    uiOutput("ui_category_filter"),

    tags$hr(style = "margin: 1rem 0; border-color: var(--border-subtle);"),

    # Button to reset all filters to their default values
    actionButton("btn_reset_filters", "Reset Filters",
                 class = "btn btn-outline-secondary btn-sm w-100 mb-2"),

    tags$hr(style = "margin: 1rem 0; border-color: var(--border-subtle);"),

    # Dataset selector — choose which CSV file to load
    div(
      style = "font-size: 0.85rem; font-weight: 700; color: #475569; margin-bottom: 0.5rem;",
      "Dataset Selection"
    ),
    selectInput(
      "dataset_choice",
      label = NULL,
      choices = c(
        "Standard Cafe Data (1,230 rows)" = "clean",
        "Messy Data (Dirty Test Case)"    = "messy",
        "Upload Custom CSV"               = "upload"
      ),
      selected = "clean"
    ),

    # Show file upload widget only when "Upload Custom CSV" is selected
    conditionalPanel(
      condition = "input.dataset_choice == 'upload'",
      fileInput("user_file", "Choose CSV File", accept = c(".csv"))
    ),

    # Audit trail badge — shows how many rows were cleaned
    uiOutput("ui_audit_badge")
  ),

  # ---------------------------------------------------------------------------
  # Tab 1: Executive Overview
  # What it does: Shows the top-level KPIs (total revenue, units, best product),
  #               auto-generated business insights, and two overview charts.
  # ---------------------------------------------------------------------------
  bslib::nav_panel(
    title = "Executive Overview",
    div(
      style = "padding: 0.5rem 0;",

      # KPI value cards (revenue, units, top product, peak day)
      uiOutput("ui_kpi_cards"),

      # Natural language insights generated from the data
      uiOutput("ui_insight_panel"),

      # Charts row: revenue over time + revenue by category
      fluidRow(
        column(
          width = 7,
          div(
            class = "analytics-card",
            div(class = "card-title-custom", "Daily Revenue Trajectory"),
            div(class = "card-subtitle-custom", "Interactive time-series of total sales performance"),
            plotlyOutput("plot_revenue_time", height = "360px")
          )
        ),
        column(
          width = 5,
          div(
            class = "analytics-card",
            div(class = "card-title-custom", "Revenue by Category"),
            div(class = "card-subtitle-custom", "Contribution ranking across product groups"),
            plotlyOutput("plot_revenue_cat", height = "360px")
          )
        )
      )
    )
  ),

  # ---------------------------------------------------------------------------
  # Tab 2: Product Deep-Dive
  # What it does: Lets the user pick one product and see its detailed stats
  #               (units sold, revenue, trend direction) plus a daily chart.
  # ---------------------------------------------------------------------------
  bslib::nav_panel(
    title = "Product Deep-Dive",
    div(
      style = "padding: 0.5rem 0;",
      fluidRow(
        column(
          width = 4,
          div(
            class = "analytics-card",
            div(class = "card-title-custom", "Select Product to Inspect"),
            div(class = "card-subtitle-custom", "Analyze volume, share, and trends for any single SKU"),
            uiOutput("ui_product_select"),
            tags$hr(),
            uiOutput("ui_product_kpis")
          )
        ),
        column(
          width = 8,
          div(
            class = "analytics-card",
            plotlyOutput("plot_product_timeline", height = "440px")
          )
        )
      )
    )
  ),

  # ---------------------------------------------------------------------------
  # Tab 3: Product Comparison
  # What it does: Lets the user select multiple products and compare them
  #               side by side on revenue or units, with a bar chart and table.
  # ---------------------------------------------------------------------------
  bslib::nav_panel(
    title = "Product Comparison",
    div(
      style = "padding: 0.5rem 0;",
      div(
        class = "analytics-card",
        fluidRow(
          column(width = 8, uiOutput("ui_compare_select")),
          column(
            width = 4,
            radioButtons(
              "compare_metric",
              label = "Comparison Metric:",
              choices = c("Total Revenue" = "revenue", "Units Sold" = "units_sold"),
              inline = TRUE
            )
          )
        )
      ),
      fluidRow(
        column(
          width = 7,
          div(class = "analytics-card",
              plotlyOutput("plot_product_duel", height = "380px"))
        ),
        column(
          width = 5,
          div(
            class = "analytics-card",
            div(class = "card-title-custom", "Head-to-Head Statistics"),
            div(class = "card-subtitle-custom", "Side-by-side volume, revenue share, and average price"),
            DTOutput("table_product_comparison")
          )
        )
      )
    )
  ),

  # ---------------------------------------------------------------------------
  # Tab 4: Time & Demand Patterns
  # What it does: Shows demand broken down by day of week and by month,
  #               plus classifies each product as Growing / Stable / Declining.
  # ---------------------------------------------------------------------------
  bslib::nav_panel(
    title = "Time & Demand Patterns",
    div(
      style = "padding: 0.5rem 0;",
      fluidRow(
        column(
          width = 6,
          div(
            class = "analytics-card",
            div(class = "card-title-custom", "Demand by Day of the Week"),
            div(class = "card-subtitle-custom", "Uncover high-traffic days and schedule staff effectively"),
            plotlyOutput("plot_time_dow", height = "360px")
          )
        ),
        column(
          width = 6,
          div(
            class = "analytics-card",
            div(class = "card-title-custom", "Monthly Sales Volume"),
            div(class = "card-subtitle-custom", "Month-over-month performance breakdown"),
            DTOutput("table_monthly_summary")
          )
        )
      ),
      tags$div(style = "height: 1rem;"),
      div(
        class = "analytics-card",
        div(class = "card-title-custom", "Demand Trajectory Classification"),
        div(class = "card-subtitle-custom", "Automatically detects whether products are Growing, Stable, or Declining"),
        DTOutput("table_demand_patterns")
      )
    )
  ),

  # ---------------------------------------------------------------------------
  # Tab 5: Anomalies & "What Changed?"
  # What it does: Flags unusual days using the Z-score method, and lets the
  #               user compare two time periods to see what got better or worse.
  # ---------------------------------------------------------------------------
  bslib::nav_panel(
    title = "Anomalies & What Changed?",
    div(
      style = "padding: 0.5rem 0;",

      # Anomaly detection section
      div(
        class = "analytics-card",
        div(class = "card-title-custom", "Statistical Anomaly Detection"),
        div(class = "card-subtitle-custom",
            "Flags abnormal sales spikes (promotions, events) and unexpected drops (bad weather, stockouts)"),
        fluidRow(
          column(
            width = 4,
            sliderInput("anomaly_k", "Sensitivity Multiplier (k x SD):",
                        min = 1.0, max = 3.0, value = 2.0, step = 0.25)
          ),
          column(width = 8, uiOutput("ui_anomaly_summary_text"))
        ),
        plotlyOutput("plot_anomalies_view", height = "340px")
      ),

      tags$div(style = "height: 1rem;"),

      # Period comparison section
      div(
        class = "analytics-card",
        div(class = "card-title-custom", "What Changed? — Period-over-Period Comparator"),
        div(class = "card-subtitle-custom",
            "Select two distinct date intervals to analyze revenue growth and identify winning vs losing items"),
        fluidRow(
          column(width = 6, uiOutput("ui_period_a_picker")),
          column(width = 6, uiOutput("ui_period_b_picker"))
        ),
        uiOutput("ui_period_change_kpis"),
        plotlyOutput("plot_period_delta_view", height = "360px")
      )
    )
  ),

  # ---------------------------------------------------------------------------
  # Tab 6: 7-Day Forecast & Data Explorer
  # What it does: Shows a 7-day revenue prediction chart and a searchable
  #               table of all cleaned transaction records with CSV export.
  # ---------------------------------------------------------------------------
  bslib::nav_panel(
    title = "7-Day Forecast & Data Explorer",
    div(
      style = "padding: 0.5rem 0;",
      div(
        class = "analytics-card",
        div(class = "card-title-custom", "7-Day Baseline Projection"),
        div(class = "card-subtitle-custom",
            "Day-of-week weighted baseline projection using recent 14-day velocity — confidence improves with more historical data"),
        plotlyOutput("plot_forecast_view", height = "320px")
      ),
      tags$div(style = "height: 1rem;"),
      div(
        class = "analytics-card",
        div(
          style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem;",
          div(
            div(class = "card-title-custom", "Cleaned Transactions Explorer"),
            div(class = "card-subtitle-custom", "Inspect verified records or export cleaned data")
          ),
          downloadButton("btn_download_csv", "Export Clean CSV",
                         class = "btn btn-outline-primary btn-sm")
        ),
        DTOutput("table_raw_data")
      )
    )
  )
)

# =============================================================================
# SECTION: SERVER LOGIC
# What it does: Contains all the reactive logic. When the user changes a
#               filter, selects a product, or switches datasets, the server
#               re-runs the relevant calculations and updates the UI.
# =============================================================================
server <- function(input, output, session) {

  # ---------------------------------------------------------------------------
  # Step 1: Data Pipeline (Load → Clean → Enrich)
  # What it does: Reads the selected CSV file, runs it through the cleaning
  #               function, and stores both the cleaned data and the audit
  #               report as reactive values that other parts can access.
  # ---------------------------------------------------------------------------
  pipeline_output <- reactive({
    choice <- input$dataset_choice

    # Decide which file to load based on the dropdown selection
    target_path <- "data/sales.csv"
    if (choice == "messy") {
      target_path <- "data/sample_messy.csv"
    } else if (choice == "upload" && !is.null(input$user_file)) {
      target_path <- input$user_file$datapath
    }

    # Try loading; if it fails, fall back to the default dataset
    raw <- tryCatch({
      load_sales_data(target_path)
    }, error = function(e) {
      showNotification(paste("Error loading dataset:", e$message), type = "error")
      load_sales_data("data/sales.csv")
    })

    # Clean the raw data and return both the cleaned table and the audit report
    cleaned <- clean_sales_data(raw)
    return(cleaned)
  })

  # Convenience accessors
  clean_data <- reactive({ pipeline_output()$data })
  audit_info <- reactive({ pipeline_output()$audit })

  # ---------------------------------------------------------------------------
  # Audit Banner (sidebar)
  # What it does: Shows a small summary of how many rows were loaded,
  #               how many were removed during cleaning, and how many remain.
  # ---------------------------------------------------------------------------
  output$ui_audit_badge <- renderUI({
    aud <- audit_info()

    # Build warning tags for non-obvious data quality issues
    warnings <- tagList()
    if (!is.null(aud$non_positive_qty_rows) && aud$non_positive_qty_rows > 0) {
      warnings <- tagList(warnings,
        tags$li(style = "color: #d97706; font-weight: 600;",
                paste0("Negative/Zero Qty Dropped: ", aud$non_positive_qty_rows)))
    }
    if (!is.null(aud$non_positive_price_rows) && aud$non_positive_price_rows > 0) {
      warnings <- tagList(warnings,
        tags$li(style = "color: #d97706; font-weight: 600;",
                paste0("Negative/Zero Price Dropped: ", aud$non_positive_price_rows)))
    }
    if (!is.null(aud$discount_clamped_rows) && aud$discount_clamped_rows > 0) {
      warnings <- tagList(warnings,
        tags$li(style = "color: #ef4444; font-weight: 600;",
                paste0("Discount >100% Clamped: ", aud$discount_clamped_rows)))
    }
    if (!is.null(aud$mixed_date_formats) && aud$mixed_date_formats) {
      warnings <- tagList(warnings,
        tags$li(style = "color: #d97706; font-weight: 600;",
                "Mixed Date Formats Detected"))
    }

    div(
      class = "audit-banner",
      div(style = "font-weight: 700; margin-bottom: 4px;", "R Cleaning Audit:"),
      tags$ul(
        style = "margin: 0; padding-left: 1.2rem; font-size: 0.8rem;",
        tags$li(paste("Initial Rows:", aud$total_input_rows)),
        tags$li(paste("Bad Dates:", aud$bad_dates)),
        tags$li(paste("Bad Numbers:", aud$bad_numbers)),
        tags$li(paste("Duplicates Removed:", aud$duplicates_removed)),
        warnings,
        tags$li(style = "font-weight: 700;",
                paste("Clean Rows:", aud$rows_after_cleaning))
      )
    )
  })

  # ---------------------------------------------------------------------------
  # Dynamic Filter Controls
  # What it does: Once the data is loaded, these build the date range picker
  #               and category dropdown with the actual values from the data.
  # ---------------------------------------------------------------------------
  output$ui_date_filter <- renderUI({
    df    <- clean_data()
    min_d <- min(df$date, na.rm = TRUE)
    max_d <- max(df$date, na.rm = TRUE)

    dateRangeInput("date_range", label = "Date Range:",
                   start = min_d, end = max_d, min = min_d, max = max_d,
                   format = "yyyy-mm-dd", separator = " to ")
  })

  output$ui_category_filter <- renderUI({
    df   <- clean_data()
    cats <- sort(unique(df$category))

    selectizeInput("category_filter", label = "Product Category:",
                   choices = cats, selected = cats, multiple = TRUE,
                   options = list(plugins = list("remove_button")))
  })

  # Reset Filters button handler
  observeEvent(input$btn_reset_filters, {
    df    <- clean_data()
    min_d <- min(df$date, na.rm = TRUE)
    max_d <- max(df$date, na.rm = TRUE)
    cats  <- sort(unique(df$category))

    updateDateRangeInput(session, "date_range", start = min_d, end = max_d)
    updateSelectizeInput(session, "category_filter", selected = cats)
  })

  # ---------------------------------------------------------------------------
  # Filtered Data
  # What it does: Applies the user's date range and category selections to
  #               the cleaned data. Every chart and table reads from this.
  # ---------------------------------------------------------------------------
  filtered_df <- reactive({
    df <- clean_data()
    req(input$date_range, input$category_filter)

    df %>%
      filter(
        date >= input$date_range[1] & date <= input$date_range[2],
        category %in% input$category_filter
      )
  })

  # ---------------------------------------------------------------------------
  # Dynamic Dropdowns (product selectors)
  # ---------------------------------------------------------------------------
  output$ui_product_select <- renderUI({
    prods <- sort(unique(filtered_df()$product))
    selectInput("selected_product", label = NULL, choices = prods, selected = prods[1])
  })

  output$ui_compare_select <- renderUI({
    prods          <- sort(unique(filtered_df()$product))
    default_select <- head(prods, 3)
    selectizeInput("compare_products", label = "Select Products to Compare:",
                   choices = prods, selected = default_select, multiple = TRUE,
                   options = list(plugins = list("remove_button")))
  })

  # Period pickers for "What Changed?" tab
  output$ui_period_a_picker <- renderUI({
    dates <- sort(unique(clean_data()$date))
    mid   <- floor(length(dates) / 2)
    dateRangeInput("period_a", "Period A (Baseline):", start = dates[1], end = dates[mid])
  })

  output$ui_period_b_picker <- renderUI({
    dates <- sort(unique(clean_data()$date))
    mid   <- floor(length(dates) / 2)
    dateRangeInput("period_b", "Period B (Comparison):",
                   start = dates[mid + 1], end = dates[length(dates)])
  })

  # ===========================================================================
  # Tab 1 Outputs: Executive Overview
  # ===========================================================================

  # Calculate KPIs, time analysis, demand patterns, and anomalies reactively
  summary_kpis        <- reactive({ calc_summary_kpis(filtered_df()) })
  time_analysis_res   <- reactive({ calc_time_analysis(filtered_df()) })
  demand_patterns_res <- reactive({ classify_demand_patterns(filtered_df()) })
  anomalies_res       <- reactive({
    k_val <- if (!is.null(input$anomaly_k)) input$anomaly_k else 2.0
    detect_anomalies(filtered_df(), k = k_val)
  })

  # --- KPI Cards ---
  output$ui_kpi_cards <- renderUI({
    k <- summary_kpis()

    div(
      class = "kpi-container",
      div(class = "kpi-card blue",
          div(class = "kpi-label", tags$span("Total Revenue")),
          div(class = "kpi-value", paste0("Rs ", format(round(k$total_revenue), big.mark = ","))),
          div(class = "kpi-subtitle", paste("Avg Daily: Rs", format(round(k$avg_daily_revenue), big.mark = ",")))
      ),
      div(class = "kpi-card emerald",
          div(class = "kpi-label", tags$span("Units Sold")),
          div(class = "kpi-value", format(k$total_units, big.mark = ",")),
          div(class = "kpi-subtitle", paste(k$total_transactions, "transactions recorded"))
      ),
      div(class = "kpi-card purple",
          div(class = "kpi-label", tags$span("Top Product")),
          div(class = "kpi-value", style = "font-size: 1.45rem;", k$best_product_name),
          div(class = "kpi-subtitle", paste0("Revenue: Rs ", format(round(k$best_product_revenue), big.mark = ",")))
      ),
      div(class = "kpi-card amber",
          div(class = "kpi-label", tags$span("Peak Sales Day")),
          div(class = "kpi-value", style = "font-size: 1.45rem;", k$best_day_name),
          div(class = "kpi-subtitle", paste0("Avg: Rs ", format(round(k$best_day_avg_rev), big.mark = ","), "/day"))
      )
    )
  })

  # --- Insight Panel ---
  output$ui_insight_panel <- renderUI({
    insights <- generate_executive_insights(
      kpis       = summary_kpis(),
      time_stats = time_analysis_res(),
      patterns   = demand_patterns_res(),
      anomalies  = anomalies_res()
    )

    div(
      class = "insight-panel",
      div(class = "insight-header", "Automated Business Insights"),
      tags$ul(
        class = "insight-list",
        lapply(insights, function(x) {
          # Convert **bold** markdown to HTML <strong> tags
          tags$li(class = "insight-item",
                  HTML(gsub("\\*\\*(.*?)\\*\\*", "<strong>\\1</strong>", x)))
        })
      )
    )
  })

  # --- Overview Charts ---
  output$plot_revenue_time <- renderPlotly({
    plot_revenue_over_time(filtered_df(), interactive = TRUE)
  })

  output$plot_revenue_cat <- renderPlotly({
    plot_revenue_by_category(filtered_df(), interactive = TRUE)
  })

  # ===========================================================================
  # Tab 2 Outputs: Product Deep-Dive
  # ===========================================================================

  product_perf <- reactive({
    req(input$selected_product)
    calc_product_performance(filtered_df(), input$selected_product)
  })

  output$ui_product_kpis <- renderUI({
    p <- product_perf()

    # Choose badge colour based on trend direction
    trend_badge_class <- if (grepl("Increasing", p$trend)) {
      "badge-growing"
    } else if (grepl("Decreasing", p$trend)) {
      "badge-declining"
    } else if (grepl("Emerging", p$trend)) {
      "badge-growing"
    } else if (grepl("Discontinued", p$trend)) {
      "badge-declining"
    } else {
      "badge-stable"
    }

    tagList(
      div(style = "margin-bottom: 0.75rem;",
          div(style = "font-size: 0.8rem; color: #64748b; font-weight: 700; text-transform: uppercase;", "Category"),
          div(style = "font-size: 1.1rem; font-weight: 700;", p$category)),
      div(style = "margin-bottom: 0.75rem;",
          div(style = "font-size: 0.8rem; color: #64748b; font-weight: 700; text-transform: uppercase;", "Units Sold"),
          div(style = "font-size: 1.3rem; font-weight: 800; color: #2563eb;", format(p$units_sold, big.mark = ","))),
      div(style = "margin-bottom: 0.75rem;",
          div(style = "font-size: 0.8rem; color: #64748b; font-weight: 700; text-transform: uppercase;", "Product Revenue"),
          div(style = "font-size: 1.3rem; font-weight: 800; color: #059669;", paste0("Rs ", format(round(p$revenue), big.mark = ",")))),
      div(style = "margin-bottom: 0.75rem;",
          div(style = "font-size: 0.8rem; color: #64748b; font-weight: 700; text-transform: uppercase;", "Avg Daily Sales (Active Days)"),
          div(style = "font-size: 1.1rem; font-weight: 700;", paste(round(p$avg_daily_sales, 1), "units/day"))),
      div(style = "margin-bottom: 0.75rem;",
          div(style = "font-size: 0.8rem; color: #64748b; font-weight: 700; text-transform: uppercase;", "Revenue Contribution"),
          div(style = "font-size: 1.1rem; font-weight: 700;", paste0(round(p$store_share_pct, 1), "% of store"))),
      div(
        div(style = "font-size: 0.8rem; color: #64748b; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;", "Demand Trajectory"),
        tags$span(class = trend_badge_class, p$trend))
    )
  })

  output$plot_product_timeline <- renderPlotly({
    p <- product_perf()
    plot_product_trend(p$daily_series, p$product, interactive = TRUE)
  })

  # ===========================================================================
  # Tab 3 Outputs: Product Comparison
  # ===========================================================================

  duel_data <- reactive({
    req(input$compare_products)
    compare_products(filtered_df(), input$compare_products)
  })

  output$plot_product_duel <- renderPlotly({
    d      <- duel_data()
    metric <- if (!is.null(input$compare_metric)) input$compare_metric else "revenue"
    plot_product_comparison_chart(d$summary_table, metric = metric, interactive = TRUE)
  })

  output$table_product_comparison <- renderDT({
    d <- duel_data()$summary_table
    req(nrow(d) > 0)

    display_tbl <- d %>%
      transmute(
        Product        = product,
        Category       = category,
        `Units Sold`   = format(units_sold, big.mark = ","),
        `Total Revenue` = paste0("Rs ", format(round(total_revenue), big.mark = ",")),
        `Daily Avg`    = round(avg_daily_units, 1),
        `Rev Share`    = paste0(round(revenue_share, 1), "%")
      )

    datatable(display_tbl, options = list(dom = 't', paging = FALSE), rownames = FALSE)
  })

  # ===========================================================================
  # Tab 4 Outputs: Time & Demand Patterns
  # ===========================================================================

  output$plot_time_dow <- renderPlotly({
    t <- time_analysis_res()
    plot_weekday_analysis(t$day_of_week, interactive = TRUE)
  })

  output$table_monthly_summary <- renderDT({
    t <- time_analysis_res()$monthly
    req(nrow(t) > 0)

    display_m <- t %>%
      transmute(
        Month              = month,
        `Total Revenue`    = paste0("Rs ", format(round(total_revenue), big.mark = ",")),
        `Units Sold`       = format(total_units, big.mark = ","),
        `Daily Avg Revenue` = paste0("Rs ", format(round(avg_daily_revenue), big.mark = ",")),
        `Days Active`      = active_days
      )

    datatable(display_m, options = list(dom = 't', paging = FALSE), rownames = FALSE)
  })

  output$table_demand_patterns <- renderDT({
    pats <- demand_patterns_res()
    req(nrow(pats) > 0)

    display_pat <- pats %>%
      transmute(
        Product           = product,
        Category          = category,
        `Early Daily Avg` = round(early_avg, 1),
        `Recent Daily Avg` = round(recent_avg, 1),
        # Display human-readable labels for edge cases instead of Inf%
        `Change (%)`      = case_when(
          status == "Emerging"     ~ "New",
          status == "Discontinued" ~ "-100%",
          status == "No Activity"  ~ "—",
          TRUE ~ sprintf("%+.1f%%", change_pct)
        ),
        Status            = status
      )

    datatable(display_pat, options = list(pageLength = 10, dom = 'tip'), rownames = FALSE)
  })

  # ===========================================================================
  # Tab 5 Outputs: Anomalies & "What Changed?"
  # ===========================================================================

  # --- Anomaly summary text ---
  output$ui_anomaly_summary_text <- renderUI({
    ano      <- anomalies_res()
    n_spikes <- sum(ano$anomalies$anomaly_type == "High Spike", na.rm = TRUE)
    n_drops  <- sum(ano$anomalies$anomaly_type == "Low Drop", na.rm = TRUE)

    div(
      style = "font-size: 0.9rem; color: #475569; padding-top: 10px;",
      tags$span(style = "font-weight: 700;", "Detected Outliers: "),
      tags$span(style = "color: #ef4444; font-weight: 700;", paste(n_spikes, "High Spikes")),
      " | ",
      tags$span(style = "color: #d97706; font-weight: 700;", paste(n_drops, "Low Drops")),
      tags$br(),
      tags$span(style = "font-size: 0.8rem; color: #64748b;",
        sprintf("Thresholds: Upper = Rs %s | Lower = Rs %s (Mean = Rs %s, SD = Rs %s)",
                format(round(ano$upper_bound), big.mark = ","),
                format(round(ano$lower_bound), big.mark = ","),
                format(round(ano$mean_rev), big.mark = ","),
                format(round(ano$sd_rev), big.mark = ",")))
    )
  })

  output$plot_anomalies_view <- renderPlotly({
    plot_anomalies_timeline(anomalies_res(), interactive = TRUE)
  })

  # --- Period comparison ---
  period_change_data <- reactive({
    req(input$period_a, input$period_b)
    analyze_period_change(
      clean_data(),
      input$period_a[1], input$period_a[2],
      input$period_b[1], input$period_b[2]
    )
  })

  output$ui_period_change_kpis <- renderUI({
    chg <- period_change_data()
    req(!is.null(chg))

    # Format percentage, handling Inf (new demand from zero baseline)
    fmt_pct <- function(val, sign_prefix = TRUE) {
      if (is.infinite(val) && val > 0) return("New Demand")
      if (is.infinite(val) && val < 0) return("Eliminated")
      prefix <- if (sign_prefix && val >= 0) "+" else ""
      paste0(prefix, round(val, 1), "%")
    }

    rev_delta_color <- if (is.finite(chg$rev_change_pct) && chg$rev_change_pct < 0) "#e11d48" else "#059669"

    # Format top gainer/decline labels, guarding against Inf
    gainer_label <- if (!is.null(chg$top_gainer)) {
      if (is.infinite(chg$top_gainer$rev_pct)) "New in Period B" else paste0("+", round(chg$top_gainer$rev_pct, 1), "% revenue gain")
    } else "N/A"
    decline_label <- if (!is.null(chg$biggest_decline)) {
      if (is.infinite(chg$biggest_decline$rev_pct)) "Absent in Period B" else paste0(round(chg$biggest_decline$rev_pct, 1), "% revenue drop")
    } else "N/A"

    div(
      class = "kpi-container", style = "margin-top: 1rem; margin-bottom: 1rem;",
      div(class = "kpi-card",
          div(class = "kpi-label", "Period Revenue Delta"),
          div(class = "kpi-value", style = paste0("color: ", rev_delta_color, ";"),
              fmt_pct(chg$rev_change_pct)),
          div(class = "kpi-subtitle",
              paste0("Rs ", format(round(chg$rev_a), big.mark = ","),
                     " -> Rs ", format(round(chg$rev_b), big.mark = ",")))
      ),
      div(class = "kpi-card",
          div(class = "kpi-label", "Units Sold Delta"),
          div(class = "kpi-value", fmt_pct(chg$units_change_pct)),
          div(class = "kpi-subtitle", paste(chg$units_a, "units ->", chg$units_b, "units"))
      ),
      div(class = "kpi-card emerald",
          div(class = "kpi-label", "Top Improvement"),
          div(class = "kpi-value", style = "font-size: 1.35rem;",
              if (!is.null(chg$top_gainer)) chg$top_gainer$product else "N/A"),
          div(class = "kpi-subtitle", gainer_label)
      ),
      div(class = "kpi-card amber",
          div(class = "kpi-label", "Biggest Decline"),
          div(class = "kpi-value", style = "font-size: 1.35rem;",
              if (!is.null(chg$biggest_decline)) chg$biggest_decline$product else "N/A"),
          div(class = "kpi-subtitle", decline_label)
      )
    )
  })

  output$plot_period_delta_view <- renderPlotly({
    plot_period_delta_chart(period_change_data(), interactive = TRUE)
  })

  # ===========================================================================
  # Tab 6 Outputs: 7-Day Forecast & Data Explorer
  # ===========================================================================

  output$plot_forecast_view <- renderPlotly({
    df <- filtered_df()
    fc <- calc_simple_forecast(df, horizon = 7)
    plot_forecast_chart(df, fc, interactive = TRUE)
  })

  # Interactive data table of all cleaned records
  output$table_raw_data <- renderDT({
    df <- filtered_df()

    display_df <- df %>%
      transmute(
        Date         = as.character(date),
        Day          = as.character(day_of_week),
        Product      = product,
        Category     = category,
        Quantity     = quantity,
        `Unit Price` = paste0("Rs ", unit_price),
        `Discount (%)`  = paste0(discount, "%"),
        `Net Revenue` = paste0("Rs ", round(revenue, 2))
      )

    datatable(
      display_df, filter = "top",
      options = list(pageLength = 10, lengthMenu = c(10, 25, 50, 100)),
      rownames = FALSE
    )
  })

  # CSV download handler
  output$btn_download_csv <- downloadHandler(
    filename = function() {
      paste0("demandsense_cleaned_sales_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(filtered_df(), file, row.names = FALSE)
    }
  )
}

# =============================================================================
# Launch the application
# =============================================================================
shinyApp(ui = ui, server = server)
