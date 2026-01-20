import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // 1. Singleton instance usage for google_sign_in 7.0.0+
  // final GoogleSignIn _googleSignIn = GoogleSignIn(); // Removed
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // 1. 사용자의 로그인 상태를 알려주는 스트림 (main.dart의 에러 해결)
  Stream<User?> get user => _auth.authStateChanges();

  // 2. 구글 로그인 로직
  Future<User?> signInWithGoogle() async {
    try {
      // 2. 구글 로그인 설정 (serverClientId 추가)
      // Android에서는 explicit initialization이 필요할 수 있음 (google_sign_in 7.0.0+)
      // serverClientId: 860955702730-gt7kd9gcnl717uptkmbi2ja3ho8c59rm.apps.googleusercontent.com
      await _googleSignIn.initialize(
        serverClientId:
            '860955702730-gt7kd9gcnl717uptkmbi2ja3ho8c59rm.apps.googleusercontent.com',
      );

      // 3. 구글 로그인창 띄우기 (signIn replaced by authenticate)
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      // if (googleUser == null) return null; // authenticate throws on error/cancel

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        // accessToken: googleAuth.accessToken, // google_sign_in 7.0.0에서 제거됨
        idToken: googleAuth.idToken,
      );

      if (googleAuth.idToken == null) {
        debugPrint("Google Sign-In Error: Missing idToken");
        return null;
      }

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // 로그인 성공 후 Firestore에 사용자 데이터 저장
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': userCredential.user!.email,
        'displayName': userCredential.user!.displayName,
        'photoURL': userCredential.user!.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential.user;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
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
