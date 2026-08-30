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

import jwt from 'jsonwebtoken';
import { partnerStore } from '../db/partnerStore';
import { config } from '../config';

export interface LoginResult {
  token: string;
  partnerId: string;
}

// Partner login by userId prefix only (e.g. "EXAMPLE" in "EXAMPLE-001") — no
// password check. This is intentional: this reference app's login exists so a
// partner can try the app locally with just a userId; it is not a general
// credential-verification pattern to copy into a production integration.
export async function login(userId: string): Promise<LoginResult> {
  const dashIndex = userId.indexOf('-');
  if (dashIndex < 1) throw new Error('INVALID_USER_ID');

  const partnerId = userId.substring(0, dashIndex).toUpperCase();
  const partner = await partnerStore().get(partnerId);
  if (!partner) throw new Error('INVALID_CREDENTIALS');

  const token = jwt.sign({ userId, partnerId }, config.jwtSecret, { expiresIn: '24h' });
  return { token, partnerId };
}
