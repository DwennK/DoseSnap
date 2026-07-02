export type DecodedImage = {
  bytes: Uint8Array;
  mediaType: string;
};

export function decodeImageBase64(input: string, maxBytes: number): DecodedImage {
  const trimmed = input.trim();
  const match = /^data:(image\/[a-zA-Z0-9.+-]+);base64,(.*)$/.exec(trimmed);
  const mediaType = match?.[1] ?? "image/jpeg";
  const base64 = match?.[2] ?? trimmed;

  if (!["image/jpeg", "image/png", "image/heic", "image/heif", "image/webp"].includes(mediaType)) {
    throw new Error("unsupported_image_type");
  }

  if (estimatedDecodedBytes(base64) > maxBytes) {
    throw new Error("image_too_large");
  }

  const bytes = Uint8Array.from(atob(base64), (character) => character.charCodeAt(0));

  if (bytes.byteLength === 0) {
    throw new Error("empty_image");
  }

  if (bytes.byteLength > maxBytes) {
    throw new Error("image_too_large");
  }

  return { bytes, mediaType };
}

function estimatedDecodedBytes(base64: string): number {
  const normalized = base64.replace(/\s/g, "");
  const padding = normalized.endsWith("==") ? 2 : normalized.endsWith("=") ? 1 : 0;
  return Math.max(0, Math.floor((normalized.length * 3) / 4) - padding);
}

export function toDataUrl(image: DecodedImage): string {
  let binary = "";
  for (const byte of image.bytes) {
    binary += String.fromCharCode(byte);
  }

  return `data:${image.mediaType};base64,${btoa(binary)}`;
}
