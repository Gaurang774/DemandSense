# run.R
# One-click execution script for DemandSense

cat("=====================================================\n")
cat("Starting DemandSense - Sales & Demand Analytics (R)\n")
cat("Listening on http://127.0.0.1:8080\n")
cat("Press Ctrl+C to terminate\n")
cat("=====================================================\n\n")

library(shiny)

# Run the app locally
shiny::runApp(
  appDir = ".",
  port = 8080,
  host = "127.0.0.1",
  launch.browser = FALSE
)
