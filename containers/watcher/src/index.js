const chokidar = require('chokidar')
const axios = require('axios')
const path = require('path')
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const {
  INPUT_DIR,
  TMP_DIR,
  ARGO_SERVER_SERVICE_HOST,
  ARGO_SERVER_SERVICE_PORT,
  ARGO_TOKEN
} = process.env

console.log({ INPUT_DIR, ARGO_SERVER_SERVICE_HOST, ARGO_SERVER_SERVICE_PORT, ARGO_TOKEN });

const callArgoWorkflow = async inputObj => {
  const url = `https://${ARGO_SERVER_SERVICE_HOST}:${ARGO_SERVER_SERVICE_PORT}/api/v1/events/argo/etl`
  const res = await axios({
    method: 'post',
    url,
    headers: {
      "Content-type": "application/json",
      Authorization: `Bearer ${ARGO_TOKEN}`,
      "x-chain-id": "001",
    },
    data: { ...inputObj, message: `Handling file [${inputObj.inputDir}/${inputObj.filename}]` }
  })
  console.log(`status: [${res.status}] data: [${JSON.stringify(res.data || {})}] url: [${url}]`)
}

chokidar.watch(INPUT_DIR)
.on('add', async resource => {
  console.log('******************************************************************');
  const filename = path.basename(resource)
  console.log(`File [${resource}] has been added, calling workflow`)
  const inputObj = { 
    filename, 
    inputDir: INPUT_DIR, 
    tmpDir: TMP_DIR 
  }
  await callArgoWorkflow(inputObj)
})
.on('change', path => console.log(`File [${path}] has been changed, nothing to do`))
.on('unlink', path => console.log(`File [${path}] has been removed, nothing to do`))