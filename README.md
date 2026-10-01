# WorldTimeChum

A native Omarchy shell plugin inspired by World Time Buddy. Click the globe icon in the bar (tooltip: **WorldTimeChum**) to compare cities on a shared 25-hour timeline.

Requires the Quickshell-based Omarchy shell, Python 3, and system tzdata. No accounts, network services, or Python packages are required.

Install with `bash install.sh`. Cities are saved in the widget's `zones` setting in `~/.config/omarchy/shell.json`. The first city is home; its midnight anchors the timeline. Use **Home** to change it. Search/select an IANA zone, such as `Australia/Adelaide`, to add a city (up to 12).

The interface uses Omarchy's native controls, theme font, spacing, and colors. Working hours are subtly tinted and night hours dimmed. After updating an already installed copy, run `omarchy restart shell` if Quickshell retains cached components.

City details sit in a fixed left column, beside vertically aligned time rows. A continuous background tint follows the current home hour and updates each minute. The independent border follows hover, then returns to the clicked selection (or home time if nothing has been selected). On other dates, the tint follows the same home wall-clock hour. Click to save a time for copying.

Time boxes show only hours and minutes. Clicking moves only the outline, leaving the current home-time tint in place. The Copy button copies each city's full selected date and time. Hover and the live home-time highlight do not change what will be copied.

Use **24h / 12h** in the header to change notation for clocks, time boxes, tooltips, and copied times. The preference is saved with the widget settings. In 12-hour mode, AM/PM appears beneath each time.

The popup fills the available width of the monitor containing its bar button, retaining Omarchy's outer margins. Typography, controls, and the city column keep their normal Omarchy sizes; the time boxes expand to use the remaining width. Long city lists scroll vertically, and narrow monitors can scroll horizontally.

Navigate dates with the arrows, click an hour to compare, and copy the selected times to the clipboard. Each tile represents the same instant everywhere. Half-hour/quarter-hour offsets and daylight-saving transitions use the system IANA timezone database. Hover shows the local date and UTC offset, including repeated hours during DST changes.

Keyboard: Escape closes the popup. You can also run `omarchy-shell local.worldtimechum toggle`; the widget also exposes open/close.

Disable with `omarchy plugin disable local.worldtimechum`. Remove with `omarchy plugin remove local.worldtimechum --yes`.

Run the timezone checks with `python3 -m unittest discover -s tests`.

Licensed under the [MIT License](LICENSE).
