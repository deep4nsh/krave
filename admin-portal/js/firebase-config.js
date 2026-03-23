// Firebase Configuration for Krave Admin Portal
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyD1OSbRqEgl6JtNYVhgu0ueze_ZgcYNzVQ",
  authDomain: "krave-124.firebaseapp.com",
  projectId: "krave-124",
  storageBucket: "krave-124.firebasestorage.app",
  messagingSenderId: "325148399429",
  appId: "1:325148399429:web:6a4a9ee9a10b4d1272102c",
  measurementId: "G-C13MDTSHSY"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
