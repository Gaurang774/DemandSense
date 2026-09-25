# =============================================================================
# FILE: R/data_loader.R
# PURPOSE: Reads a CSV file containing sales data and checks that the
#          required columns are present before returning the data.
# =============================================================================

library(readr)
library(dplyr)

# -----------------------------------------------------------------------------
# Function: load_sales_data
# What it does: Opens a CSV file, standardises column names to lowercase,
#               checks that essential columns exist, and fills in defaults
#               for any optional columns that are missing.
# Input:  file_path — path to the CSV file (string)
# Output: A data frame (tibble) with all columns read as text so that
#         the cleaning step can handle type conversion safely.
# -----------------------------------------------------------------------------
load_sales_data <- function(file_path = "data/sales.csv") {

  # Stop immediately if the file does not exist
  if (!file.exists(file_path)) {
    stop(paste("File not found:", file_path))
  }

  # Read every column as plain text (character).
  # This avoids automatic type-guessing errors on messy data.
  raw_data <- readr::read_csv(
    file      = file_path,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE,
    trim_ws   = TRUE
  )

  # Make all column names lowercase and remove extra spaces
  colnames(raw_data) <- tolower(trimws(colnames(raw_data)))

  # These four columns must be present for the app to work

  required_cols <- c("date", "product", "quantity", "unit_price")
  missing_cols  <- setdiff(required_cols, colnames(raw_data))

  if (length(missing_cols) > 0) {
    stop(paste("Missing required column(s):", paste(missing_cols, collapse = ", ")))
  }

  # If the file has no "category" column, create one with a default value
  if (!"category" %in% colnames(raw_data)) {
    raw_data$category <- "General"
  }

  # If the file has no "discount" column, assume zero discount
  if (!"discount" %in% colnames(raw_data)) {
    raw_data$discount <- "0"
  }

  return(raw_data)
}
