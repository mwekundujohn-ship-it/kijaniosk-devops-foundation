import { createServer, IncomingMessage, ServerResponse } from 'http';
import { readFileSync } from 'fs';
import { join } from 'path';
import { calculateTotal, LineItem } from './payments';

function resolveVersion(): string {
  if (process.env.APP_VERSION) {
    return process.env.APP_VERSION;
  }
  try {
    const manifest = JSON.parse(readFileSync(join(__dirname, '..', 'package.json'), 'utf8'));
    return String(manifest.version);
  } catch {
    return 'unknown';
  }
}

const version = resolveVersion();
const port = Number(process.env.PORT ?? 3001);

function sendJson(res: ServerResponse, status: number, body: unknown): void {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'content-type': 'application/json',
    'content-length': Buffer.byteLength(payload),
  });
  res.end(payload);
}

const server = createServer((req: IncomingMessage, res: ServerResponse) => {
  const url = req.url ?? '/';

  if (req.method === 'GET' && url === '/health') {
    sendJson(res, 200, { status: 'ok', service: 'kk-payments', version });
    return;
  }

  if (req.method === 'POST' && url === '/total') {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
    });
    req.on('end', () => {
      try {
        const items = JSON.parse(body) as LineItem[];
        if (!Array.isArray(items)) {
          throw new Error('expected an array of line items');
        }
        sendJson(res, 200, { total: calculateTotal(items) });
      } catch {
        sendJson(res, 400, { error: 'invalid request body' });
      }
    });
    return;
  }

  sendJson(res, 404, { error: 'not found' });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`kk-payments ${version} listening on port ${port}`);
});

for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, () => {
    server.close(() => process.exit(0));
  });
}
