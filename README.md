# WorldTimeChum

A native Omarchy shell plugin inspired by World Time Buddy. Click the globe icon in the bar (tooltip: **WorldTimeChum**) to compare cities on a shared 25-hour timeline.

Requires the Quickshell-based Omarchy shell, Python 3, and system tzdata. No accounts, network services, or Python packages are required.

Install with `bash install.sh`. Cities are saved in the widget's `zones` setting in `~/.config/omarchy/shell.json`. The first city is home; its midnight anchors the timeline. Use **Home** to change it. Search/select an IANA zone, such as `Australia/Adelaide`, to add a city (up to 12).

The interface uses Omarchy's native controls, theme font, spacing, and colors. Working hours are subtly tinted and night hours dimmed. After updating an already installed copy, run `omarchy restart shell` if Quickshell retains cached components.

City details sit in a fixed left column, beside vertically aligned time rows. A continuous background tint follows the current home hour and updates each minute. A border appears only when you click or drag to select a range, and stays on that range. Hover alone does not draw or move a border. On other dates, the tint follows the same home wall-clock hour.

A small downward chevron above the timeline tracks the actual home time within the hour, updating each minute independently of selection.

Time boxes show only hours and minutes. Click and drag in either direction to select a range, snapping to 30-minute intervals; a click selects one 30-minute interval. Each hourly box has two selectable halves. The outline marks the range while the current home-time tint stays in place. Hover shows local start and end dates/times. **Copy selected range** copies both endpoints for every city, respecting date changes, daylight saving, and 12h/24h notation. Hover does not change what will be copied.

Drag either selection edge to resize the range without selecting it again. The small grips mark the handles; the pointer changes to a horizontal resize cursor near either edge. Resizing snaps to 30 minutes, keeps the opposite endpoint fixed, and preserves a minimum duration of 30 minutes.

Use **24h / 12h** in the header to change notation for clocks, time boxes, tooltips, and copied times. The preference is saved with the widget settings. In 12-hour mode, AM/PM appears beneath each time.

The popup fills the available width of the monitor containing its bar button, retaining Omarchy's outer margins. Typography, controls, and the city column keep their normal Omarchy sizes; the time boxes expand to use the remaining width. Long city lists scroll vertically, and narrow monitors can scroll horizontally.

Navigate dates with the arrows, click an hour to compare, and copy the selected times to the clipboard. Each tile represents the same instant everywhere. Half-hour/quarter-hour offsets and daylight-saving transitions use the system IANA timezone database. Hover shows the local date and UTC offset, including repeated hours during DST changes.

Keyboard: Escape closes the popup. You can also run `omarchy-shell local.worldtimechum toggle`; the widget also exposes open/close.

Disable with `omarchy plugin disable local.worldtimechum`. Remove with `omarchy plugin remove local.worldtimechum --yes`.

Run the timezone checks with `python3 -m unittest discover -s tests`.
Run the drag-selection checks with `node --test tests/selection.test.cjs` (Node is only needed for these tests).

Licensed under the [MIT License](LICENSE).
