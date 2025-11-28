const aseprite = require('aseprite-cli').instance([
  '/Users/james/Documents/growletters/aseprite_from_steam',
  'aseprite',
]);
const fs = require('fs/promises');
const path = require('path');

async function exportAsepriteToPng(inputFile, outputFile) {
  try {
    await aseprite.exec(inputFile, ['--save-as', outputFile]);
    console.log(`Successfully exported ${inputFile} to ${outputFile}`);
  } catch (error) {
    console.error(`Error exporting ${inputFile}:`, error);
  }
}

async function exportAllInDirectory(dirPath) {
  const entries = await fs.readdir(dirPath, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);
    if (entry.isDirectory()) {
      await exportAllInDirectory(fullPath);
      continue;
    }

    if (entry.isFile() && entry.name.toLowerCase().endsWith('.aseprite')) {
      const outputPath = fullPath.replace(/\.aseprite$/i, '.png');
      await exportAsepriteToPng(fullPath, outputPath);
    }
  }
}

async function run() {
  const assetsDir = path.join(__dirname, 'assets');
  try {
    await exportAllInDirectory(assetsDir);
  } catch (error) {
    console.error('Failed to export aseprite assets:', error);
    process.exitCode = 1;
  }
}

if (require.main === module) {
  run();
}

module.exports = {
  exportAsepriteToPng,
  exportAllInDirectory,
};
