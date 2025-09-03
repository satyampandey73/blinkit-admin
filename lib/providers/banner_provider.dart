import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:blinkit_admin/models/banner_model.dart';

class BannerProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  /// Add a new banner document to `banners` collection. Returns the new doc id.
  Future<String?> addBanner(BannerModel banner) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final ref = await _firestore.collection('banners').add(banner.toMap());
      return ref.id;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBanner(BannerModel banner) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('banners').doc(banner.id).set(banner.toMap());
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBanner(String id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('banners').doc(id).delete();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// One-time fetch of all banners ordered by `order` field if present.
  Future<List<BannerModel>> fetchAllBanners() async {
    final snap = await _firestore.collection('banners').orderBy('order').get();
    return snap.docs
        .map(
          (d) => BannerModel.fromMap(Map<String, dynamic>.from(d.data()), d.id),
        )
        .toList();
  }

  /// Real-time stream of banners.
  Stream<List<BannerModel>> bannersStream() {
    return _firestore.collection('banners').orderBy('order').snapshots().map((
      snap,
    ) {
      return snap.docs
          .map(
            (d) =>
                BannerModel.fromMap(Map<String, dynamic>.from(d.data()), d.id),
          )
          .toList();
    });
  }
}
