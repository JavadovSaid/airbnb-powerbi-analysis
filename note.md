# Airbnb Pricing & Occupancy Performance Analysis (Seattle Dataset)

## 1. Data Cleaning & Power Query Decisions
* **Price Column Normalization:** Striped `$` and `,` formatting symbols from both `listings[price]` and `calendar[price]` columns, casting them to `Decimal Number`.
* **The `available` Column Logic Trap:** In `calendar.csv`, `available = 'f'` indicates that a listing was **Booked**, while `'t'` means it remained vacant. To avoid completely inverting the occupancy analysis, a custom conditional column `IsBooked` was created:
  $$\text{IsBooked} = \begin{cases} 1 & \text{if } \text{available} = \text{'f'} \\ 0 & \text{if } \text{available} = \text{'t'} \end{cases}$$
* **Column Pruning:** Removed non-analytical listing metadata (e.g., URLs, host notes, scraping dates) to optimize in-memory model compression.

---

## 2. Data Model & Architecture (Star Schema)
* **Fact Table:** `calendar` (~1.39M rows containing daily granularity listings availability and pricing).
* **Dimension Table:** `listings` (3,818 unique active property profiles).
* **Date Dimension:** Built via DAX `CALENDAR()` auto-range, marked as the official Date table.
* **Relationships:**  
  * `Date[Date]` `1` $\rightarrow$ `*` `calendar[date]` (Single direction)  
  * `listings[id]` `1` $\rightarrow$ `*` `calendar[listing_id]` (Single direction)
* **Sorting Logic:** `Date[Month Name]` configured to sort explicitly by `Date[Month Number]` to ensure strictly chronological visualization on trend charts.

---

## 3. DAX Calculation Methodology & Median Price Explanation
### Why `MEDIANX` over `listings[id]` is Required
A naive `MEDIAN(calendar[price])` across the 1.39M row fact table skews pricing upwards because high-occupancy listings are over-represented across daily rows, and daily dynamic prices fluctuate seasonally. Conversely, a flat `MEDIAN(listings[price])` ignores contextual filters when evaluating dynamic portfolio slices.

To calculate an accurate listing-level median price that aggregates correctly at any visual grain (Neighbourhood, Room Type, Month):
```dax
Median Price = 
MEDIANX(
    VALUES(listings[id]),
    CALCULATE(AVERAGE(listings[price]))
)
```


## 4. Key Findings & 5 Strategic Investor Insights (Based on Dashboard Metrics)

### Insight 1: Top-Tier Pricing Neighborhoods (Briarcliff & Industrial District)
* **Data Context:** The overall active portfolio consists of **3,818 listings** with an overall market median price hovering around **10,000** and an average occupancy rate of **~33%**.
* **Finding:** Neighborhoods such as **Briarcliff** (Median Price: **17,350**) and **Industrial District / Pioneer Square** lead the pricing spectrum. However, Briarcliff exhibits a lower occupancy rate (**~13%**), indicating a luxury, low-turnover segment.
* **Actionable Advice:** High-net-worth investors focusing on capital appreciation and luxury nightly rates should target Briarcliff, keeping in mind the necessity for targeted high-end marketing to offset lower booking frequency.

### Insight 2: High Occupancy Performance Leaders (South Lake Union & South Beacon Hill)
* **Data Context:** Neighborhood occupancy benchmarked via horizontal bar charts.
* **Finding:** **South Lake Union** achieves the highest occupancy rate in the market at **~55%**, followed closely by **South Beacon Hill** and **North Beach/Blue Ridge** (**~50%**).
* **Actionable Advice:** For steady, cash-flow-driven investors, properties in South Lake Union represent the ideal balance of demand velocity and reliable monthly yields.

### Insight 3: Room Type Economics (`Entire home/apt` vs. Shared Spaces)
* **Data Context:** Room type analysis across median price and occupancy rate visuals.
* **Finding:** `Entire home/apt` commands a dominant median price of **~12,500+** and the highest occupancy rate of **~36%**, whereas `Private room` (**~7,000**) and `Shared room` (**~4,000**) scale down significantly in both price and demand (**~18% occupancy** for shared spaces).
* **Actionable Advice:** Investors should strictly prioritize acquiring single-family or multi-room apartments designated as `Entire home/apt`, as they drastically outperform shared accommodations in revenue generation potential.

### Insight 4: Instant Bookable Impact on Portfolio Uniformity
* **Data Context:** `instant_bookable` comparison (`t` vs `f`).
* **Finding:** Listings with instant booking enabled maintain comparable median price baselines while smoothing out booking friction across the platform.
* **Actionable Advice:** Property managers should enable `instant_bookable` on all listings to capture impulse travelers and enhance algorithm-driven search visibility without needing to discount nightly rates.

### Insight 5: Review Volume vs. Occupancy Correlation
* **Data Context:** Scatter/Bar distribution of `number_of_reviews` against `Occupancy Rate %`.
* **Finding:** Properties maintaining active review loops cluster heavily toward consistent operational engagement, proving that social proof directly supports long-term booking stability.
* **Actionable Advice:** New hosts must implement automated post-stay review reminders within the first 14 days to rapidly build review counts, establishing algorithmic trust and driving higher occupancy rates.