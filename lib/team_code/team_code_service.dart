import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createTeam(String userId) async {
    final teamCode = _generateTeamCode();

    // Create the team document
    await _firestore.collection('teams').doc(teamCode).set({
      'creatorId': userId,
      'members': [userId], // Add creator as first member
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Create the corresponding quiz session document with initial data
    await _firestore.collection('sessions').doc(teamCode).set({
      'members': [userId],
      'currentIndex': 0,
      'questions': [],
      'answers': {},  // map of userId to selected option index per question
      'started': false,
    });

    return teamCode;
  }

  Future<bool> joinTeam(String teamCode, String userId) async {
    final teamDocRef = _firestore.collection('teams').doc(teamCode);
    final sessionDocRef = _firestore.collection('sessions').doc(teamCode);

    final teamDoc = await teamDocRef.get();

    if (teamDoc.exists) {
      // Add user to team members array if not already present
      await teamDocRef.update({
        'members': FieldValue.arrayUnion([userId]),
      });

      // Also update session members list accordingly
      await sessionDocRef.update({
        'members': FieldValue.arrayUnion([userId]),
      });

      return true;
    } else {
      return false;
    }
  }

  String _generateTeamCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }
}
