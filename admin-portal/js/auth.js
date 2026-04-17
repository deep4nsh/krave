// ─── Authentication Module ────────────────────────────────────────────────────
import { auth, db } from './firebase-config.js';
import {
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";
import { doc, getDoc } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";
import { showToast } from './utils.js';
import { COLLECTIONS } from './constants.js';

export let currentUser = null;
export let userRole = 'none';

export async function getUserRole(uid) {
  // 1. Check Admin
  const adminDoc = await getDoc(doc(db, 'Admins', uid));
  if (adminDoc.exists()) return 'admin';

  // 2. Check Owner
  const ownerDoc = await getDoc(doc(db, COLLECTIONS.OWNERS, uid));
  if (ownerDoc.exists()) {
    const data = ownerDoc.data();
    return data.status === 'approved' ? 'owner' : 'pendingOwner';
  }

  return 'none';
}

export function initAuth(onAuthenticated, onUnauthenticated) {
  onAuthStateChanged(auth, async (user) => {
    if (user) {
      const role = await getUserRole(user.uid);
      if (role === 'admin' || role === 'owner') {
        currentUser = user;
        userRole = role;
        
        // Fetch extra data for owners (like their canteen ID)
        if (role === 'owner') {
           const ownerDoc = await getDoc(doc(db, COLLECTIONS.OWNERS, user.uid));
           currentUser.canteenId = ownerDoc.data().canteen_id;
        }

        onAuthenticated(user);
      } else {
        await signOut(auth);
        showToast('Access denied. Admin or Owner privileges required.', 'error');
        onUnauthenticated();
      }
    } else {
      currentUser = null;
      userRole = 'none';
      onUnauthenticated();
    }
  });
}

export async function login(email, password) {
  const cred = await signInWithEmailAndPassword(auth, email, password);
  const role = await getUserRole(cred.user.uid);
  if (role !== 'admin' && role !== 'owner') {
    await signOut(auth);
    throw new Error('Access denied. This portal is for Admins and Owners only.');
  }
  return cred.user;
}

export async function logout() {
  await signOut(auth);
}
