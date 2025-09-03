import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:blinkit_admin/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;

  /// Fetch user document by uid from `users` collection.
  Future<void> fetchUser(String uid) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        _user = null;
        _error = 'User not found';
      } else {
        final data = doc.data() ?? {};
        // Ensure uid is present
        final map = Map<String, dynamic>.from(data);
        map['uid'] = doc.id;
        _user = UserModel.fromMap(map);
      }
    } catch (e) {
      _error = e.toString();
      _user = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Listen to realtime changes for the user document.
  Stream<UserModel?> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final map = Map<String, dynamic>.from(snap.data() ?? {});
      map['uid'] = snap.id;
      return UserModel.fromMap(map);
    });
  }
}
