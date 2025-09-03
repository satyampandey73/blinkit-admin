import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:blinkit_admin/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  /// Adds a product to `products` collection. If the product has an `id`, it will be used as doc id.
  Future<String?> addProduct(ProductModel product) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (product.id != null && product.id!.isNotEmpty) {
        // If caller provided an id, write the payload to that document id.
        await _firestore
            .collection('products')
            .doc(product.id)
            .set(product.toJson());
        return product.id;
      }

      // Add a new document and write back the generated id into the document so
      // the stored payload includes the document id (keeps shape consistent).
      final ref = await _firestore.collection('products').add(product.toJson());
      try {
        await ref.update({'id': ref.id});
      } catch (_) {
        // If update fails for some reason, ignore: the provider maps doc.id when
        // reading so this is best-effort to keep id inside document too.
      }
      return ref.id;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final id = product.id;
      if (id == null || id.isEmpty) {
        _error = 'Product id is required to update';
        return false;
      }
      // Use update to perform a partial update and avoid accidentally
      // overwriting server-side fields. Remove `id` from payload because
      // document id is stored as the document id; storing it as a field is
      // optional and may be redundant.
      final payload = Map<String, dynamic>.from(product.toJson());
      payload.remove('id');

      try {
        await _firestore.collection('products').doc(id).update(payload);
      } on FirebaseException catch (err) {
        // If document does not exist, fall back to set so update still succeeds.
        if (err.code == 'not-found') {
          await _firestore.collection('products').doc(id).set(payload);
        } else {
          rethrow;
        }
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(String id) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestore.collection('products').doc(id).delete();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<ProductModel>> fetchAllProducts() async {
    final snap = await _firestore.collection('products').get();
    return snap.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data());
      map['id'] = d.id;
      return ProductModel.fromJson(map);
    }).toList();
  }

  Stream<List<ProductModel>> productsStream() {
    return _firestore.collection('products').snapshots().map((snap) {
      return snap.docs.map((d) {
        final map = Map<String, dynamic>.from(d.data());
        map['id'] = d.id;
        return ProductModel.fromJson(map);
      }).toList();
    });
  }

  /// Fetch a single product by document id. Returns null if not found.
  Future<ProductModel?> fetchProductById(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    if (!doc.exists) return null;
    final map = Map<String, dynamic>.from(doc.data()!);
    map['id'] = doc.id;
    return ProductModel.fromJson(map);
  }
}
