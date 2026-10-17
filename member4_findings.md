\# Member 4: Delivery Logistics Performance Analysis



\## Objective

Analyze order status, delivery duration, late deliveries, cancellations, and customer review scores using the Olist e-commerce dataset.



\## Dataset Summary

\- Total orders: 99,441

\- Delivered orders: 96,478

\- Customer review records imported: 99,224



\## Key Findings



\### Order Status

\- Delivered: 96,478

\- Shipped: 1,107

\- Canceled: 625

\- Unavailable: 609

\- Invoiced: 314

\- Processing: 301

\- Created: 5

\- Approved: 2



Most orders in the dataset were delivered.



\### Delivery Performance

\- Average delivery duration: 12.56 days

\- Minimum duration: 0.53 days

\- Maximum duration: 209.63 days

\- Late deliveries: 7,826



The maximum delivery duration is unusually high and should be investigated as a potential outlier.



\### Cancellations

\- Canceled orders: 625

\- Cancellation rate: 0.63% of all orders



\### Customer Review Scores

\- 1 star: 11,424

\- 2 stars: 3,151

\- 3 stars: 8,179

\- 4 stars: 19,142

\- 5 stars: 57,328



Five-star reviews were the most frequent, while two-star reviews were the least frequent.



\## Deliverables

The `reports/member4/` directory contains four CSV reports and four charts covering order status, delivery duration, cancellations, and review scores.



\## Limitations

\- Delivery duration uses valid purchase and customer-delivery timestamps for delivered orders.

\- Late delivery depends on comparing actual and estimated delivery dates.

\- Review counts represent available review records and may not represent unique orders.

\- The analysis identifies patterns but does not establish the causes of delays or cancellations.



\## Conclusion

Most orders were delivered, average delivery duration was 12.56 days, and the cancellation rate was 0.63%. Five-star reviews were the most common. Further investigation of late deliveries and unusually long delivery durations may help identify logistics improvement opportunities.

