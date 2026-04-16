import { initializeApp } from 'https://www.gstatic.com/firebasejs/12.7.0/firebase-app.js';
import {
  getAuth,
  signInWithEmailAndPassword,
} from 'https://www.gstatic.com/firebasejs/12.7.0/firebase-auth.js';
import {
  getFunctions,
  httpsCallable,
} from 'https://www.gstatic.com/firebasejs/12.7.0/firebase-functions.js';

import { createFirebaseTizenBridge } from './firebase_tizen_bridge_core.mjs';

globalThis.firebaseTizenBridge = createFirebaseTizenBridge({
  initializeApp,
  getAuth,
  signInWithEmailAndPassword,
  getFunctions,
  httpsCallable,
});
