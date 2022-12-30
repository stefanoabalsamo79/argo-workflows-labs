const fs = require('fs')
const { Pool } = require('pg')

const { INPUT_DIR, FILE_TO_PROCESS, POSTGRESDB_IP, POSTGRESDB_PORT } = process.env
console.log('env: ', process.env)

const createTable = async client => {
  const stmt = `
  CREATE TABLE IF NOT EXISTS "users" (
    "uid" VARCHAR(50) NOT NULL,
    "name" VARCHAR(50) NOT NULL,
    "age" NUMERIC NOT NULL
  );`
  try {   
    const res = await client.query(stmt)
    console.log('Table creation res:', res);
  } catch (error) {
    console.error(error.stack)
    return false
  }
}

const main = async () => {

  const pool = new Pool({
    user: 'admin',
    host: POSTGRESDB_IP,
    database: 'postgresdb',
    password: 'psltest',
    port: Number(POSTGRESDB_PORT),
  })
  const client = await pool.connect()
  await createTable(client)

  const res = await client.query('SELECT COUNT(*) from users')
  const [ { count } ] = res.rows
  console.log('row counter: ', count)

  const filename = `${INPUT_DIR}/${FILE_TO_PROCESS}`
  let data
  try {
    data = fs.readFileSync(filename, 'utf8');
    // console.log(data);
  } catch (err) {
    throw err
  }

  Object.entries(JSON.parse(data)).forEach(async ([key, value]) => {
    const { uid, name, age } = value
    // console.log({ uid, name, age })

    await client.query('INSERT INTO users (uid, name, age) VALUES ($1, $2, $3)', [uid, name, age], (err, res) => {  
      client.query('COMMIT', (err) => {
        if (err) console.error('Error committing transaction', err.stack)
      })
    }) 
  })
  client.release()  
}

main().then(console.log).catch(console.error)







