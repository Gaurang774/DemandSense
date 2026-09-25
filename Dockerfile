# =============================================================================
# Purpose: Dockerfile for DemandSense - Sales & Demand Analytics Web Application
# Description: Packages R, required Linux system dependencies, all required R
#              packages, and the application source code into a portable container.
# =============================================================================

# Step 1: Base Image
# We use rocker/shiny:latest which is the official Docker image for R Shiny.
# It includes Linux (Ubuntu), R, and the Shiny web framework pre-installed.
FROM rocker/shiny:latest

# Step 2: Install required Linux system libraries
# Packages like readr, plotly, and DT require underlying C/C++ system libraries
# for networking (libcurl, openssl), XML parsing, and font/image rendering.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

# Step 3: Install required R packages
# Installs all data manipulation, charting, UI theming, and table packages.
RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org/')); \
    install.packages(c( \
        'bslib', \
        'dplyr', \
        'tidyr', \
        'readr', \
        'lubridate', \
        'ggplot2', \
        'plotly', \
        'DT', \
        'scales' \
    ))"

# Step 4: Set the working directory inside the container
WORKDIR /app

# Step 5: Copy all project files into the container working directory
COPY . /app

# Step 6: Expose port 8080 to allow incoming web traffic
EXPOSE 8080

# Step 7: Define default command to start the Shiny app via run.R
CMD ["Rscript", "run.R"]
