# DemandSense — Interactive Sales & Demand Analytics in R

> **College Mini-Project**  
> **Technologies:** R (v4.6.1+), Shiny, bslib, ggplot2, plotly, dplyr, readr, tidyr, DT, scales  
> **Core Concept:** Transforming raw business transaction data into automated visual insights using R.

---

## 📌 Executive Summary

**DemandSense** is an interactive, full-stack data analytics application designed to help small business owners and managers analyze their sales performance without manual spreadsheet work. 

Built exclusively in **R**, it demonstrates the complete modern data science lifecycle:
```text
RAW SALES DATA (CSV)
      ↓
R DATA CLEANING & AUDIT (readr, dplyr, tidyr)
      ↓
FEATURE ENRICHMENT (as.Date, format, weekdays, revenue derivation)
      ↓
STATISTICAL ANALYTICS & ANOMALY DETECTION (Mean, SD, Z-scores, CAGR)
      ↓
DETERMINISTIC INSIGHT GENERATION (Rule-based natural language generator)
      ↓
INTERACTIVE VISUALIZATION (ggplot2 + Plotly)
      ↓
SHINY PRESENTATION & REACTIVE ENGINE (bslib dashboard)
```

---

## 🚀 Quick Start Guide

### Prerequisites
- R (version 4.2 or higher, tested on R 4.6.1)
- Installed R packages:
  ```r
  install.packages(c("shiny", "bslib", "dplyr", "tidyr", "readr", "ggplot2", "plotly", "DT", "scales"))
  ```

### Launching the Application
Open a terminal in the project directory (`d:\demandsence`) and run:
```bash
Rscript run.R
```
Or from within RStudio / R console:
```r
shiny::runApp()
```
The application will launch immediately at **`http://127.0.0.1:8080`**.

### Running Automated Pipeline Tests
To execute pre-flight unit and integration checks across all modules:
```bash
Rscript tests/test_analytics.R
```

---

## 🗂️ Project Structure

```text
demandsence/
├── app.R                     # Main Shiny UI, server logic, navigation & reactive orchestration
├── run.R                     # Single-command launch script
├── prd.md                    # Product Requirement Document
├── README.md                 # Project documentation & Academic Viva Guide
│
├── R/
│   ├── data_loader.R         # Safe CSV ingestion & schema validation
│   ├── data_cleaner.R        # Deduplication, type validation, date parsing & audit trail
│   ├── analytics.R           # Core statistical routines, KPIs, comparison & anomaly math
│   ├── insights.R            # Deterministic, rule-based natural language insight generator
│   └── plots.R               # Modern ggplot2 custom theme + Plotly interactive wrappers
│
├── data/
│   ├── generate_data.R       # Reproducible data synthesis script (with fixed seed)
│   ├── sales.csv             # Curated 1,230-row small business dataset (May–Aug)
│   └── sample_messy.csv      # Dirty test dataset (nulls, negatives, duplicates) for viva demo
│
├── www/
│   └── style.css             # Glassmorphism accents, modern typography & card styling
│
└── tests/
    └── test_analytics.R      # End-to-end analytical pipeline test suite
```

---

## 💻 Key Features & Modules

### 1. Executive Overview
- **Real-Time KPI Cards:** Total Revenue, Total Units Sold, Best-Selling Product, and Peak Sales Day.
- **Automated Business Insights:** 100% deterministic natural language findings generated in R highlighting volume leaders, peak days, growth surges, and detected outliers.
- **Visuals:** Daily revenue trajectory line chart with smooth trend and revenue breakdown by product category.

### 2. Product Deep-Dive
- Inspect any individual SKU (e.g., *Coffee*, *Cold Brew*, *Grilled Sandwich*).
- Displays total units sold, revenue, average daily sales velocity, store revenue share %, and trajectory badge (*Growing*, *Stable*, *Declining*).

### 3. Product Comparison (Duel)
- Side-by-side comparison of 2 or more products.
- Switchable metric toggle (*Total Revenue* vs. *Units Sold*).
- Head-to-head summary statistics table with average unit prices and revenue shares.

### 4. Time & Demand Patterns
- **Day-of-Week Analysis:** Visualizes revenue distribution across Monday through Sunday, highlighting the peak demand day (e.g. Saturday).
- **Monthly Seasonality Table:** Aggregates performance by month.
- **Demand Trajectory Classification:** Automatically compares historical vs. recent periods to categorize items into *Growing (↗)*, *Stable (→)*, or *Declining (↘)*.

### 5. Anomalies & "What Changed?"
- **Statistical Outlier Detection:** Implements dynamic statistical bounds ($\text{Mean} \pm k \cdot \text{SD}$) with an interactive sensitivity slider to flag abnormal spikes (festivals, promotions) and drops (inclement weather, stockouts).
- **"What Changed?" Period Comparator:** Compares two distinct date intervals (Period A vs. Period B) to isolate revenue growth % and pinpoint top gainers and biggest decliners.

### 6. 7-Day Forecast & Data Explorer
- **Day-of-Week Weighted Moving Forecast:** Extrapolates future 7-day demand using weekday seasonality multipliers and recent 14-day velocity.
- **Interactive Data Table:** Filterable, searchable, and paginated transaction viewer powered by `DT` with instant CSV export.

---

## 🎓 Academic Viva Voce Defense Guide

### 1. Elevator Pitch (30-second summary)
> *"DemandSense is an interactive sales and demand analytics application built in R and Shiny. Rather than relying on static spreadsheets or black-box machine learning, DemandSense implements a transparent R pipeline: it ingests raw transaction data, cleans and audits dirty records, derives analytical features, runs statistical anomaly detection, and renders dynamic business insights through reactive Shiny visualizations."*

### 2. Frequently Asked Viva Questions

#### Q1: Why use R instead of Python or Excel for this project?
**Answer:**  
- **Vectorized Data Processing:** R is built from the ground up for statistical computing. With the tidyverse (`dplyr`, `tidyr`), complex multi-column transformations and aggregations execute with high performance and expressive, readable code.
- **Reactivity & Presentation:** R Shiny offers a native reactive programming model where UI changes automatically propagate through a dependency graph without needing a separate frontend/backend architecture.
- **Academic Rigor:** R provides built-in statistical primitives (`mean()`, `sd()`, `quantile()`) that make anomaly detection and data audits easy to verify and explain mathematically.

#### Q2: How does the Anomaly Detection work mathematically?
**Answer:**  
We use statistical parametric thresholding based on the normal distribution:
1. Aggregate daily revenue: $x_i = \sum \text{revenue on day } i$.
2. Compute mean daily revenue: $\mu = \frac{1}{N}\sum_{i=1}^N x_i$.
3. Compute standard deviation: $\sigma = \sqrt{\frac{1}{N-1}\sum_{i=1}^N (x_i - \mu)^2}$.
4. Define bounds using multiplier $k$:
   $$\text{Upper Bound} = \mu + k\sigma, \quad \text{Lower Bound} = \max(0, \mu - k\sigma)$$
5. Points where $x_i > \text{Upper Bound}$ are classified as **High Spikes**; points where $x_i < \text{Lower Bound}$ are classified as **Low Drops**.

#### Q3: How is Shiny reactivity structured in `app.R`?
**Answer:**  
- **`reactive()` expressions:** We use cached reactive pipelines (`pipeline_output()`, `filtered_df()`, `summary_kpis()`) that only recompute when their explicit inputs (e.g. date range, category dropdown, dataset selector) change.
- **`isolate()` and `req()`:** We guard downstream calculations using `req()` so calculations only trigger when valid user inputs are supplied.

#### Q4: How does DemandSense handle dirty or messy datasets?
**Answer:**  
In `R/data_cleaner.R`:
1. **Deduplication:** Calls `dplyr::distinct()` to eliminate duplicate transaction logs.
2. **Flexible Date Parsing:** Uses a multi-format regex parser supporting `%Y-%m-%d`, `%Y/%m/%d`, and `%d-%m-%Y`. Rows with invalid dates are removed.
3. **Domain Validation:** Filters out non-positive quantities (`quantity > 0`) and prices (`unit_price > 0`), and imputes missing discounts to 0.
4. **Audit Logging:** Emits an audit object tracking initial rows, pruned duplicates, and dropped invalid rows, visible in the sidebar.
