# DAX Measures Documentation

## 1. Total Orders
```dax
Total Orders =
COUNTROWS(Orders)
```
Counts the total number of orders.

## 2. Delivered Orders
```dax
Delivered Orders =
CALCULATE(
    COUNTROWS(Orders),
    Orders[order_status] = "delivered"
)
```
Counts orders with delivered status.

## 3. Cancelled Orders
```dax
Cancelled Orders =
CALCULATE(
    COUNTROWS(Orders),
    Orders[order_status] = "canceled"
)
```
Counts orders that were canceled.

## 4. Late Orders
```dax
Late Orders =
CALCULATE(
    COUNTROWS(Orders),
    FILTER(
        Orders,
        Orders[order_status] = "delivered"
            && NOT ISBLANK(Orders[order_delivered_customer_date])
            && NOT ISBLANK(Orders[order_estimated_delivery_date])
            && Orders[order_delivered_customer_date]
                > Orders[order_estimated_delivery_date]
    )
)
```
Counts delivered orders that arrived after the estimated delivery date.

## 5. On-Time Orders
```dax
On-Time Orders =
CALCULATE(
    COUNTROWS(Orders),
    FILTER(
        Orders,
        Orders[order_status] = "delivered"
            && NOT ISBLANK(Orders[order_delivered_customer_date])
            && NOT ISBLANK(Orders[order_estimated_delivery_date])
            && Orders[order_delivered_customer_date]
                <= Orders[order_estimated_delivery_date]
    )
)
```
Counts delivered orders that arrived on or before the estimated delivery date.

## 6. Average Delivery Time
```dax
Average Delivery Time =
AVERAGEX(
    FILTER(
        Orders,
        Orders[order_status] = "delivered"
            && NOT ISBLANK(Orders[order_purchase_timestamp])
            && NOT ISBLANK(Orders[order_delivered_customer_date])
    ),
    DATEDIFF(
        Orders[order_purchase_timestamp],
        Orders[order_delivered_customer_date],
        DAY
    )
)
```
Calculates the average number of days between order purchase and customer delivery.

## 7. Average Estimated Delivery Time
```dax
Average Estimated Delivery Time =
AVERAGEX(
    FILTER(
        Orders,
        Orders[order_status] = "delivered"
            && NOT ISBLANK(Orders[order_purchase_timestamp])
            && NOT ISBLANK(Orders[order_estimated_delivery_date])
    ),
    DATEDIFF(
        Orders[order_purchase_timestamp],
        Orders[order_estimated_delivery_date],
        DAY
    )
)
```
Calculates the average estimated delivery duration in days.

## 8. Average Delivery Delay
```dax
Average Delivery Delay =
AVERAGEX(
    FILTER(
        Orders,
        Orders[order_status] = "delivered"
            && NOT ISBLANK(Orders[order_delivered_customer_date])
            && NOT ISBLANK(Orders[order_estimated_delivery_date])
    ),
    DATEDIFF(
        Orders[order_estimated_delivery_date],
        Orders[order_delivered_customer_date],
        DAY
    )
)
```
Calculates the average difference between actual and estimated delivery dates. Positive values indicate delays; negative values indicate early delivery.

## 9. Average Carrier Handover Time
```dax
Average Carrier Handover Time =
AVERAGEX(
    FILTER(
        Orders,
        NOT ISBLANK(Orders[order_purchase_timestamp])
            && NOT ISBLANK(Orders[order_delivered_carrier_date])
    ),
    DATEDIFF(
        Orders[order_purchase_timestamp],
        Orders[order_delivered_carrier_date],
        DAY
    )
)
```
Calculates the average time taken to hand over orders from purchase to carrier.

## 10. Average Carrier-to-Customer Time
```dax
Avg_Carrier_to_Customer =
AVERAGEX(
    FILTER(
        Orders,
        NOT(ISBLANK(Orders[order_delivered_carrier_date]))
            && NOT(ISBLANK(Orders[order_delivered_customer_date]))
    ),
    DATEDIFF(
        Orders[order_delivered_carrier_date],
        Orders[order_delivered_customer_date],
        DAY
    )
)
```
Calculates the average time taken by the carrier to deliver orders to customers.

## Tools Used
- Power BI
- DAX (Data Analysis Expressions)
- Power Query
- MySQL