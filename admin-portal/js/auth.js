// ─── Authentication Module ────────────────────────────────────────────────────
import { auth, db } from './firebase-config.js';
import {
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";
import { doc, getDoc } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";
import { showToast } from './utils.js';

export let currentUser = null;

export async function verifyAdmin(uid) {
  const adminDoc = await getDoc(doc(db, 'Admins', uid));
  return adminDoc.exists();
}

export function initAuth(onAuthenticated, onUnauthenticated) {
  onAuthStateChanged(auth, async (user) => {
    if (user) {
      const isAdmin = await verifyAdmin(user.uid);
      if (isAdmin) {
        currentUser = user;
        onAuthenticated(user);
      } else {
        await signOut(auth);
        showToast('Access denied. Admin privileges required.', 'error');
        onUnauthenticated();
      }
    } else {
      currentUser = null;
      onUnauthenticated();
    }
  });
}

export async function login(email, password) {
  const cred = await signInWithEmailAndPassword(auth, email, password);
  const isAdmin = await verifyAdmin(cred.user.uid);
  if (!isAdmin) {
    await signOut(auth);
    throw new Error('This account does not have admin privileges.');
  }
  return cred.user;
}

export async function logout() {
  await signOut(auth);
}
