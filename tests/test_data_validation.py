import csv
import unittest
from datetime import datetime
from pathlib import Path
from typing import Iterable, Optional, Set


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
RAW_ORDERS_PATH = (
    REPOSITORY_ROOT / "data" / "raw" / "olist_orders_dataset.csv"
)
FINAL_ORDER_LEVEL_PATH = (
    REPOSITORY_ROOT / "data" / "interim" / "final_order_level.csv"
)
REQUIRED_COLUMNS = {
    "order_id",
    "customer_id",
    "order_status",
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
}
TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S"


def parse_timestamp(value: Optional[str]) -> Optional[datetime]:
    if value is None or not value.strip():
        return None
    return datetime.strptime(value, TIMESTAMP_FORMAT)


def find_duplicate_ids(order_ids: Iterable[str]) -> Set[str]:
    seen = set()
    duplicates = set()
    for order_id in order_ids:
        if order_id in seen:
            duplicates.add(order_id)
        seen.add(order_id)
    return duplicates


def timestamp_sequence_is_valid(
    timestamps: Iterable[Optional[datetime]],
) -> bool:
    populated = [timestamp for timestamp in timestamps if timestamp is not None]
    return all(
        earlier <= later for earlier, later in zip(populated, populated[1:])
    )


def is_on_time(
    actual_delivery: Optional[str], estimated_delivery: Optional[str]
) -> Optional[bool]:
    actual = parse_timestamp(actual_delivery)
    estimated = parse_timestamp(estimated_delivery)
    if actual is None or estimated is None:
        return None
    return actual <= estimated


class OrderDataValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with RAW_ORDERS_PATH.open(
            encoding="utf-8-sig", newline=""
        ) as orders_file:
            reader = csv.DictReader(orders_file)
            cls.raw_columns = set(reader.fieldnames or [])
            cls.raw_orders = list(reader)

    def test_raw_orders_have_required_columns(self):
        self.assertTrue(
            REQUIRED_COLUMNS.issubset(self.raw_columns),
            f"Missing columns: {sorted(REQUIRED_COLUMNS - self.raw_columns)}",
        )

    def test_raw_order_ids_are_present_and_unique(self):
        order_ids = [row["order_id"].strip() for row in self.raw_orders]
        self.assertTrue(all(order_ids), "Raw orders contain blank order IDs")
        self.assertEqual(find_duplicate_ids(order_ids), set())

    def test_duplicate_detection_finds_repeated_order_ids(self):
        self.assertEqual(
            find_duplicate_ids(["order-1", "order-2", "order-1"]),
            {"order-1"},
        )

    def test_raw_delivery_timestamps_do_not_precede_purchase(self):
        for row in self.raw_orders:
            purchase = parse_timestamp(row["order_purchase_timestamp"])
            delivered = parse_timestamp(
                row["order_delivered_customer_date"]
            )
            if purchase is not None and delivered is not None:
                self.assertLessEqual(
                    purchase,
                    delivered,
                    f"Delivery precedes purchase for {row['order_id']}",
                )

    def test_timestamp_sequence_validation_uses_available_timestamps(self):
        valid_sequence = [
            "2018-01-01 09:00:00",
            "2018-01-01 10:00:00",
            None,
            "2018-01-02 10:00:00",
        ]
        invalid_sequence = [
            "2018-01-01 09:00:00",
            "2018-01-01 08:00:00",
        ]
        self.assertTrue(
            timestamp_sequence_is_valid(
                parse_timestamp(value) for value in valid_sequence
            )
        )
        self.assertFalse(
            timestamp_sequence_is_valid(
                parse_timestamp(value) for value in invalid_sequence
            )
        )

    def test_missing_delivery_timestamps_are_not_classified_as_on_time(self):
        estimated = "2018-01-02 10:00:00"
        self.assertIsNone(is_on_time(None, estimated))
        self.assertIsNone(
            is_on_time("2018-01-02 09:00:00", None)
        )
        self.assertTrue(
            is_on_time("2018-01-02 09:00:00", estimated)
        )
        self.assertFalse(
            is_on_time("2018-01-02 11:00:00", estimated)
        )

    @unittest.skipUnless(
        FINAL_ORDER_LEVEL_PATH.is_file(),
        "Member 1's final order-level output is unavailable; "
        "expected data/interim/final_order_level.csv",
    )
    def test_final_order_level_row_count_matches_distinct_order_ids(self):
        with FINAL_ORDER_LEVEL_PATH.open(
            encoding="utf-8-sig", newline=""
        ) as final_file:
            reader = csv.DictReader(final_file)
            self.assertIn("order_id", reader.fieldnames or [])
            order_ids = [row["order_id"].strip() for row in reader]

        self.assertTrue(all(order_ids), "Final output contains blank order IDs")
        self.assertEqual(len(order_ids), len(set(order_ids)))


if __name__ == "__main__":
    unittest.main()
