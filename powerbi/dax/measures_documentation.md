# DAX Measures Documentation

## 1. Total Orders

```dax
Total Orders =
DISTINCTCOUNT(order_analytics[order_id])
```

Counts the total number of unique orders.

## 2. Delivered Orders

```dax
Delivered Orders =
CALCULATE(
    DISTINCTCOUNT(order_analytics[order_id]),
    order_analytics[order_status] = "delivered"
)
```

Counts orders with delivered status.

## 3. Late Orders

```dax
Late Orders =
CALCULATE(
    DISTINCTCOUNT(order_analytics[order_id]),
    order_analytics[order_status] = "delivered",
    order_analytics[on_time_delivery_flag] = 0
)
```

Counts delivered orders that were late.

## 4. Late Delivery Rate

```dax
Late Delivery Rate =
DIVIDE(
    [Late Orders],
    CALCULATE(
        DISTINCTCOUNT(order_analytics[order_id]),
        order_analytics[order_status] = "delivered",
        NOT ISBLANK(order_analytics[on_time_delivery_flag])
    ),
    0
)
```

Calculates the percentage of eligible delivered orders that were late.

## 5. Cancellation Rate

```dax
Cancellation Rate =
DIVIDE(
    CALCULATE(
        DISTINCTCOUNT(order_analytics[order_id]),
        order_analytics[order_status] = "canceled"
    ),
    [Total Orders],
    0
)
```

Calculates the percentage of orders that were canceled.

## 6. Total Order Value

```dax
Total Order Value =
SUM(order_analytics[item_plus_freight_total])
```

Calculates the total item value plus freight value.

## Tools Used
- Power BI
- DAX
- Power Query
- MySQL