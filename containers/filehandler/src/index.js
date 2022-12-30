const fs = require('fs');
const mv = require('mv');

const { INPUT_DIR, FILE_TO_PROCESS, TMP_DIR } = process.env
console.log('env: ', process.env)

if (!fs.existsSync(TMP_DIR)) {
  fs.mkdirSync(TMP_DIR, (err) => {
    if (err) return console.error(err);
    console.log(`Directory [${TMP_DIR}] created successfully!`)
  })
}

const filename = FILE_TO_PROCESS
const srcPath = `${INPUT_DIR}/${filename}`
const trgPath = `${TMP_DIR}/${filename}`
mv(srcPath, trgPath, err => {
  if (err) throw err
  console.log(`File moved from [${srcPath}] to [${trgPath}]`)
});
