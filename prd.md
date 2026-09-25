# DemandSense

### Interactive Sales & Demand Analytics for Small Businesses

**Project Type:** College Mini-Project
**Primary Goal:** Learn and demonstrate practical use of R for data analysis
**Primary Technology:** R
**Frontend:** Shiny
**Visualization:** ggplot2, optional Plotly
**Data:** Historical sales transaction data

---

# 1. Product Overview

**DemandSense** is an interactive sales analytics application designed for small businesses to understand how their products perform over time.

A business provides historical sales data, and the application uses R to:

* clean the data
* calculate sales metrics
* identify trends
* compare products
* identify peak sales periods
* analyze demand patterns
* detect unusual sales activity
* generate simple business insights

The user interacts with filters and charts rather than manually analyzing spreadsheets.

The purpose is not to build a complex AI forecasting system.

The purpose is to demonstrate how **R can transform raw business data into useful information and visual insights**.

---

# 2. Problem Statement

Small businesses often have sales records but do not have an easy way to answer questions such as:

> Which products sell the most?

> When are sales highest?

> Which products are losing demand?

> Which days of the week perform best?

> Are sales increasing or decreasing?

> Which products experience unusual spikes or drops?

> Which products generate the most revenue?

A spreadsheet can answer some of these questions, but the analysis often requires repeated manual work.

DemandSense provides a single interactive environment for exploring these questions.

---

# 3. Core Philosophy

The project follows:

```text
RAW SALES DATA
      ↓
R DATA CLEANING
      ↓
R DATA TRANSFORMATION
      ↓
R STATISTICAL ANALYSIS
      ↓
R VISUALIZATION
      ↓
SHINY INTERACTION
      ↓
BUSINESS INSIGHT
```

R is the **analytical engine**.

Shiny is the **presentation and interaction layer**.

---

# 4. Target User

## Primary User

Small business owner or manager.

Examples:

* grocery store
* clothing shop
* electronics shop
* café
* stationery store
* small online retailer

## Secondary User

Students learning R and data analysis.

The application should remain simple enough to demonstrate during an academic viva.

---

# 5. Input Dataset

The MVP uses a CSV file containing sales records.

Example:

```text
date
product
category
quantity
unit_price
discount
```

Optional fields:

```text
customer
payment_method
location
promotion
```

Example:

| Date       | Product | Category | Quantity | Unit Price | Discount |
| ---------- | ------- | -------- | -------: | ---------: | -------: |
| 2026-08-01 | Coffee  | Beverage |       12 |         80 |        0 |
| 2026-08-01 | Tea     | Beverage |       18 |         50 |        5 |
| 2026-08-02 | Coffee  | Beverage |       20 |         80 |        0 |

The project should begin with a **clean, well-defined dataset** before supporting messy uploads.

---

# 6. Data Processing Pipeline

## Step 1 — Import

Use:

```r
readr::read_csv()
```

to load the dataset.

## Step 2 — Cleaning

Handle:

* missing values
* incorrect data types
* invalid quantities
* invalid prices
* duplicate rows

Core R packages:

```text
readr
dplyr
tidyr
```

## Step 3 — Derived Variables

Use `mutate()` to create:

```text
revenue
month
week
day_of_week
```

For example:

```r
revenue = quantity * unit_price - discount
```

## Step 4 — Aggregation

Use:

```r
group_by()
summarise()
```

to calculate:

* total revenue
* total units sold
* average daily sales
* product revenue
* category revenue
* daily sales
* monthly sales

---

# 7. Main Dashboard

The landing dashboard should immediately answer:

> **How is the business performing?**

Display:

```text
TOTAL REVENUE
₹248,420

UNITS SOLD
4,821

BEST SELLING PRODUCT
Coffee

BEST SALES DAY
Saturday

AVERAGE DAILY REVENUE
₹8,281
```

These are calculated directly in R.

---

# 8. Module 1 — Sales Overview

This module gives an overall view of sales.

### Visualizations

#### Revenue over time

```text
Revenue
  │
  │          ╭──╮
  │      ╭───╯  ╰────╮
  │  ╭───╯            ╰─
  └────────────────────────
       Time
```

Use:

```r
ggplot2::geom_line()
```

#### Revenue by category

```text
Beverages   ███████████
Snacks      ████████
Desserts    █████
```

Use:

```r
geom_col()
```

---

# 9. Module 2 — Product Performance

The user selects a product.

Example:

```text
Product:
[ Coffee ▼ ]
```

The application displays:

```text
COFFEE

Units Sold
1,248

Revenue
₹99,840

Average Daily Sales
41.6

Trend
↗ Increasing
```

The chart shows sales over time.

The user can change the product and the entire analysis updates.

---

# 10. Module 3 — Product Comparison

Allow users to compare two or more products.

Example:

```text
Product A: Coffee
Product B: Tea
```

Display:

```text
              Coffee     Tea

Units Sold      1248      980
Revenue       ₹99840    ₹49000
Avg/day         41.6      32.6
```

Visual comparison:

```text
Coffee   ███████████████
Tea      ███████████
```

R performs the aggregation and comparison.

---

# 11. Module 4 — Time Analysis

Analyze demand by:

* day of week
* month
* week
* selected date range

Example:

```text
MONDAY       ██████
TUESDAY      ███████
WEDNESDAY    █████
THURSDAY     ████████
FRIDAY       █████████
SATURDAY     ████████████
SUNDAY       ██████████
```

The application can identify:

> **Saturday has the highest average daily sales.**

This is calculated from the data rather than hardcoded.

---

# 12. Module 5 — Demand Patterns

This module focuses on simple patterns in sales.

Possible analyses:

### Growing products

Products whose sales are increasing over time.

### Declining products

Products whose sales are decreasing.

### Stable products

Products whose sales remain relatively consistent.

Initially, this can be implemented with simple statistics rather than machine learning.

For example:

```text
Earlier average sales
        ↓
Recent average sales
        ↓
Compare
        ↓
Increasing / Stable / Declining
```

---

# 13. Module 6 — Peak Period Analysis

Determine when the business experiences unusually high sales.

Analyze:

* highest-selling days
* highest-selling weeks
* highest-selling months
* highest-demand products

Example:

```text
PEAK SALES

Saturday
₹14,820

December
₹62,410

Coffee
412 units
```

---

# 14. Module 7 — Anomaly Detection

The application should identify unusually high or low sales observations.

MVP approach:

Use simple statistical thresholds such as:

```text
Mean
Standard deviation
```

Conceptually:

```text
Normal sales
───────────────

        •
      • • •
    • • • • •
  • • • • • • •
                 ●
                 ↑
               unusual
```

The application can label:

```text
HIGH SPIKE
LOW DROP
```

and allow the user to investigate the date/product responsible.

No machine learning is required.

---

# 15. Module 8 — “What Changed?”

This should be one of the product's signature features.

Compare two selected periods.

Example:

```text
Period A:
1–15 August

Period B:
16–31 August
```

R calculates:

```text
Revenue
₹94,200 → ₹111,800

Change
+18.7%
```

Then:

```text
TOP IMPROVEMENT

Coffee
+27%

BIGGEST DECLINE

Tea
-11%
```

This turns raw charts into an actual analytical workflow.

---

# 16. Module 9 — Insight Panel

Create deterministic, rule-based textual insights.

Example:

```text
INSIGHTS

• Coffee generated the highest revenue.
• Saturday had the highest average daily sales.
• Revenue increased by 18.7% in the second half
  of the selected month.
• Tea sales declined by 11%.
• One unusually high sales spike occurred on 18 Aug.
```

These sentences should be generated from actual R calculations.

Do not use an LLM for the MVP.

---

# 17. Interactive Filters

Global filters:

```text
Date range
[ Start ] → [ End ]

Category
[ All ▼ ]

Product
[ All ▼ ]
```

Optional:

```text
Day of week
[ All ▼ ]
```

Every visualization should update when filters change.

---

# 18. Recommended UI

The application should look like a modern analytics product rather than a default Shiny application.

## Layout

```text
┌────────────────────────────────────────────────────────────┐
│ DEMANDSENSE                                                │
│ Sales & Demand Analytics                                   │
├────────────────────────────────────────────────────────────┤
│ Date Range        Category        Product                  │
│ [____] [____]     [ All ▼ ]       [ All ▼ ]               │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ ₹248,420       4,821        Coffee       Saturday          │
│ Revenue        Units        Best Product  Peak Day         │
│                                                            │
├─────────────────────────────┬──────────────────────────────┤
│                             │                              │
│ Revenue Trend               │ Category Performance         │
│                             │                              │
│       ╭───╮                 │ Beverage   ███████████       │
│    ╭──╯   ╰──╮              │ Snacks     ███████           │
│ ───╯         ╰───           │ Desserts   █████             │
│                             │                              │
├─────────────────────────────┴──────────────────────────────┤
│                      KEY INSIGHTS                          │
│  • Saturday has the highest average sales.                │
│  • Coffee revenue increased 27%.                           │
│  • One unusual spike occurred on 18 Aug.                  │
└────────────────────────────────────────────────────────────┘
```

---

# 19. R Skills Demonstrated

DemandSense should deliberately teach the following R concepts.

## Data Import

```r
read_csv()
```

## Data Cleaning

```r
filter()
drop_na()
distinct()
```

## Data Transformation

```r
mutate()
select()
arrange()
```

## Grouping & Aggregation

```r
group_by()
summarise()
count()
```

## Combining Data

Optional:

```r
left_join()
```

## Statistics

```r
mean()
median()
sd()
min()
max()
```

## Date Handling

```r
as.Date()
format()
```

## Visualization

```r
ggplot()
geom_line()
geom_col()
geom_point()
```

## Shiny

```r
reactive()
renderPlot()
renderTable()
renderText()
observeEvent()
```

---

# 20. Optional Phase 2 — Simple Forecasting

Once the core system works, add a basic demand forecast.

Example:

```text
HISTORICAL SALES
       ↓
Simple statistical model
       ↓
NEXT 7 DAYS
```

Display:

```text
Forecast

Mon  122 units
Tue  118 units
Wed  130 units
Thu  136 units
Fri  149 units
Sat  171 units
Sun  156 units
```

This introduces basic modeling without turning the project into a machine-learning project.

---

# 21. Optional Phase 3 — Inventory Assistant

Use sales history to produce a simple stock signal.

Example:

```text
COFFEE
Current stock: 82

Average daily demand: 42

Estimated coverage:
~2 days

STATUS
⚠ Reorder soon
```

This transforms DemandSense from an analytics dashboard into a lightweight operational tool.

This should be **future scope**, not part of the initial MVP.

---

# 22. Data Model

MVP:

```text
sales
│
├── date
├── product
├── category
├── quantity
├── unit_price
└── discount
```

Derived:

```text
revenue
day_of_week
month
week
```

Future:

```text
products.csv
sales.csv
promotions.csv
inventory.csv
```

Multiple datasets can later be joined using `left_join()`.

---

# 23. Architecture

```text
                    SHINY UI
                       │
                       ▼
              ┌─────────────────┐
              │   R ANALYTICS   │
              │                 │
              │ Data Loading    │
              │ Cleaning        │
              │ Transformation  │
              │ Statistics      │
              │ Pattern Logic   │
              │ Visualization   │
              └────────┬────────┘
                       │
                       ▼
                   ggplot2
                       │
                       ▼
                  VISUAL OUTPUT
```

Suggested structure:

```text
DemandSense/
│
├── app.R
│
├── R/
│   ├── data_loader.R
│   ├── data_cleaner.R
│   ├── analytics.R
│   ├── insights.R
│   └── plots.R
│
├── data/
│   └── sales.csv
│
└── www/
    └── style.css
```

---

# 24. MVP Scope

The first submission should contain:

### Dashboard

* revenue
* units sold
* best-selling product
* peak sales day

### Product Analysis

* product selection
* sales trend
* revenue
* units sold

### Time Analysis

* weekday analysis
* monthly analysis
* date filtering

### Comparison

* compare products/categories

### Insights

* automatically generated rule-based findings

### Visualization

* line chart
* bar chart
* comparison chart

### Shiny interaction

* filters
* reactive plots
* reactive statistics

---

# 25. What We Should NOT Build Initially

To keep the R learning manageable:

* no deep machine learning
* no complex neural networks
* no recommendation engine
* no AI-generated business advice
* no custom backend API
* no massive frontend framework
* no real-time database
* no advanced forecasting initially

The project should first succeed as a **strong R analytics application**.

---

# 26. Learning Progression

The project itself becomes an R learning roadmap.

### Stage 1

```text
CSV
↓
read_csv()
↓
data frame
```

### Stage 2

```text
cleaning
↓
filter()
mutate()
select()
```

### Stage 3

```text
group_by()
summarise()
```

### Stage 4

```text
mean()
median()
sd()
```

### Stage 5

```text
ggplot2
```

### Stage 6

```text
Shiny
reactive()
renderPlot()
```

### Stage 7

```text
Insights
anomaly detection
simple forecasting
```

---

# 27. Demonstration Scenario

During the presentation:

### Step 1

Upload:

```text
sales.csv
```

### Step 2

DemandSense calculates:

```text
₹248,420 revenue
4,821 units
```

### Step 3

Select:

```text
Product = Coffee
```

### Step 4

R updates:

```text
Coffee revenue
₹99,840
```

### Step 5

Select:

```text
August
```

### Step 6

The system displays:

> Coffee sales increased 27% compared with the previous period.

### Step 7

Select:

```text
Saturday
```

The graph changes and shows the Saturday demand pattern.

This provides a very clean live demonstration of **R + Shiny reactivity**.

---

# 28. Success Criteria

The project is successful when a user can:

1. Load sales data.
2. Explore the data interactively.
3. Understand product performance.
4. Identify high/low demand periods.
5. Compare products.
6. Discover unusual observations.
7. Receive automatically generated data-backed insights.
8. See all major calculations and visualizations update through R.

---

# 29. Academic Value

DemandSense demonstrates practical R usage across the complete data-analysis pipeline:

```text
IMPORT
  ↓
CLEAN
  ↓
TRANSFORM
  ↓
ANALYZE
  ↓
VISUALIZE
  ↓
INTERACT
  ↓
INTERPRET
```

This is much easier to learn and defend than building an R interpreter, while still demonstrating substantially more than a simple marks dashboard.

---

# 30. Viva Explanation

> **“DemandSense is an interactive sales analytics system built using R and Shiny. We take historical transaction data, clean and transform it using R, calculate sales and demand statistics, identify trends and anomalies, and present the results through interactive visualizations. Shiny provides the interface, while R performs the actual analytical work.”**

---

# 31. Final Product Identity

## DemandSense

### **Understand what your sales data is telling you.**

Core loop:

```text
             SALES DATA
                  ↓
                  R
        ┌─────────┼─────────┐
        ↓         ↓         ↓
      CLEAN     ANALYZE   COMPARE
        │         │         │
        └─────────┼─────────┘
                  ↓
              INSIGHTS
                  ↓
              SHINY UI
                  ↓
          INVESTIGATE DATA
```

The core MVP should stay deliberately simple. The sophistication comes from **the quality of the analysis and the interaction**, not from complicated code.
