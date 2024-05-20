const express = require('express')
const https = require('https');
const fs = require('fs');
const path = require('path');
const app = express()
const port = 8080

const sslOptions = {
  key: fs.readFileSync(path.join(__dirname, 'ssl', 'key.pem')),
  cert: fs.readFileSync(path.join(__dirname, 'ssl', 'cert.pem'))
};

app.use( "/", [ express.static("./public" ) ] );

https.createServer(sslOptions, app).listen(port, () => {
  console.log(`Example app listening on HTTPS port ${port}`);
});
//app.listen(port, () => {
//  console.log(`Example app listening on port ${port}`)
//})
