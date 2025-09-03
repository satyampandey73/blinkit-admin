import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersStream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final uid = docs[i].id;
              final name = d['name']?.toString() ?? '';
              final phone = d['phoneNumber']?.toString() ?? '';
              final email = d['email']?.toString() ?? '';
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(name.isEmpty ? uid : name),
                subtitle: Text(
                  [phone, email].where((s) => s.isNotEmpty).join(' • '),
                ),
                onTap: () {
                  // Could open detail in future
                },
              );
            },
          );
        },
      ),
    );
  }
}
