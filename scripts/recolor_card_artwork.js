const fs = require("fs");
const path = require("path");
const { PNG } = require("pngjs");

const artworkRoot = path.resolve("assets/cards/art");
const outline = [0x29, 0x36, 0x5f];
const saturationMultiplier = 0.75;
const blackThreshold = 30;

function pngFiles(directory) {
  return fs.readdirSync(directory, { withFileTypes: true })
    .flatMap((entry) => {
      const filePath = path.join(directory, entry.name);
      if (entry.isDirectory()) return pngFiles(filePath);
      return entry.isFile() && entry.name.toLowerCase().endsWith(".png") ? [filePath] : [];
    });
}

function desaturate(red, green, blue) {
  const value = (Math.max(red, green, blue) + Math.min(red, green, blue)) / 2;
  return [red, green, blue].map((channel) =>
    Math.round(value + (channel - value) * saturationMultiplier),
  );
}

function recolor(filePath) {
  const png = PNG.sync.read(fs.readFileSync(filePath));
  let outlinePixels = 0;
  for (let offset = 0; offset < png.data.length; offset += 4) {
    if (png.data[offset + 3] === 0) continue;
    const red = png.data[offset];
    const green = png.data[offset + 1];
    const blue = png.data[offset + 2];
    const replacement = Math.max(red, green, blue) <= blackThreshold
      ? outline
      : desaturate(red, green, blue);
    if (replacement === outline) outlinePixels += 1;
    [png.data[offset], png.data[offset + 1], png.data[offset + 2]] = replacement;
  }
  const temporaryPath = path.join(path.dirname(filePath), `.${path.basename(filePath)}.palette-tmp`);
  fs.writeFileSync(temporaryPath, PNG.sync.write(png));
  fs.renameSync(temporaryPath, filePath);
  return outlinePixels;
}

const files = pngFiles(artworkRoot).sort();
const outlinePixels = files.reduce((total, filePath) => total + recolor(filePath), 0);
console.log(`Updated ${files.length} card-art PNGs; recolored ${outlinePixels} opaque near-black pixels to #29365F and reduced saturation by 25%.`);
