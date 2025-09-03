import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:blinkit_admin/models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  /// Adds a top-level super-category document to `categories` collection.
  /// The document shape matches `SupCatModel.toMap()`.
  Future<String?> addSupCategory(SupCatModel supCat) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final ref = await _firestore.collection('categories').add(supCat.toMap());
      return ref.id;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSupCategory(String id, SupCatModel supCat) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestore.collection('categories').doc(id).set(supCat.toMap());
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSupCategory(String id) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestore.collection('categories').doc(id).delete();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<SupCatModel>> fetchAllSupCategories() async {
    final snap = await _firestore.collection('categories').get();
    return snap.docs
        .map((d) => SupCatModel.fromMap(Map<String, dynamic>.from(d.data())))
        .toList();
  }

  Stream<List<SupCatModel>> supCategoriesStream() {
    return _firestore.collection('categories').snapshots().map((snap) {
      return snap.docs
          .map((d) => SupCatModel.fromMap(Map<String, dynamic>.from(d.data())))
          .toList();
    });
  }

  /// Stream of pairs (docId, SupCatModel) so UI can perform update/delete
  /// operations which require the Firestore document id.
  Stream<List<MapEntry<String, SupCatModel>>> supCategoriesWithIdStream() {
    return _firestore.collection('categories').snapshots().map((snap) {
      return snap.docs
          .map(
            (d) => MapEntry<String, SupCatModel>(
              d.id,
              SupCatModel.fromMap(Map<String, dynamic>.from(d.data())),
            ),
          )
          .toList();
    });
  }
}
