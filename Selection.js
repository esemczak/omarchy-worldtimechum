// Half-hour slots are inclusive under the pointer; the range end is exclusive.
function durationLabel(start, end) {
    if (start < 0 || end <= start) return "";
    var minutes = (end - start) * 30;
    var hours = Math.floor(minutes / 60);
    var remainder = minutes % 60;
    return (hours ? hours + "h" : "") + (hours && remainder ? " " : "") + (remainder ? remainder + "m" : "");
}

function slotAt(x, hourWidth) {
    return Math.max(0, Math.min(49, Math.floor(x / (hourWidth / 2))));
}

function rangeFrom(anchor, cursor) {
    return { start: Math.min(anchor, cursor), end: Math.max(anchor, cursor) + 1 };
}

function boundaryAt(x, hourWidth) {
    return Math.max(0, Math.min(50, Math.round(x / (hourWidth / 2))));
}

function edgeAt(x, hourWidth, start, end, tolerance) {
    if (start < 0) return "";
    var left = Math.abs(x - start * hourWidth / 2);
    var right = Math.abs(x - end * hourWidth / 2);
    if (Math.min(left, right) > tolerance) return "";
    return left <= right ? "start" : "end";
}

function resizeRange(start, end, edge, boundary) {
    if (edge === "start") return { start: Math.max(0, Math.min(end - 1, boundary)), end: end };
    return { start: start, end: Math.min(50, Math.max(start + 1, boundary)) };
}
