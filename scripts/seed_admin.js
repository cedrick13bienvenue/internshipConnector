const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });

const auth = getAuth();
const db = getFirestore();

const ADMIN_EMAIL = 'admin@aluconnect.com';
const ADMIN_PASSWORD = 'Admin@2026';
const ADMIN_NAME = 'ALU Admin';

async function seedAdmin() {
  // Delete existing admin user from Auth if it exists
  try {
    const existing = await auth.getUserByEmail(ADMIN_EMAIL);
    await auth.deleteUser(existing.uid);
    console.log(`Deleted existing auth user: ${existing.uid}`);

    // Delete their Firestore doc too
    await db.collection('users').doc(existing.uid).delete();
    console.log('Deleted existing Firestore user doc');
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    console.log('No existing admin user found, creating fresh...');
  }

  // Create new admin auth user
  const newUser = await auth.createUser({
    email: ADMIN_EMAIL,
    password: ADMIN_PASSWORD,
    displayName: ADMIN_NAME,
    emailVerified: true,
  });
  console.log(`Created auth user: ${newUser.uid}`);

  // Write Firestore document
  await db.collection('users').doc(newUser.uid).set({
    email: ADMIN_EMAIL,
    fullName: ADMIN_NAME,
    role: 'admin',
    isOnboarded: true,
    isEmailVerified: true,
    skills: [],
    savedOpportunities: [],
    createdAt: Timestamp.now(),
    photoUrl: null,
    bio: null,
    program: null,
  });
  console.log('Firestore user doc created');

  console.log('\n✓ Admin seeded successfully');
  console.log(`  Email:    ${ADMIN_EMAIL}`);
  console.log(`  Password: ${ADMIN_PASSWORD}`);

  process.exit(0);
}

seedAdmin().catch((e) => {
  console.error('Error:', e.message);
  process.exit(1);
});
