# =============================================================================
# FILE: R/data_cleaner.R
# PURPOSE: Takes the raw text data loaded by data_loader.R and cleans it.
#          Converts text to proper types (dates, numbers), removes invalid
#          rows, and calculates the "revenue" column.
# =============================================================================

library(dplyr)
library(lubridate)

# -----------------------------------------------------------------------------
# Function: clean_sales_data
# What it does:
#   1. Tries multiple date formats to parse the "date" column.
#   2. Converts quantity, unit_price, and discount from text to numbers.
#   3. Removes rows that have invalid or missing values.
#   4. Keeps a record of how many bad rows were removed (the audit trail).
#   5. Calculates revenue = quantity * unit_price * (1 - discount/100).
#
# Input:  raw_data — the tibble returned by load_sales_data()
# Output: A named list with two items:
#           $data  — the cleaned tibble ready for analysis
#           $audit — a list of counts showing what was removed
# -----------------------------------------------------------------------------
clean_sales_data <- function(raw_data) {

  # --- Step 1: Record the starting row count for the audit ---
  start_rows <- nrow(raw_data)

  # --- Step 2: Parse dates ---
  # Try several common date formats. If a value cannot be parsed by any
  # format, it becomes NA and will be removed later.
  cleaned <- raw_data

  # Detect mixed date formats before parsing (audit flag)
  date_strings <- cleaned$date[!is.na(cleaned$date)]
  ymd_pattern <- grepl("^\\d{4}[-/]", date_strings)
  mdy_pattern <- grepl("^\\d{1,2}/\\d{1,2}/\\d{4}$", date_strings)
  dmy_pattern <- grepl("^\\d{1,2}-\\d{1,2}-\\d{4}$", date_strings)
  n_formats_detected <- sum(c(any(ymd_pattern), any(mdy_pattern), any(dmy_pattern)))
  mixed_date_formats <- (n_formats_detected > 1)

  cleaned$date <- lubridate::parse_date_time(
    cleaned$date,
    orders = c("ymd", "mdy", "dmy", "ymd HMS", "mdy HMS", "dmy HMS"),
    quiet  = TRUE
  )
  cleaned$date <- as.Date(cleaned$date)

  # Count how many dates could not be parsed
  bad_dates <- sum(is.na(cleaned$date))

  # --- Step 3: Convert text columns to numbers ---
  cleaned$quantity   <- as.numeric(cleaned$quantity)
  cleaned$unit_price <- as.numeric(cleaned$unit_price)
  cleaned$discount   <- as.numeric(cleaned$discount)

  # Replace any NA discounts with 0 (no discount)
  cleaned$discount[is.na(cleaned$discount)] <- 0

  # Track rows where discount exceeded 100% before clamping
  # (these produce zero or negative revenue, which is a data quality issue)
  discount_clamped_rows <- sum(cleaned$discount > 100, na.rm = TRUE)

  # Clamp discount to stay between 0 and 100
  cleaned$discount <- pmin(pmax(cleaned$discount, 0), 100)

  # Count how many quantity or price values were not valid numbers
  bad_numbers <- sum(is.na(cleaned$quantity) | is.na(cleaned$unit_price))

  # --- Step 4: Remove rows with any remaining NA values in key columns ---
  # Track negative/zero quantity rows specifically (these are returns, spoilage, etc.)
  non_positive_qty_rows <- sum(
    !is.na(cleaned$quantity) & cleaned$quantity <= 0 &
    !is.na(cleaned$date) & !is.na(cleaned$unit_price),
    na.rm = TRUE
  )
  non_positive_price_rows <- sum(
    !is.na(cleaned$unit_price) & cleaned$unit_price <= 0 &
    !is.na(cleaned$date) & !is.na(cleaned$quantity),
    na.rm = TRUE
  )

  cleaned <- cleaned %>%
    filter(
      !is.na(date),
      !is.na(quantity),
      !is.na(unit_price),
      quantity > 0,
      unit_price > 0
    )

  # --- Step 5: Clean up text columns ---
  # Trim whitespace and capitalise the first letter of product and category
  cleaned$product  <- tools::toTitleCase(trimws(cleaned$product))
  cleaned$category <- tools::toTitleCase(trimws(cleaned$category))

  # --- Step 6: Calculate revenue ---
  # revenue = quantity * price, reduced by the discount percentage
  cleaned$revenue <- cleaned$quantity * cleaned$unit_price * (1 - cleaned$discount / 100)

  # --- Step 7: Add time-based columns for analytics ---
  # These are used by calc_time_analysis() and calc_summary_kpis()
  day_order <- c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
  cleaned$day_of_week <- factor(weekdays(cleaned$date), levels = day_order)
  cleaned$month       <- format(cleaned$date, "%B %Y")       # e.g. "January 2025"
  cleaned$year_month  <- format(cleaned$date, "%Y-%m")        # e.g. "2025-01"

  # --- Step 8: Remove any exact duplicate rows ---
  before_dedup <- nrow(cleaned)
  cleaned <- distinct(cleaned)
  duplicates_removed <- before_dedup - nrow(cleaned)

  # --- Step 9: Build the audit summary ---
  end_rows <- nrow(cleaned)
  audit <- list(
    total_input_rows       = start_rows,
    bad_dates              = bad_dates,
    bad_numbers            = bad_numbers,
    non_positive_qty_rows  = non_positive_qty_rows,
    non_positive_price_rows = non_positive_price_rows,
    discount_clamped_rows  = discount_clamped_rows,
    mixed_date_formats     = mixed_date_formats,
    duplicates_removed     = duplicates_removed,
    rows_after_cleaning    = end_rows,
    rows_removed           = start_rows - end_rows
  )

  return(list(data = cleaned, audit = audit))
}
