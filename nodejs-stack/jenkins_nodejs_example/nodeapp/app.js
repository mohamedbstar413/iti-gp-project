const express = require('express')
const app = express()
const port = 3000
app.get('/', (req, res) => {
    res.send('Hello Abdelrahman')
  })

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', uptime: process.uptime() });
});

app.get('/ready', (req, res) => {
  res.status(200).json({ status: 'READY' });
});

  app.listen(port, () => {
    console.log(`Example app listening at http://localhost:${port}`)
  })
