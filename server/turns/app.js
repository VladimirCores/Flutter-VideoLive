var Turn = require('node-turn');
var server = new Turn({
  // set options
  authMech: 'long-term',
  credentials: {
    'hvn-turn-user': "super-hvn-password"
  }
});
server.start();

const express = require('express')
const app = express()
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('FOR TURN PURPOSE ONLY')
})

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`)
})