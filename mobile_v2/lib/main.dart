import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        title: Text('Test'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Text(
          'يعمل!',
          style: TextStyle(fontSize: 40, color: Colors.white),
        ),
      ),
    ),
  ));
}