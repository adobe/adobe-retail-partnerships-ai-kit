/*
Copyright (c) 2026 Adobe. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

import express from 'express';
import cors from 'cors';
import path from 'path';
import { config } from './config';
import { connectMongo } from './db/mongo';
import { InMemoryPartnerStore, setPartnerStore, partnerStore } from './db/partnerStore';
import { healthRouter } from './routes/health';
import { authRouter } from './routes/auth';
import { adminRouter } from './routes/admin';

const app = express();

app.use(express.json());
app.use(cors({ origin: config.corsOrigins }));

// API + health routes take priority over static files
app.use('/', healthRouter);
app.use('/api', authRouter);
app.use('/', adminRouter); // admin routes live at /admin/* (separate gateway-proxied path from /api)

// Serve Flutter web build
const webDir = path.join(__dirname, '..', 'public');
app.use(express.static(webDir));
// SPA fallback — let go_router handle routing client-side
app.get(/.*/, (_req, res) => res.sendFile(path.join(webDir, 'index.html')));

async function start() {
  let persistent = false;
  if (config.mongoUrl) {
    try {
      await connectMongo(config.mongoUrl);
      persistent = true;
    } catch (e) {
      console.error(`event=startup.error reason=MONGO_CONNECT_FAILED detail=${String(e)}`);
    }
  }
  if (!persistent) {
    // No reachable MongoDB — fall back to an in-memory store so the app is
    // still fully usable for a first look, seeded with a demo partner
    // matching the userId hint shown on the login screen (EXAMPLE-001).
    // Data here does not survive a restart; set MONGODB_URL for real
    // persistence (needed once you're implementing/testing features, not
    // just previewing the base app).
    console.warn('event=startup.warning reason=NO_PERSISTENT_STORE detail="using an in-memory partner store seeded with a demo partner"');
    setPartnerStore(new InMemoryPartnerStore());
    await partnerStore().upsert({
      id: 'EXAMPLE',
      displayName: 'Example Partner',
    });
    console.log('event=startup.info detail="seeded demo partner — sign in with userId EXAMPLE-001"');
  }
  app.listen(config.port, () => {
    // eslint-disable-next-line no-console
    console.log(`Partner Ref BFF listening on :${config.port}`);
  });
}
void start().catch((e) => {
  console.error(`event=startup.fatal detail=${String(e)}`);
  process.exitCode = 1;
});
