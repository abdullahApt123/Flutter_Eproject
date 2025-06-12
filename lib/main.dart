import 'package:babyhubshop/Bottomnavigationbar.dart';
import 'package:babyhubshop/HelpCenter.dart';
import 'package:babyhubshop/Home.dart';
import 'package:babyhubshop/splashScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey: 'AIzaSyCrIhvmCqVyHNSjkhRpBjo4TD24Bph7XjY',
    appId: '1:718677210532:android:42c806bc1ca6f941503d31',
    messagingSenderId: '718677210532',
    projectId: 'fir-eed1a',
    storageBucket: 'fir-eed1a.firebasestorage.app',
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        'splash' : (context) => SplashScreen()
      },
    );
  }
}
