import 'package:blinkit_admin/home_screen.dart';
import 'package:blinkit_admin/providers/order_provider.dart';
import 'package:blinkit_admin/providers/user_provider.dart';
import 'package:blinkit_admin/providers/banner_provider.dart';
import 'package:blinkit_admin/providers/category_provider.dart';
import 'package:blinkit_admin/providers/product_provider.dart';
import 'package:blinkit_admin/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => BannerProvider()),
            ChangeNotifierProvider(create: (_) => CategoryProvider()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Flutter Demo',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            ),
            home: HomeScreen(),
          ),
        );
      },
    );
  }
}
