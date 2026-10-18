import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

// Config pública del proyecto — no es un secreto (igual que la de
// android/app/google-services.json): lo que protege los datos son las
// reglas de Firestore/Storage, no ocultar esto. Ver docs/SEGURIDAD.md.
const firebaseConfig = {
  projectId: "app-alabanzas",
  appId: "1:568410790350:web:407da050d169cfe8ae339f",
  storageBucket: "app-alabanzas.firebasestorage.app",
  apiKey: "AIzaSyDrzc7nVPa2qt3TAMcGoI3qytgKivAwpiw",
  authDomain: "app-alabanzas.firebaseapp.com",
  messagingSenderId: "568410790350",
};

const app = initializeApp(firebaseConfig);

export const db = getFirestore(app);
export const storage = getStorage(app);
