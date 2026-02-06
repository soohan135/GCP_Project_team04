import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  // 1. 사용자의 로그인 상태를 알려주는 스트림 (main.dart의 에러 해결)
  Stream<User?> get user =>
      _auth.authStateChanges().asyncMap((firebaseUser) async {
        if (firebaseUser != null) {
          // 사용자 로그인 시 최초 방문 여부 확인 및 데이터 저장
          await _initializeUserDataIfNeeded(firebaseUser);
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
        // 최초 방문 여부 확인 및 데이터 저장
        await _initializeUserDataIfNeeded(currentUser);
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

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        // 로그인 성공 후 최초 데이터 저장 로직 호출
        await _initializeUserDataIfNeeded(userCredential.user!);
        return userCredential.user;
      }

      return null;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      // 플러그인 에러가 나더라도 Firebase Auth에 이미 로그인이 되었다면 해당 유저 반환
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _initializeUserDataIfNeeded(currentUser);
        return currentUser;
      }
      return null;
    }
  }

  // Firestore에서 사용자 데이터를 Stream으로 가져옴
  Stream<AppUser?> get appUserStream {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.exists ? AppUser.fromFirestore(snapshot) : null,
        );
  }

  // Firestore에 유저 정보가 없을 때만 저장 (최초 1회)
  Future<void> _initializeUserDataIfNeeded(User user) async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final userSnapshot = await userRef.get();

      // FCM 토큰 가져오기
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint("Error fetching FCM token: $e");
      }

      // users 컬렉션에 문서가 없으면 최초 로그인으로 판단
      if (!userSnapshot.exists) {
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'role': 'none', // 초기 상태는 정해지지 않음
          'upload_counters': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'fcmToken': fcmToken, // FCM 토큰 저장
        });
        debugPrint("New user data saved to 'users' for uid: ${user.uid}");
      } else {
        // 기존 유저의 경우에도 토큰이 바뀌었을 수 있으므로 업데이트
        if (fcmToken != null) {
          await userRef.update({'fcmToken': fcmToken});
          debugPrint("FCM token updated for uid: ${user.uid}");
        }
        debugPrint("User data already exists for uid: ${user.uid}");
      }
    } catch (e) {
      debugPrint("Error initializing user data: $e");
    }
  }

  // 역할 업데이트
  Future<void> updateUserRole(
    String uid,
    UserRole role, {
    String? serviceCenterId,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'role': role.name,
      'serviceCenterId': serviceCenterId,
    });
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
