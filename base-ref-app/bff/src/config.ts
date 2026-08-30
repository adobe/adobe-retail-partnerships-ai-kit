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

import 'dotenv/config';
import { randomBytes } from 'crypto';

/**
 * Nothing here is boot-fatal. This is the feature-less BASE app — it's meant
 * to run with zero configuration for a first look: any secret not supplied
 * is auto-generated for this process only (ephemeral — a restart generates a
 * new one, so existing JWTs/encrypted values stop working). Set real values
 * in .env once you want stability across restarts or real persistence.
 *
 * The Partner Integration AI Kit skills add the Adobe variables (IMS
 * credentials, Retail API base URL, offer id, the Notify webhook secret) and
 * their own validation when the integration is generated onto this app.
 */
function resolveSecret(envVar: string, label: string): string {
  const value = process.env[envVar]?.trim();
  if (value) return value;
  console.warn(`event=config.warning reason=${envVar}_NOT_CONFIGURED detail="using an ephemeral auto-generated ${label} for this run — set ${envVar} in .env for a stable value across restarts"`);
  return randomBytes(32).toString('hex');
}

if (!process.env.CORS_ORIGINS?.trim()) {
  console.warn('event=config.warning reason=CORS_ORIGINS_NOT_CONFIGURED detail="defaulting to allow-all (*) — set CORS_ORIGINS to restrict"');
}
if (!process.env.MONGODB_URL?.trim()) {
  console.warn('event=config.warning reason=MONGODB_URL_NOT_CONFIGURED detail="no persistent partner store configured — falling back to an in-memory store seeded with a demo partner (see index.ts); set MONGODB_URL for real persistence"');
}

const corsOrigins = (process.env.CORS_ORIGINS ?? '*')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

export const config = {
  // PORT is the only defaulted value — the container + health probes assume 8080.
  port: Number(process.env.PORT ?? 8080),
  mongoUrl: process.env.MONGODB_URL?.trim() || undefined,
  adminAllowedClientIds: (process.env.REFAPP_ADMIN_ALLOWED_CLIENT_IDS ?? '')
    .split(',').map((s) => s.trim()).filter(Boolean),
  jwtSecret: resolveSecret('JWT_SECRET', 'JWT secret'),
  corsOrigins: corsOrigins.includes('*') ? true : corsOrigins,
} as const;
