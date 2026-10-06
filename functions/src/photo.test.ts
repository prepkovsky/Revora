import assert from "node:assert/strict";
import { describe, test } from "node:test";
import { dataURL, decodePhoto, maxPhotoBytes } from "./photo.js";

function jpeg(size: number): Buffer {
  const bytes = Buffer.alloc(size, 0x41);
  bytes.set([0xff, 0xd8, 0xff, 0xe0]);
  return bytes;
}

describe("decodePhoto", () => {
  test("accepts a JPEG", () => {
    const photo = jpeg(1000);
    assert.deepEqual(decodePhoto(photo.toString("base64")), photo);
  });

  test("accepts a JPEG at the size limit", () => {
    assert.equal(decodePhoto(jpeg(maxPhotoBytes).toString("base64"))?.length, maxPhotoBytes);
  });

  test("rejects a JPEG over the size limit", () => {
    assert.equal(decodePhoto(jpeg(maxPhotoBytes + 1).toString("base64")), null);
  });

  test("rejects other image formats", () => {
    const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    assert.equal(decodePhoto(png.toString("base64")), null);
  });

  test("rejects text that isn't base64", () => {
    const valid = jpeg(30).toString("base64");
    assert.equal(decodePhoto(`${valid.slice(0, -4)}!@#$`), null);
    assert.equal(decodePhoto(valid.slice(0, -1)), null);
    assert.equal(decodePhoto(`data:image/jpeg;base64,${valid}`), null);
  });

  test("rejects anything that isn't a string", () => {
    for (const value of [undefined, null, "", 42, {}, [jpeg(30).toString("base64")]]) {
      assert.equal(decodePhoto(value), null);
    }
  });
});

test("dataURL", () => {
  assert.equal(dataURL(Buffer.from([0xff, 0xd8, 0xff])), "data:image/jpeg;base64,/9j/");
});
