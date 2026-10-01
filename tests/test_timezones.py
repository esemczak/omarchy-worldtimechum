import unittest
from datetime import datetime, timezone
from timezones import snapshot


class TimezoneTests(unittest.TestCase):
    def test_half_and_quarter_hour_offsets_share_instants(self):
        result = snapshot(["Australia/Adelaide", "Asia/Kathmandu"], now=datetime(2026, 10, 2, tzinfo=timezone.utc))
        a, b = result["rows"]
        self.assertEqual(a["cells"][0]["time"], "00:00")
        self.assertEqual(b["cells"][0]["time"], "20:15")
        self.assertEqual(a["cells"][0]["epoch"], b["cells"][0]["epoch"])

    def test_spring_gap(self):
        row = snapshot(["America/New_York"], now=datetime(2026, 3, 8, 12, tzinfo=timezone.utc))["rows"][0]
        self.assertEqual([c["time"] for c in row["cells"][:4]], ["00:00", "01:00", "03:00", "04:00"])

    def test_fall_repeat_is_distinguishable(self):
        row = snapshot(["America/New_York"], now=datetime(2026, 11, 1, 12, tzinfo=timezone.utc))["rows"][0]
        self.assertEqual(row["cells"][1]["time"], row["cells"][2]["time"])
        self.assertNotEqual(row["cells"][1]["offset"], row["cells"][2]["offset"])

    def test_weekend_not_work(self):
        row = snapshot(["Europe/London"], now=datetime(2026, 10, 3, 12, tzinfo=timezone.utc))["rows"][0]
        self.assertFalse(any(c["work"] for c in row["cells"][:24]))

    def test_current_column_tracks_home_time(self):
        result = snapshot(["Australia/Adelaide"], now=datetime(2026, 10, 1, 21, 45, tzinfo=timezone.utc))
        self.assertEqual(result["currentColumn"], 7)
        self.assertAlmostEqual(result["currentPosition"], 7.25)

    def test_current_position_on_other_date_does_not_round_up(self):
        result = snapshot(["Australia/Adelaide"], day_offset=1, now=datetime(2026, 10, 1, 22, 15, tzinfo=timezone.utc))
        self.assertEqual(result["currentColumn"], 7)
        self.assertAlmostEqual(result["currentPosition"], 7.75)

    def test_current_column_distinguishes_repeated_hour(self):
        result = snapshot(["America/New_York"], now=datetime(2026, 11, 1, 6, 30, tzinfo=timezone.utc))
        self.assertEqual(result["currentColumn"], 2)

    def test_other_date_keeps_current_home_hour(self):
        result = snapshot(["Australia/Adelaide"], day_offset=2, now=datetime(2026, 10, 1, 21, 45, tzinfo=timezone.utc))
        self.assertEqual(result["rows"][0]["cells"][result["currentColumn"]]["time"], "07:00")

    def test_half_hour_range_endpoints_across_midnight(self):
        rows = snapshot(["Australia/Adelaide", "Asia/Kathmandu"], now=datetime(2026, 10, 2, tzinfo=timezone.utc))["rows"]
        self.assertEqual(len(rows[0]["boundaries"]), 51)
        self.assertEqual(rows[0]["boundaries"][47]["time"], "23:30")
        self.assertEqual(rows[0]["boundaries"][48]["time"], "00:00")
        self.assertEqual(rows[1]["boundaries"][1]["time"], "20:45")
        self.assertEqual(rows[0]["boundaries"][50]["epoch"], rows[1]["boundaries"][50]["epoch"])

    def test_half_hour_endpoints_across_dst_gap(self):
        row = snapshot(["America/New_York"], now=datetime(2026, 3, 8, 12, tzinfo=timezone.utc))["rows"][0]
        self.assertEqual(row["boundaries"][3]["time"], "01:30")
        self.assertEqual(row["boundaries"][4]["time"], "03:00")
        self.assertEqual(row["boundaries"][4]["epoch"] - row["boundaries"][3]["epoch"], 1800)
