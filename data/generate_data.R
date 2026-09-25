# Script to generate realistic sales datasets for DemandSense
set.seed(42)

start_date <- as.Date("2026-05-01")
end_date   <- as.Date("2026-08-31")
all_dates  <- seq.Date(start_date, end_date, by = "day")

products_meta <- list(
  list(name = "Coffee", category = "Beverages", price = 80, base_qty = 38, trend = 0.05),
  list(name = "Tea", category = "Beverages", price = 50, base_qty = 32, trend = -0.15),
  list(name = "Cold Brew", category = "Beverages", price = 120, base_qty = 12, trend = 0.25),
  list(name = "Smoothie", category = "Beverages", price = 140, base_qty = 16, trend = 0.08),
  list(name = "Croissant", category = "Bakery", price = 90, base_qty = 26, trend = 0.02),
  list(name = "Chocolate Muffin", category = "Bakery", price = 75, base_qty = 22, trend = 0.01),
  list(name = "Blueberry Scone", category = "Bakery", price = 85, base_qty = 15, trend = -0.02),
  list(name = "Grilled Sandwich", category = "Snacks", price = 150, base_qty = 24, trend = 0.06),
  list(name = "Bagel & Cream Cheese", category = "Snacks", price = 110, base_qty = 18, trend = 0.03),
  list(name = "Veggie Wrap", category = "Snacks", price = 130, base_qty = 14, trend = 0.02)
)

rows <- list()

for (i in seq_along(all_dates)) {
  dt <- all_dates[i]
  day_name <- weekdays(dt)
  day_idx <- i # 1 to 123
  
  # Day of week multiplier
  dow_mult <- switch(day_name,
    "Monday" = 0.90,
    "Tuesday" = 0.95,
    "Wednesday" = 0.85,
    "Thursday" = 1.00,
    "Friday" = 1.20,
    "Saturday" = 1.65,
    "Sunday" = 1.35,
    1.00
  )
  
  # Special event dates (Anomalies)
  is_solstice_fest <- (dt == as.Date("2026-06-21"))
  is_storm_day     <- (dt == as.Date("2026-07-14"))
  is_college_fest  <- (dt == as.Date("2026-08-18"))
  
  for (p in products_meta) {
    # Trend progress from 0 to 1
    progress <- day_idx / length(all_dates)
    trend_factor <- 1 + (p$trend * progress * 2)
    
    # Calculate expected quantity
    expected_qty <- p$base_qty * dow_mult * trend_factor
    
    # Apply noise
    noise <- rnorm(1, mean = 0, sd = 3)
    qty <- round(expected_qty + noise)
    if (qty < 1) qty <- 1
    
    # Apply anomalies
    if (is_solstice_fest && p$name %in% c("Coffee", "Cold Brew", "Smoothie")) {
      qty <- round(qty * 2.6)
    }
    if (is_storm_day) {
      qty <- max(1, round(qty * 0.15))
    }
    if (is_college_fest && p$name %in% c("Coffee", "Cold Brew", "Grilled Sandwich", "Chocolate Muffin")) {
      qty <- round(qty * 2.8)
    }
    
    # Occasional discount
    discount <- 0
    disc_roll <- runif(1)
    if (disc_roll < 0.12) {
      discount <- sample(c(5, 10, 15, 20), 1)
    }
    
    rows[[length(rows) + 1]] <- data.frame(
      date = as.character(dt),
      product = p$name,
      category = p$category,
      quantity = as.integer(qty),
      unit_price = as.numeric(p$price),
      discount = as.numeric(discount),
      stringsAsFactors = FALSE
    )
  }
}

clean_df <- do.call(rbind, rows)
write.csv(clean_df, "data/sales.csv", row.names = FALSE)
cat(sprintf("Generated clean sales dataset: %d rows\n", nrow(clean_df)))

# Now generate a messy dataset for demonstrating R cleaning pipeline
messy_df <- clean_df[sample(nrow(clean_df), 150), ]

# Introduce dirty data:
# 1. Missing discounts (NA)
messy_df$discount[sample(nrow(messy_df), 15)] <- NA

# 2. Negative or zero quantities
messy_df$quantity[sample(nrow(messy_df), 6)] <- c(-2, 0, -5, 0, -1, 0)

# 3. Invalid unit prices
messy_df$unit_price[sample(nrow(messy_df), 4)] <- c(-80, 0, NA, -50)

# 4. Inconsistent date formats or missing dates
messy_df$date[sample(nrow(messy_df), 5)] <- c(NA, "2026/06/15", "01-07-2026", NA, "2026-08-01")

# 5. Duplicate rows
duplicates <- messy_df[sample(nrow(messy_df), 12), ]
messy_df <- rbind(messy_df, duplicates)

write.csv(messy_df, "data/sample_messy.csv", row.names = FALSE)
cat(sprintf("Generated messy sample dataset: %d rows (includes nulls, negatives, duplicates)\n", nrow(messy_df)))
