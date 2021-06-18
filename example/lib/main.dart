import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_paginate_firestore/get_paginate_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Firestore pagination library',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final controller = PaginateController(
    query: FirebaseFirestore.instance.collection('users').orderBy('name'),
    isLive: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firestore pagination example'),
        centerTitle: true,
      ),
      body: PaginateFirestore<Map<String, dynamic>>(
        controller: controller,
        // Use SliverAppBar in header to make it sticky
        header: SliverToBoxAdapter(child: Text('HEADER')),
        footer: SliverToBoxAdapter(child: Text('FOOTER')),
        // item builder type is compulsory.
        itemBuilderType: PaginateBuilderType.listView,
        //Change types accordingly
        itemBuilder: (index, documentSnapshot) {
          final data = documentSnapshot.data();
          return ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: data == null ? Text('Error in data') : Text(data['name']),
            subtitle: Text(documentSnapshot.id),
          );
        },
        // to fetch real-time data
      ),
    );
  }
}
