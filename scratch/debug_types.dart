import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void debugFeedbackTypes(String studentId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('feedback')
      .where('studentId', isEqualTo: studentId)
      .get();
  
  for (var doc in snapshot.docs) {
    print('Doc ID: ${doc.id}, Type: "${doc.data()['type']}"');
  }
}
