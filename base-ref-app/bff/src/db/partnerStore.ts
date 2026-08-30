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

import { getDb } from './mongo';

export interface PartnerRecord {
  id: string;
  displayName: string;
  /** Optional cap on the number of distinct users that may claim under this
   *  partner. Unset = unlimited; counted across all statuses (total ever). */
  maxClaims?: number;
}

export interface PartnerStore {
  get(id: string): Promise<PartnerRecord | null>;
  upsert(record: PartnerRecord): Promise<void>;
  list(): Promise<PartnerRecord[]>;
  /** Returns true if a record existed and was deleted, false if there was nothing to delete. */
  delete(id: string): Promise<boolean>;
}

const COLLECTION = 'partners_ref_app_partners';

export class MongoPartnerStore implements PartnerStore {
  async get(id: string): Promise<PartnerRecord | null> {
    return (await getDb().collection<PartnerRecord>(COLLECTION).findOne({ id: id.toUpperCase() }, { projection: { _id: 0 } })) ?? null;
  }
  async upsert(record: PartnerRecord): Promise<void> {
    await getDb().collection<PartnerRecord>(COLLECTION).updateOne(
      { id: record.id.toUpperCase() },
      { $set: { ...record, id: record.id.toUpperCase() } },
      { upsert: true },
    );
  }
  async list(): Promise<PartnerRecord[]> {
    return getDb().collection<PartnerRecord>(COLLECTION).find({}, { projection: { _id: 0 } }).toArray();
  }
  async delete(id: string): Promise<boolean> {
    const result = await getDb().collection<PartnerRecord>(COLLECTION).deleteOne({ id: id.toUpperCase() });
    return result.deletedCount > 0;
  }
}

export class InMemoryPartnerStore implements PartnerStore {
  private m = new Map<string, PartnerRecord>();
  async get(id: string) { return this.m.get(id.toUpperCase()) ?? null; }
  async upsert(r: PartnerRecord) {
    const id = r.id.toUpperCase();
    // Merge (like Mongo $set) so fields omitted on update — e.g. maxClaims — are preserved.
    this.m.set(id, { ...this.m.get(id), ...r, id });
  }
  async list() { return [...this.m.values()]; }
  async delete(id: string) { return this.m.delete(id.toUpperCase()); }
}

let store: PartnerStore = new MongoPartnerStore();
export function setPartnerStore(s: PartnerStore): void { store = s; }
export function partnerStore(): PartnerStore { return store; }
