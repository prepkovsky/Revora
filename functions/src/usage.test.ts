import assert from "node:assert/strict";
import { describe, test } from "node:test";
import { countedScan, dailyScanLimit, nextUTCMidnight, readUsage, refundedScan, utcDay } from "./usage.js";

const now = new Date("2026-10-06T21:30:00Z");

describe("days", () => {
  test("are UTC days", () => {
    assert.equal(utcDay(now), "2026-10-06");
    assert.equal(utcDay(new Date("2026-10-06T23:59:59+02:00")), "2026-10-06");
    assert.equal(utcDay(new Date("2026-10-07T00:30:00+02:00")), "2026-10-06");
  });

  test("reset at the next UTC midnight", () => {
    assert.equal(nextUTCMidnight(now).toISOString(), "2026-10-07T00:00:00.000Z");
    assert.equal(nextUTCMidnight(new Date("2026-10-31T12:00:00Z")).toISOString(), "2026-11-01T00:00:00.000Z");
    assert.equal(nextUTCMidnight(new Date("2026-12-31T23:59:59Z")).toISOString(), "2027-01-01T00:00:00.000Z");
    assert.equal(nextUTCMidnight(new Date("2026-10-07T00:00:00Z")).toISOString(), "2026-10-08T00:00:00.000Z");
  });
});

describe("countedScan", () => {
  test("starts at 1 without a count", () => {
    assert.deepEqual(countedScan(undefined, now), { day: "2026-10-06", count: 1 });
  });

  test("adds to today's count", () => {
    assert.deepEqual(countedScan({ day: "2026-10-06", count: 5 }, now), { day: "2026-10-06", count: 6 });
  });

  test("starts again on a new day", () => {
    assert.deepEqual(countedScan({ day: "2026-10-05", count: dailyScanLimit }, now), {
      day: "2026-10-06",
      count: 1,
    });
  });

  test("allows the last scan and stops after it", () => {
    assert.deepEqual(countedScan({ day: "2026-10-06", count: dailyScanLimit - 1 }, now), {
      day: "2026-10-06",
      count: dailyScanLimit,
    });
    assert.equal(countedScan({ day: "2026-10-06", count: dailyScanLimit }, now), null);
    assert.equal(countedScan({ day: "2026-10-06", count: dailyScanLimit + 3 }, now), null);
  });
});

describe("refundedScan", () => {
  test("gives a scan back on the same day", () => {
    assert.deepEqual(refundedScan({ day: "2026-10-06", count: 3 }, "2026-10-06"), { day: "2026-10-06", count: 2 });
  });

  test("gives nothing back once the day has moved on", () => {
    assert.equal(refundedScan({ day: "2026-10-07", count: 1 }, "2026-10-06"), null);
  });

  test("never goes below zero", () => {
    assert.equal(refundedScan({ day: "2026-10-06", count: 0 }, "2026-10-06"), null);
    assert.equal(refundedScan(undefined, "2026-10-06"), null);
  });
});

describe("readUsage", () => {
  test("reads a stored count", () => {
    const stored = { day: "2026-10-06", count: 4, expiresAt: new Date() };
    assert.deepEqual(readUsage(stored), { day: "2026-10-06", count: 4 });
  });

  test("treats anything else as no count", () => {
    for (const data of [undefined, null, {}, { day: "2026-10-06" }, { day: 1, count: 1 }, { day: "2026-10-06", count: -1 }, { day: "2026-10-06", count: 1.5 }]) {
      assert.equal(readUsage(data), undefined);
    }
  });
});
