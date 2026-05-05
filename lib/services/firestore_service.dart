// lib/services/firestore_service.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Lê a collection "startups" do Firestore em tempo real

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/startup_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream em tempo real da lista completa de startups
  Stream<List<StartupModel>> getStartupsStream() {
    return _db
        .collection('startups')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => StartupModel.fromFirestore(doc)).toList());
  }

  /// Stream filtrado por estágio
  Stream<List<StartupModel>> getStartupsByEstagio(String estagio) {
    return _db
        .collection('startups')
        .where('estagio', isEqualTo: estagio)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => StartupModel.fromFirestore(doc)).toList());
  }
}