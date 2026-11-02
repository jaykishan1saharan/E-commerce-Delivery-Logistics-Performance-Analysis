# KPI Definitions – Olist E-commerce Delivery Analysis

## 1. Purpose

This document defines the key performance indicators (KPIs) used to evaluate order delivery performance, customer experience, and operational efficiency in the Olist E-commerce dataset.

These definitions will be used consistently across SQL queries, exported datasets, and the Power BI dashboard.

## 2. Dataset Requirements

The order-level analytical dataset should contain the following fields:

| Column | Description |
|---|---|
| `order_id` | Unique identifier for each order |
| `customer_id` | Unique customer identifier |
| `order_status` | Current status of the order |
| `purchase_timestamp` | Date and time when the order was placed |
| `estimated_delivery_timestamp` | Estimated delivery date |
| `actual_delivery_timestamp` | Actual delivery date |
| `customer_state` | State of the customer |
| `review_score` | Customer review score (1–5) |
| `delivery_days` | Actual delivery duration in days |
| `late_delivery_flag` | Indicates whether an order was delivered late |

**Important:** The analytical dataset must contain only one row per unique `order_id`. Joins with order items or reviews must not unintentionally multiply order records.

## 3. Core KPIs

### KPI 1: Total Orders

**Definition:** Total number of unique orders placed.

**SQL Formula:**
```sql
COUNT(DISTINCT order_id)
```

### KPI 2: Delivered Orders

**Definition:** Number of orders successfully delivered to customers.

**SQL Formula:**
```sql
COUNT(DISTINCT CASE
    WHEN order_status = 'delivered'
    THEN order_id
END)
```

### KPI 3: Cancelled Orders

**Definition:** Number of orders that were cancelled.

**SQL Formula:**
```sql
COUNT(DISTINCT CASE
    WHEN order_status = 'canceled'
    THEN order_id
END)
```

### KPI 4: Late Orders

**Definition:** Number of delivered orders where the actual delivery timestamp is later than the estimated delivery timestamp.

**SQL Formula:**
```sql
COUNT(DISTINCT CASE
    WHEN order_status = 'delivered'
     AND actual_delivery_timestamp > estimated_delivery_timestamp
    THEN order_id
END)
```

### KPI 5: Late Delivery Rate

**Definition:** Percentage of delivered orders that arrived later than the estimated delivery date.

**Formula:**

Late Delivery Rate = (Late Orders / Delivered Orders) × 100

**SQL Formula:**
```sql
ROUND(
    100.0 * SUM(late_delivery_flag) /
    NULLIF(COUNT(DISTINCT order_id), 0),
    2
)
```

Use this formula on a dataset containing only delivered orders, with one row per order.

### KPI 6: Cancellation Rate

**Definition:** Percentage of total orders that were cancelled.

**Formula:**

Cancellation Rate = (Cancelled Orders / Total Orders) × 100

**SQL Formula:**
```sql
ROUND(
    100.0 * COUNT(DISTINCT CASE
        WHEN order_status = 'canceled'
        THEN order_id
    END) /
    NULLIF(COUNT(DISTINCT order_id), 0),
    2
)
```

### KPI 7: Average Delivery Days

**Definition:** Average number of days taken to deliver successfully delivered orders.

**Formula:**

Delivery Days = Actual Delivery Timestamp − Purchase Timestamp

**SQL Formula:**
```sql
ROUND(
    AVG(
        TIMESTAMPDIFF(
            DAY,
            purchase_timestamp,
            actual_delivery_timestamp
        )
    ),
    2
)
```

Only delivered orders with valid purchase and actual delivery timestamps should be included.

### KPI 8: Average Review Score

**Definition:** Average customer rating given to orders.

**SQL Formula:**
```sql
ROUND(AVG(review_score), 2)
```

Review scores range from 1 to 5. Use an order-level review value to avoid counting the same order multiple times.

## 4. Data Quality Validation KPIs

The following checks must be performed before using the dataset in Power BI:

| Validation Check | Expected Result |
|---|---|
| Duplicate order IDs | 0 |
| Missing order IDs | 0 |
| Invalid delivery dates | 0 after applying documented exclusion rules |
| Negative delivery duration | 0 |
| Invalid review scores | 0 |
| Duplicate rows in final dataset | 0 |
| Delivered orders without actual delivery dates | Investigate and document |

## 5. Business Rules

1. Count orders using `COUNT(DISTINCT order_id)` wherever appropriate.
2. Consider only successfully delivered orders when calculating delivery duration and late delivery rate.
3. An order is late only when its actual delivery timestamp is greater than its estimated delivery timestamp.
4. Orders with missing timestamps must not be silently treated as on-time deliveries.
5. Cancelled orders must not be included in delivery duration calculations.
6. Use consistent date and timestamp formats throughout SQL and Power BI.
7. Avoid duplicate order records caused by one-to-many joins.
8. Document any excluded records and the reason for exclusion.

## 6. KPI Usage in Power BI

| KPI | Suggested Dashboard Visual |
|---|---|
| Total Orders | KPI Card |
| Delivered Orders | KPI Card |
| Cancelled Orders | KPI Card |
| Late Orders | KPI Card |
| Late Delivery Rate | KPI Card / Gauge |
| Cancellation Rate | KPI Card |
| Average Delivery Days | KPI Card |
| Average Review Score | KPI Card |
| Delivery Performance by State | Bar Chart / Map |
| Monthly Order Trends | Line Chart |
| Order Status Distribution | Donut Chart |

## 7. Validation and Ownership

**Responsible Member:** Yashashvi Yash

**Project:** Olist E-commerce Delivery Analysis

**Purpose:** Maintain consistent KPI definitions between SQL calculations, exported CSV files, and the Power BI dashboard.

All final KPI values must be validated against SQL query results before the dashboard is considered complete.

---

*Document Version: 1.0*  
*Project Phase: Week 4 – Dashboard Validation*