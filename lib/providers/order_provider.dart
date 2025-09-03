import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore;
  final String collectionPath;

  OrderProvider({FirebaseFirestore? firestore, this.collectionPath = 'orders'})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<OrderModel>> streamOrders({String? status}) {
    Query q = _firestore
        .collection(collectionPath)
        .orderBy('createdAt', descending: true);
    if (status != null && status != 'all') {
      q = q.where('status', isEqualTo: status);
    }
    return q.snapshots().map(
      (snap) => snap.docs
          .map(
            (d) =>
                OrderModel.fromMap(d.data() as Map<String, dynamic>, id: d.id),
          )
          .toList(),
    );
  }

  Future<List<OrderModel>> fetchOrders({
    String? status,
    DateTime? start,
    DateTime? end,
    int limit = 100,
  }) async {
    Query q = _firestore
        .collection(collectionPath)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (status != null && status != 'all')
      q = q.where('status', isEqualTo: status);
    if (start != null)
      q = q.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      );
    if (end != null)
      q = q.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));

    final snap = await q.get();
    return snap.docs
        .map(
          (d) => OrderModel.fromMap(d.data() as Map<String, dynamic>, id: d.id),
        )
        .toList();
  }

  Future<OrderModel?> getOrderById(String id) async {
    final doc = await _firestore.collection(collectionPath).doc(id).get();
    if (!doc.exists) return null;
    return OrderModel.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await _firestore.collection(collectionPath).doc(id).update({
      'status': status,
    });
    notifyListeners();
  }

  Future<void> deleteOrder(String id) async {
    await _firestore.collection(collectionPath).doc(id).delete();
    notifyListeners();
  }

  Future<void> createOrder(OrderModel order) async {
    final data = order.toMap();
    await _firestore.collection(collectionPath).add(data);
    notifyListeners();
  }

  /// Search by matching product name, userId or id. It's a simple client-side search
  Future<List<OrderModel>> searchOrders(String query) async {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase();
    final snap = await _firestore
        .collection(collectionPath)
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();
    final all = snap.docs
        .map((d) => OrderModel.fromMap(d.data(), id: d.id))
        .toList();
    return all.where((o) {
      if (o.id.toLowerCase().contains(lower)) return true;
      if (o.userId.toLowerCase().contains(lower)) return true;
      if (o.items.any((it) => it.name.toLowerCase().contains(lower)))
        return true;
      return false;
    }).toList();
  }
}
