// server.js
const { createServer } = require('https');
const { parse } = require('url');
const next = require('next');
const fs = require('fs');
const path = require('path');

// const dev = process.env.NODE_ENV !== 'production';
const dev = false;
const app = next({ dev });
const handle = app.getRequestHandler();

const stackName = process.env.STACK_NAME;
const domainName = process.env.DOMAIN_NAME;

const certFilePath = path.join(
  '/opt/livekit/caddy_data/certificates/acme-v02.api.letsencrypt.org-directory',
  `${stackName}.${domainName}`,
  `${stackName}.${domainName}.crt`
);

const keyFilePath = path.join(
  '/opt/livekit/caddy_data/certificates/acme-v02.api.letsencrypt.org-directory',
  `${stackName}.${domainName}`,
  `${stackName}.${domainName}.key`
);

const httpsOptions = {
  key: fs.readFileSync(keyFilePath),
  cert: fs.readFileSync(certFilePath)
};

const port = process.env.PORT || 443;

app.prepare().then(() => {
  createServer(httpsOptions, (req, res) => {
    const parsedUrl = parse(req.url, true);
    handle(req, res, parsedUrl);
  }).listen(port, err => {
    if (err) throw err;
    console.log(`> Server started on https://localhost:${port}`);
  });
});
