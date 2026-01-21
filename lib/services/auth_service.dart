import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 1. 사용자의 로그인 상태를 알려주는 스트림 (main.dart의 에러 해결)
  Stream<User?> get user => _auth.authStateChanges().asyncMap((firebaseUser) async {
    if (firebaseUser != null) {
      // 사용자 로그인 시 log 문서 생성 확인
      await _createLogDocumentIfNeeded(firebaseUser);
    }
    return firebaseUser;
  });

  // 2. 구글 로그인 로직
  Future<User?> signInWithGoogle() async {
    try {
      // 이미 Firebase에 로그인되어 있는지 확인
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint("User already logged in: ${currentUser.uid}");
        // log 컬렉션에 문서가 없으면 생성
        await _createLogDocumentIfNeeded(currentUser);
        return currentUser;
      }

      // 구글 로그인
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint("Google Sign-In cancelled by user");
        return null;
      }

      late GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        debugPrint("Error getting authentication: $e");
        // 인증 정보 재시도
        await _googleSignIn.signOut();
        return null;
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        debugPrint("Google Sign-In Error: User is null");
        return null;
      }

      // 로그인 성공 후 Firestore에 사용자 데이터 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName,
            'photoURL': userCredential.user!.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // log 컬렉션에 문서 생성
      await _createLogDocumentIfNeeded(userCredential.user!);

      return userCredential.user;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  // Firestore log 컬렉션에 문서 생성 (첫 로그인 시에만)
  Future<void> _createLogDocumentIfNeeded(User user) async {
    try {
      final logRef = FirebaseFirestore.instance
          .collection('log')
          .doc(user.uid);

      final logSnapshot = await logRef.get();

      if (!logSnapshot.exists) {
        await logRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'provider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint("Log document created successfully for uid: ${user.uid}");
      } else {
        debugPrint("Log document already exists for uid: ${user.uid}");
      }
    } catch (e) {
      debugPrint("Error creating log document: $e");
    }
  }

  // 3. 로그아웃 로직 (settings_screen.dart의 에러 해결)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // 구글 로그아웃
      await _auth.signOut(); // 파이어베이스 로그아웃
    } catch (e) {
      debugPrint("Sign Out Error: $e");
    }
  }
}
