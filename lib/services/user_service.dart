import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _employeeIndex =>
      _firestore.collection('employeeIndex');

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.id).set(user.toFirestore());
    // 👇 Employee ID index bhi banao
    await _employeeIndex.doc(user.employeeId).set({'email': user.email});
  }

  // 👇 NAYA — Employee ID se email dhoondhne ke liye
  Future<String?> getEmailByEmployeeId(String employeeId) async {
    final doc = await _employeeIndex.doc(employeeId).get();
    if (!doc.exists) return null;
    return doc.data()?['email'] as String?;
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _users.doc(userId).update(data);
  }

  Future<void> deleteUser(String userId, String employeeId) async {
    await _users.doc(userId).delete();
    await _employeeIndex.doc(employeeId).delete();
  }

  // Naya helper — sirf active/inactive toggle ke liye
  Future<void> toggleUserActive(String userId, bool isActive) async {
    await _users.doc(userId).update({'isActive': isActive});
  }

  // Naya helper — role change ke liye
  Future<void> updateUserRole(String userId, String newRole) async {
    await _users.doc(userId).update({'role': newRole});
  }

  Stream<UserModel?> watchUser(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Stream<List<UserModel>> getAllUsers() {
    return _users.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> createUserByAdmin({
    required String name,
    required String email,
    required String password,
    required String employeeId,
    required String role,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUid = credential.user!.uid;

      final newUser = UserModel(
        id: newUid,
        name: name,
        email: email,
        employeeId: employeeId,
        role: role,
        isActive: true,
      );

      await createUser(newUser); // ye index bhi bana dega

      await secondaryAuth.signOut();
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  // Saare users check karo aur missing employeeIndex entries banao
  Future<int> rebuildEmployeeIndex() async {
    final usersSnapshot = await _users.get();
    int fixed = 0;

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final employeeId = data['employeeId'] as String?;
      final email = data['email'] as String?;

      if (employeeId == null || email == null || employeeId.isEmpty) continue;

      final indexDoc = await _employeeIndex.doc(employeeId).get();
      if (!indexDoc.exists) {
        await _employeeIndex.doc(employeeId).set({'email': email});
        fixed++;
      }
    }

    return fixed;
  }
}
