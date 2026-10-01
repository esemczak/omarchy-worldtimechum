const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const selection = {};
vm.createContext(selection);
vm.runInContext(fs.readFileSync(require('node:path').join(__dirname, '../Selection.js'), 'utf8'), selection);

test('snaps pointer to half-hour slots and clamps outside the timeline', () => {
    assert.equal(selection.slotAt(0, 60), 0);
    assert.equal(selection.slotAt(29.9, 60), 0);
    assert.equal(selection.slotAt(30, 60), 1);
    assert.equal(selection.slotAt(-30, 60), 0);
    assert.equal(selection.slotAt(1500, 60), 49);
});
test('click selects thirty minutes', () => {
    const range = selection.rangeFrom(15, 15);
    assert.equal(range.start, 15);
    assert.equal(range.end, 16);
});
test('forward and reverse drags produce the same ordered range', () => {
    for (const [anchor, cursor] of [[15, 20], [20, 15]]) {
        const range = selection.rangeFrom(anchor, cursor);
        assert.equal(range.start, 15);
        assert.equal(range.end, 21);
    }
});
test('last half hour ends at the final boundary', () => {
    assert.equal(selection.rangeFrom(49, 49).end, 50);
});

test('edge resize snaps to nearest half hour', () => {
    assert.equal(selection.boundaryAt(44, 60), 1);
    assert.equal(selection.boundaryAt(46, 60), 2);
    assert.equal(selection.boundaryAt(-100, 60), 0);
    assert.equal(selection.boundaryAt(2000, 60), 50);
});
test('edge detection distinguishes handles from a new selection', () => {
    assert.equal(selection.edgeAt(301, 60, 10, 14, 8), 'start');
    assert.equal(selection.edgeAt(418, 60, 10, 14, 8), 'end');
    assert.equal(selection.edgeAt(360, 60, 10, 14, 8), '');
    assert.equal(selection.edgeAt(0, 60, -1, -1, 8), '');
});
test('left edge holds right edge fixed and cannot cross it', () => {
    const extended = selection.resizeRange(10, 14, 'start', 8);
    assert.equal(extended.start, 8);
    assert.equal(extended.end, 14);
    const crossed = selection.resizeRange(10, 14, 'start', 20);
    assert.equal(crossed.start, 13);
    assert.equal(crossed.end, 14);
});
test('right edge holds left edge fixed and clamps to timeline', () => {
    const extended = selection.resizeRange(10, 14, 'end', 60);
    assert.equal(extended.start, 10);
    assert.equal(extended.end, 50);
    const crossed = selection.resizeRange(10, 14, 'end', 5);
    assert.equal(crossed.start, 10);
    assert.equal(crossed.end, 11);
});
