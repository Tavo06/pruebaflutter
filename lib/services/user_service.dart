import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/app_exception.dart';
import '../models/user_profile.dart';

/// Operaciones sobre el perfil del usuario en Cloud Firestore.
///
/// La unicidad del DNI se garantiza con el índice `dnis/{dni}`: el perfil y
/// el índice se escriben en el mismo lote atómico, y las reglas impiden crear
/// un documento de DNI que ya exista (incluso con solicitudes simultáneas).
///
/// Todas las actualizaciones usan `update()` con los campos concretos, de modo
/// que nunca se sobrescriben los demás datos del perfil.
class UserService {
  UserService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection(FirestoreCollections.users).doc(uid);

  DocumentReference<Map<String, dynamic>> _dniDoc(String dni) =>
      _db.collection(FirestoreCollections.dnis).doc(dni);

  /// Registro por correo: crea el perfil pendiente (`registroCompleto: false`)
  /// y reserva el DNI.
  Future<void> createPendingProfile({
    required String uid,
    required String correo,
    required RegistrationData data,
  }) async {
    final batch = _db.batch();
    batch.set(_userDoc(uid), {
      'uid': uid,
      'nombre': data.nombre,
      'apellido': data.apellido,
      'dni': data.dni,
      'fechaNacimiento': UserProfile.birthDateToTimestamp(data.fechaNacimiento),
      'telefono': data.telefono,
      'correo': correo,
      'registroCompleto': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_dniDoc(data.dni), {'uid': uid});
    await _commitWithDni(batch);
  }

  /// Primer acceso con Google: perfil inicial solo con los datos que entrega
  /// el proveedor. DNI, fecha de nacimiento y teléfono NO se inventan; el
  /// usuario los completa después ([completeGoogleProfile]).
  Future<void> createGoogleProfile({
    required String uid,
    required String correo,
    required String nombre,
    required String apellido,
  }) async {
    try {
      await _userDoc(uid).set({
        'uid': uid,
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'registroCompleto': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Completa un perfil iniciado con Google, reserva el DNI y marca el
  /// registro como finalizado, todo en un único lote atómico.
  Future<void> completeGoogleProfile({
    required String uid,
    required RegistrationData data,
  }) async {
    final batch = _db.batch();
    batch.update(_userDoc(uid), {
      'nombre': data.nombre,
      'apellido': data.apellido,
      'dni': data.dni,
      'fechaNacimiento': UserProfile.birthDateToTimestamp(data.fechaNacimiento),
      'telefono': data.telefono,
      'registroCompleto': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_dniDoc(data.dni), {'uid': uid});
    await _commitWithDni(batch);
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    try {
      final snap = await _userDoc(uid).get();
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return UserProfile.fromMap(data);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Marca el registro como finalizado. Las reglas exigen el correo verificado.
  Future<void> markRegistrationComplete(String uid) async {
    try {
      await _userDoc(uid).update({
        'registroCompleto': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Actualiza los datos editables del perfil. Si [telefono] es `null` el
  /// campo no se modifica (cambio parcial).
  Future<void> updateProfileData({
    required String uid,
    required String nombre,
    required String apellido,
    String? telefono,
  }) async {
    try {
      await _userDoc(uid).update({
        'nombre': nombre,
        'apellido': apellido,
        'telefono': ?telefono,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Elimina un registro sin completar (perfil y, si existe, reserva del DNI).
  Future<void> deletePendingProfile({
    required String uid,
    required String? dni,
  }) async {
    final batch = _db.batch();
    batch.delete(_userDoc(uid));
    if (dni != null) batch.delete(_dniDoc(dni));
    try {
      await batch.commit();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> _commitWithDni(WriteBatch batch) async {
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Las reglas rechazan el lote si el DNI ya está reservado.
        throw const AppException(
          'Este DNI ya está registrado.',
          field: ErrorField.dni,
        );
      }
      throw AppException.from(e);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
