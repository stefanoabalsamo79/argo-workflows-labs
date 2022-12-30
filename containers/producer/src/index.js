const fs = require('fs')
const { uuid } = require('uuidv4')
const INPUT_DIR = process.env.INPUT_DIR
const RECORD_NUMBER = process.env.RECORD_NUMBER || 1000
const PRODUCING_FILE_INTERVAL = process.env.PRODUCING_FILE_INTERVAL || 20000

const getFilePath = (path, idx) => `${INPUT_DIR}/${idx++}.txt`
const generateInteger = max => Math.floor(Math.random() * max) + 1

const generateString = (length = 8) => {
   let res = ''
   for(let i = 0; i < length; i++){
      const random = Math.floor(Math.random() * 27)
      res += String.fromCharCode(97 + random)
   }
   return res
}

const getFileContent = () => {
  let fileContentObj = {} 
  const limit = Number(RECORD_NUMBER)
  for (let idx = 0; idx < limit; idx++) {
    const uid = uuid()
    const age = generateInteger(100)
    const name = generateString()
    fileContentObj[uid] = { uid, age, name }
  }
  return JSON.stringify(fileContentObj,null,'\t')
}

if (!fs.existsSync(INPUT_DIR)) {
  fs.mkdirSync(INPUT_DIR, (err) => {
    if (err) return console.error(err);
    console.log(`Directory [${INPUT_DIR}] created successfully!`)
  })
}

let idx = 0
setInterval(() => {
  const filename = getFilePath(INPUT_DIR, idx++)
  fs.writeFile(filename, getFileContent(), function (err) {
    if (err) throw err
    console.log(`File [${filename}] is created successfully.`)
  })
}, PRODUCING_FILE_INTERVAL)
