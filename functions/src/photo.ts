/** The app sends around 1 MiB. Anything far bigger isn't from the app. */
export const maxPhotoBytes = 2 * 1024 * 1024;

const base64Pattern = /^[A-Za-z0-9+/]*={0,2}$/;

/**
 * The JPEG in a request's base64 `image`, or `null` when it isn't one.
 * The length is checked before decoding, so an oversized request is never decoded.
 */
export function decodePhoto(image: unknown): Buffer | null {
  if (typeof image !== "string" || image.length === 0) return null;
  if (image.length > Math.ceil(maxPhotoBytes / 3) * 4) return null;
  // Buffer.from skips characters that aren't base64 instead of failing.
  if (image.length % 4 !== 0 || !base64Pattern.test(image)) return null;

  const bytes = Buffer.from(image, "base64");
  if (bytes.length > maxPhotoBytes || !isJPEG(bytes)) return null;
  return bytes;
}

export function dataURL(jpeg: Buffer): string {
  return `data:image/jpeg;base64,${jpeg.toString("base64")}`;
}

function isJPEG(bytes: Buffer): boolean {
  return bytes.length > 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
}
