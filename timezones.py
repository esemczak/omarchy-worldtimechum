"""Offline timezone calculations using the operating system's IANA database."""
import json
import sys
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo, available_timezones


def snapshot(zones, day_offset=0, now=None):
    now = now or datetime.now(timezone.utc)
    valid = [z for z in zones if z in available_timezones()][:12]
    if not valid:
        valid = ["Australia/Adelaide"]
    home = now.astimezone(ZoneInfo(valid[0]))
    day = home.date() + timedelta(days=day_offset)
    start = datetime(day.year, day.month, day.day, tzinfo=ZoneInfo(valid[0])).astimezone(timezone.utc)
    # Elapsed hours, rather than wall-clock arithmetic, keep DST gaps/repeats honest.
    hours = [start + timedelta(hours=i) for i in range(25)]
    rows = []
    for name in valid:
        zone = ZoneInfo(name)
        local = now.astimezone(zone)
        cells = []
        for instant in hours:
            t = instant.astimezone(zone)
            cells.append(dict(time=t.strftime("%H:%M"), date=t.strftime("%a %d %b"),
                              label=t.strftime("%a %d %b %Y, %H:%M %Z"),
                              work=9 <= t.hour < 17 and t.weekday() < 5,
                              awake=7 <= t.hour < 22, weekend=t.weekday() >= 5,
                              epoch=int(instant.timestamp()), offset=t.strftime("%z")))
        rows.append(dict(zone=name, city=name.split("/")[-1].replace("_", " "),
                         time=local.strftime("%H:%M"), abbreviation=local.tzname(),
                         date=local.strftime("%a %d %b"), cells=cells))
    current_column = next((i for i, t in enumerate(hours[:-1])
                           if t <= now < t + timedelta(hours=1)), None)
    if current_column is None:
        current_column = min(range(25), key=lambda i: abs(
            (hours[i].astimezone(ZoneInfo(valid[0])).hour * 60
             + hours[i].astimezone(ZoneInfo(valid[0])).minute)
            - (home.hour * 60 + home.minute)))
    return dict(date=day.strftime("%A, %d %B %Y"), rows=rows, currentColumn=current_column,
                catalog=sorted(z for z in available_timezones() if "/" in z and not z.startswith(("posix/", "right/"))))


if __name__ == "__main__":
    try:
        print(json.dumps(snapshot(json.loads(sys.argv[1]), int(sys.argv[2]))))
    except (ValueError, TypeError, IndexError) as exc:
        print(json.dumps({"error": str(exc)}))
        sys.exit(1)
