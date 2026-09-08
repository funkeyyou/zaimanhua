// Render the editable SVG into platform assets. Requires sharp (or a modules path).
// node tools/generate_brand_icons.cjs [path/to/node_modules]
const fs = require('node:fs/promises');
const path = require('node:path');
const sharp = require(require.resolve('sharp', { paths: process.argv[2] ? [process.argv[2]] : [__dirname] }));
const root = path.resolve(__dirname, '..');

async function render(svg, target, size) {
  const destination = path.join(root, target);
  await fs.mkdir(path.dirname(destination), { recursive: true });
  await sharp(Buffer.from(svg)).resize(size, size).png().toFile(destination);
}

async function main() {
  const source = await fs.readFile(path.join(root, 'assets/brand/zaimanhua-x.svg'), 'utf8');
  const foreground = source.replace(/<rect id="background"[^>]*\/>/, '');
  await render(source, 'assets/images/zaimanhua_x.png', 512);
  await render(source, 'assets/brand/zaimanhua-x-1024.png', 1024);
  await render(source, 'android/app/src/main/res/playstore-icon.png', 512);
  const densities = { ldpi: .75, mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
  for (const [density, scale] of Object.entries(densities)) {
    await render(source, `android/app/src/main/res/mipmap-${density}/ic_launcher.png`, 48 * scale);
    await render(foreground, `android/app/src/main/res/mipmap-${density}/ic_launcher_foreground.png`, 108 * scale);
  }
  // Windows supports PNG-compressed icon frames. Keep sizes for crisp scaling.
  const sizes = [16, 24, 32, 48, 64, 128, 256];
  const frames = await Promise.all(sizes.map(size => sharp(Buffer.from(source)).resize(size, size).png().toBuffer()));
  const header = Buffer.alloc(6 + 16 * sizes.length);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(sizes.length, 4);
  let offset = header.length;
  for (let i = 0; i < frames.length; i++) {
    const at = 6 + i * 16;
    header[at] = header[at + 1] = sizes[i] === 256 ? 0 : sizes[i];
    header.writeUInt16LE(1, at + 4);
    header.writeUInt16LE(32, at + 6);
    header.writeUInt32LE(frames[i].length, at + 8);
    header.writeUInt32LE(offset, at + 12);
    offset += frames[i].length;
  }
  await fs.writeFile(path.join(root, 'windows/runner/resources/app_icon.ico'), Buffer.concat([header, ...frames]));
  console.log('Generated app artwork, Android legacy/adaptive icons and Windows ICO.');
}

main().catch(error => { console.error(error); process.exitCode = 1; });
