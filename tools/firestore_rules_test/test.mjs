// Pruebas de firestore.rules contra el emulador local (no toca el proyecto real).
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';
import 'firebase/compat/firestore';

const rules = readFileSync(process.argv[2] ?? 'firestore.rules', 'utf8');
const env = await initializeTestEnvironment({
  projectId: 'demo-rules',
  firestore: { rules, host: '127.0.0.1', port: 8085 },
});

const FV = firebase.firestore.FieldValue;
const TS = firebase.firestore.Timestamp;
const birth = TS.fromDate(new Date(Date.UTC(2000, 4, 1)));

function ctx(uid, { provider = 'password', verified = false, email } = {}) {
  return env
    .authenticatedContext(uid, {
      email: email ?? `${uid}@correo.com`,
      email_verified: verified,
      firebase: { sign_in_provider: provider },
    })
    .firestore();
}

function emailProfile(uid, extra = {}) {
  return {
    uid,
    nombre: 'Ana',
    apellido: 'Pérez',
    dni: '12345678',
    fechaNacimiento: birth,
    telefono: '987654321',
    correo: `${uid}@correo.com`,
    registroCompleto: false,
    createdAt: FV.serverTimestamp(),
    updatedAt: FV.serverTimestamp(),
    ...extra,
  };
}

function googleProfile(uid, extra = {}) {
  return {
    uid,
    nombre: 'Lucía',
    apellido: '',
    correo: `${uid}@correo.com`,
    registroCompleto: false,
    createdAt: FV.serverTimestamp(),
    updatedAt: FV.serverTimestamp(),
    ...extra,
  };
}

async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (c) => {
    await c.firestore().doc(path).set(data);
  });
}

function emailCreate(db, uid, data) {
  const b = db.batch();
  b.set(db.doc(`users/${uid}`), data);
  b.set(db.doc(`dnis/${data.dni}`), { uid });
  return b.commit();
}

function googleComplete(db, uid, { dni = '87654321', telefono = '912345678' } = {}) {
  const b = db.batch();
  const upd = {
    nombre: 'Lucía',
    apellido: 'Torres',
    dni,
    fechaNacimiento: birth,
    registroCompleto: true,
    updatedAt: FV.serverTimestamp(),
  };
  if (telefono !== null) upd.telefono = telefono;
  b.update(db.doc(`users/${uid}`), upd);
  b.set(db.doc(`dnis/${dni}`), { uid });
  return b.commit();
}

const results = [];
async function check(name, expectOk, fn) {
  try {
    await (expectOk ? assertSucceeds(fn()) : assertFails(fn()));
    results.push(['OK  ', name]);
  } catch (e) {
    results.push(['FAIL', `${name} → ${e.message.split('\n')[0]}`]);
  }
}

// --- Registro por correo ------------------------------------------------------
await env.clearFirestore();
await check('correo: alta con teléfono válido', true, () =>
  emailCreate(ctx('e1'), 'e1', emailProfile('e1')));
await check('correo: alta sin teléfono', false, () => {
  const d = emailProfile('e2', { dni: '22222222' });
  delete d.telefono;
  return emailCreate(ctx('e2'), 'e2', d);
});
await check('correo: teléfono de 8 dígitos', false, () =>
  emailCreate(ctx('e3'), 'e3', emailProfile('e3', { dni: '33333333', telefono: '98765432' })));
await check('correo: teléfono de 10 dígitos', false, () =>
  emailCreate(ctx('e3'), 'e3', emailProfile('e3', { dni: '33333333', telefono: '9876543210' })));
await check('correo: teléfono con letras', false, () =>
  emailCreate(ctx('e3'), 'e3', emailProfile('e3', { dni: '33333333', telefono: '98765432a' })));
await check('correo: guardar contraseña en el perfil', false, () =>
  emailCreate(ctx('e4'), 'e4', emailProfile('e4', { dni: '44444444', password: 'x' })));
await check('correo: alta ya completa', false, () =>
  emailCreate(ctx('e5'), 'e5', emailProfile('e5', { dni: '55555555', registroCompleto: true })));
await check('correo: DNI ya reservado por otro', false, () =>
  emailCreate(ctx('e6'), 'e6', emailProfile('e6')));
await check('correo: completar sin verificar el correo', false, () =>
  ctx('e1').doc('users/e1').update({ registroCompleto: true, updatedAt: FV.serverTimestamp() }));
await check('correo: completar con correo verificado', true, () =>
  ctx('e1', { verified: true }).doc('users/e1').update({ registroCompleto: true, updatedAt: FV.serverTimestamp() }));
await check('correo: volver registroCompleto a false', false, () =>
  ctx('e1', { verified: true }).doc('users/e1').update({ registroCompleto: false, updatedAt: FV.serverTimestamp() }));
await check('cuenta Google no puede usar el alta por correo', false, () =>
  emailCreate(ctx('e7', { provider: 'google.com', verified: true }), 'e7', emailProfile('e7', { dni: '77777777' })));

// --- Perfil y teléfono ----------------------------------------------------------
await check('perfil: actualizar teléfono válido', true, () =>
  ctx('e1').doc('users/e1').update({ nombre: 'Ana', apellido: 'Pérez', telefono: '923456789', updatedAt: FV.serverTimestamp() }));
await check('perfil: teléfono inválido', false, () =>
  ctx('e1').doc('users/e1').update({ telefono: '123', updatedAt: FV.serverTimestamp() }));
await check('perfil: modificar DNI', false, () =>
  ctx('e1').doc('users/e1').update({ dni: '99999999', updatedAt: FV.serverTimestamp() }));
await check('perfil: modificar correo', false, () =>
  ctx('e1').doc('users/e1').update({ correo: 'otro@correo.com', updatedAt: FV.serverTimestamp() }));
await check('perfil: leer el propio', true, () => ctx('e1').doc('users/e1').get());
await check('perfil: leer el de otro usuario', false, () => ctx('e9').doc('users/e1').get());
await check('perfil: listar usuarios', false, () => ctx('e1').collection('users').get());
await check('sin sesión: leer perfil', false, () =>
  env.unauthenticatedContext().firestore().doc('users/e1').get());

await seed('users/old', {
  uid: 'old', nombre: 'Ana', apellido: 'Pérez', dni: '10101010', fechaNacimiento: birth,
  correo: 'old@correo.com', registroCompleto: true,
});
await check('antiguo sin teléfono: lectura', true, () => ctx('old').doc('users/old').get());
await check('antiguo sin teléfono: cambiar nombre', true, () =>
  ctx('old').doc('users/old').update({ nombre: 'Anita', updatedAt: FV.serverTimestamp() }));
await check('antiguo sin teléfono: añadir teléfono', true, () =>
  ctx('old').doc('users/old').update({ telefono: '934567890', updatedAt: FV.serverTimestamp() }));

// --- Google ---------------------------------------------------------------------
const g = (uid, verified = true) => ctx(uid, { provider: 'google.com', verified });
await check('google: perfil inicial', true, () => g('g1').doc('users/g1').set(googleProfile('g1')));
await check('google: perfil inicial sin correo verificado', false, () =>
  g('g2', false).doc('users/g2').set(googleProfile('g2')));
await check('google: perfil inicial ya completo', false, () =>
  g('g3').doc('users/g3').set(googleProfile('g3', { registroCompleto: true })));
await check('google: perfil inicial con DNI inventado', false, () =>
  g('g4').doc('users/g4').set(googleProfile('g4', { dni: '44444441' })));
await check('google: correo distinto al del token', false, () =>
  g('g5').doc('users/g5').set(googleProfile('g5', { correo: 'x@correo.com' })));
await check('google: marcar completo sin datos', false, () =>
  g('g1').doc('users/g1').update({ nombre: 'Lucía', apellido: 'Torres', registroCompleto: true, updatedAt: FV.serverTimestamp() }));
await check('google: completar sin teléfono', false, () =>
  googleComplete(g('g1'), 'g1', { telefono: null }));
await check('google: completar con DNI ya reservado', false, () =>
  googleComplete(g('g1'), 'g1', { dni: '12345678' }));
await check('google: completar perfil', true, () => googleComplete(g('g1'), 'g1'));
await check('google: cambiar DNI después de completar', false, () =>
  g('g1').doc('users/g1').update({ dni: '11112222', updatedAt: FV.serverTimestamp() }));

await seed('users/g6', { uid: 'g6', nombre: '', apellido: '', correo: 'g6@correo.com', registroCompleto: false });
await check('google: eliminar perfil pendiente sin DNI', true, () => g('g6').doc('users/g6').delete());
await check('perfil completo no se puede eliminar', false, () => g('g1').doc('users/g1').delete());

await env.cleanup();
for (const [s, n] of results) console.log(s, n);
const failed = results.filter(([s]) => s === 'FAIL').length;
console.log(`\n${results.length - failed}/${results.length} comprobaciones correctas`);
process.exit(failed ? 1 : 0);
