# Purpose: Launcher script for DemandSense Shiny application.
# It reads port and host settings from environment variables (useful for Docker/cloud)
# and falls back to port 8080 and host 0.0.0.0.

library(shiny)

# Get port and host from environment variables or use defaults
app_port <- as.numeric(Sys.getenv("PORT", unset = "8080"))
app_host <- Sys.getenv("HOST", unset = "0.0.0.0")

cat("=====================================================\n")
cat("Starting DemandSense - Sales & Demand Analytics (R)\n")
cat(sprintf("Listening on http://%s:%d\n", app_host, app_port))
cat("Press Ctrl+C to terminate\n")
cat("=====================================================\n\n")

# Run the Shiny application
shiny::runApp(
  appDir = ".",
  port = app_port,
  host = app_host,
  launch.browser = FALSE
)
