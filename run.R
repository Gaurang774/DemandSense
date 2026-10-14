# Purpose: Launcher script for DemandSense Shiny application.
# It reads port and host settings from environment variables (useful for Docker/cloud)
# and falls back to port 8080 and host 0.0.0.0.

library(shiny)

# Dynamic port verification to prevent "address already in use" crashes
find_available_port <- function(default_port = 8080, max_tries = 10) {
  # If PORT is explicitly set via environment (e.g. Docker, Render), respect it
  env_port <- Sys.getenv("PORT", unset = "")
  if (nzchar(env_port)) {
    return(as.numeric(env_port))
  }
  
  for (p in default_port:(default_port + max_tries)) {
    is_free <- tryCatch({
      s <- httpuv::startServer("127.0.0.1", p, list())
      httpuv::stopServer(s)
      TRUE
    }, error = function(e) FALSE)
    
    if (is_free) return(p)
  }
  return(default_port)
}

app_port <- find_available_port(8080)
app_host <- Sys.getenv("HOST", unset = "0.0.0.0")

# Determine whether to auto-launch the browser
launch_browser_env <- Sys.getenv("LAUNCH_BROWSER", unset = "")
if (nzchar(launch_browser_env)) {
  launch_browser <- as.logical(launch_browser_env)
} else {
  # Auto-launch browser on Windows desktop; keep FALSE on headless/Docker Linux
  launch_browser <- (.Platform$OS.type == "windows")
}

cat("=====================================================\n")
cat("Starting DemandSense - Sales & Demand Analytics (R)\n")
cat(sprintf("Listening on http://%s:%d\n", app_host, app_port))
cat(sprintf("Open in browser: http://localhost:%d (or http://127.0.0.1:%d)\n", app_port, app_port))
cat("Press Ctrl+C to terminate\n")
cat("=====================================================\n\n")

# Run the Shiny application
shiny::runApp(
  appDir = ".",
  port = app_port,
  host = app_host,
  launch.browser = launch_browser
)
