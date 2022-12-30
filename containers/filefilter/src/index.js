const fs = require('fs');

const { INPUT_DIR, FILE_TO_PROCESS, TMP_DIR } = process.env
console.log('env: ', process.env)

const filename = `${INPUT_DIR}/${FILE_TO_PROCESS}`

let data
try {
  data = fs.readFileSync(filename, 'utf8');
  // console.log(data);
} catch (err) {
  console.error(err);
  throw err
}

const filteredObjData = Object.fromEntries(Object.entries(JSON.parse(data)).filter(([key, { age }]) => age > 55));
// console.log('filteredObjData: ', filteredObjData);

fs.writeFileSync(filename, JSON.stringify(filteredObjData,null,'\t'), function (err) {
  if (err) throw err
  console.log(`File [${filename}] successfully updated with the filtered content.`)
})



