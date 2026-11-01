// Runs against the local Firestore emulator:
//   firebase emulators:exec --only firestore --project demo-med-reminder "npm --prefix test/firestore_rules test"
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';

import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, setDoc, deleteDoc } from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-med-reminder',
    firestore: {
      rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: 8085,
    },
  });
});

after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();

/** Alice creates a family the way the app does. */
async function aliceCreatesFamily(hid = 'home1', code = 'CODE1234') {
  const a = db('alice');
  await assertSucceeds(setDoc(doc(a, 'households', hid), { createdBy: 'alice' }));
  await assertSucceeds(setDoc(doc(a, 'households', hid, 'members', 'alice'), { code: null }));
  await assertSucceeds(setDoc(doc(a, 'joinCodes', code), { householdId: hid, createdBy: 'alice' }));
  await assertSucceeds(setDoc(doc(a, 'households', hid, 'medicines', 'm1'), { data: { name: 'Panadol' } }));
}

test('the creator can set up a family and use it', async () => {
  await aliceCreatesFamily();
  await assertSucceeds(getDoc(doc(db('alice'), 'households', 'home1', 'medicines', 'm1')));
});

test('a phone with the right code can join and share data', async () => {
  await aliceCreatesFamily();
  const b = db('bob');
  await assertSucceeds(getDoc(doc(b, 'joinCodes', 'CODE1234')));
  await assertSucceeds(setDoc(doc(b, 'households', 'home1', 'members', 'bob'), { code: 'CODE1234' }));
  await assertSucceeds(getDocs(collection(b, 'households', 'home1', 'medicines')));
  await assertSucceeds(setDoc(doc(b, 'households', 'home1', 'logs', 'm1_1'), { status: 'taken' }));
});

test('outsiders cannot read or write family data', async () => {
  await aliceCreatesFamily();
  const m = db('mallory');
  await assertFails(getDoc(doc(m, 'households', 'home1')));
  await assertFails(getDocs(collection(m, 'households', 'home1', 'medicines')));
  await assertFails(setDoc(doc(m, 'households', 'home1', 'logs', 'x'), { status: 'taken' }));
  await assertFails(getDoc(doc(db(null), 'households', 'home1', 'medicines', 'm1')));
});

test('joining needs a code that belongs to that family', async () => {
  await aliceCreatesFamily('home1', 'CODE1234');
  await aliceCreatesFamily('home2', 'OTHER567');
  const m = db('mallory');
  await assertFails(setDoc(doc(m, 'households', 'home1', 'members', 'mallory'), { code: null }));
  await assertFails(setDoc(doc(m, 'households', 'home1', 'members', 'mallory'), { code: 'WRONG000' }));
  await assertFails(setDoc(doc(m, 'households', 'home1', 'members', 'mallory'), { code: 'OTHER567' }));
});

test('a phone can only add itself as a member', async () => {
  await aliceCreatesFamily();
  await assertFails(setDoc(doc(db('bob'), 'households', 'home1', 'members', 'carol'), { code: 'CODE1234' }));
});

test('outsiders cannot mint codes for a family or list codes', async () => {
  await aliceCreatesFamily();
  const m = db('mallory');
  await assertFails(setDoc(doc(m, 'joinCodes', 'EVIL0000'), { householdId: 'home1', createdBy: 'mallory' }));
  await assertFails(getDocs(collection(m, 'joinCodes')));
});

test('codes and memberships cannot be rewritten', async () => {
  await aliceCreatesFamily();
  const a = db('alice');
  await assertFails(setDoc(doc(a, 'joinCodes', 'CODE1234'), { householdId: 'home2', createdBy: 'alice' }));
  await assertFails(setDoc(doc(a, 'households', 'home1'), { createdBy: 'mallory' }));
});

test('a member can leave', async () => {
  await aliceCreatesFamily();
  const b = db('bob');
  await assertSucceeds(setDoc(doc(b, 'households', 'home1', 'members', 'bob'), { code: 'CODE1234' }));
  await assertSucceeds(deleteDoc(doc(b, 'households', 'home1', 'members', 'bob')));
  await assertFails(getDocs(collection(b, 'households', 'home1', 'medicines')));
});
