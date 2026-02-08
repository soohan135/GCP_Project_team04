import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<int, bool> _hasNotification = {};
  final Map<int, StreamSubscription?> _subscriptions = {};

  bool hasNotification(int index) => _hasNotification[index] ?? false;

  void initialize(AppUser user) {
    _clearSubscriptions();

    if (user.role == UserRole.consumer) {
      _subscribeToConsumer(user.uid);
    } else if (user.role == UserRole.mechanic) {
      _subscribeToMechanic(user.uid, user.serviceCenterId);
    }
  }

  void markAsRead(int index) {
    if (_hasNotification[index] == true) {
      _hasNotification[index] = false;
      notifyListeners();
    }
  }

  void _setNotification(int index, bool value) {
    if (_hasNotification[index] != value) {
      _hasNotification[index] = value;
      notifyListeners();
    }
  }

  void _subscribeToConsumer(String uid) {
    // Index 2: Shop Responses (users/{uid}/response_estimate)
    bool isFirstLoadResponses = true;
    _subscriptions[2] = _firestore
        .collection('users')
        .doc(uid)
        .collection('response_estimate')
        .snapshots()
        .listen(
          (snapshot) {
            if (isFirstLoadResponses) {
              isFirstLoadResponses = false;
              return;
            }
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                _setNotification(2, true);
              }
            }
          },
          onError: (e) => print('Error in consumer responses stream: $e'),
        );

    // Index 3: Chat (chat_rooms where participants contains uid)
    bool isFirstLoadChats = true;
    _subscriptions[3] = _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (isFirstLoadChats) {
              isFirstLoadChats = false;
              return;
            }
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                 final data = change.doc.data();
                 final lastSenderId = data?['lastMessageSenderId'] as String?;
                 // Notify only if the sender is NOT the current user
                 if (lastSenderId != null && lastSenderId != uid) {
                   _setNotification(3, true);
                 }
              }
            }
          },
          onError: (e) => print('Error in consumer chat stream: $e'),
        );
  }

  void _subscribeToMechanic(String uid, String? shopId) {
    if (shopId == null) return;

    // Index 1: Received Requests
    bool isFirstLoadRequests = true;
    _subscriptions[1] = _firestore
        .collection('service_centers')
        .doc(shopId)
        .collection('receive_estimate')
        .snapshots()
        .listen(
          (snapshot) {
            if (isFirstLoadRequests) {
              isFirstLoadRequests = false;
              return;
            }
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                _setNotification(1, true);
              }
            }
          },
          onError: (e) => print('Error in mechanic requests stream: $e'),
        );

    // Index 2: Review Management
    bool isFirstLoadReviews = true;
    _subscriptions[2] = _firestore
        .collection('service_centers')
        .doc(shopId)
        .collection('reviews')
        .snapshots()
        .listen(
          (snapshot) {
            if (isFirstLoadReviews) {
              isFirstLoadReviews = false;
              return;
            }
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                _setNotification(2, true);
              }
            }
          },
          onError: (e) => print('Error in mechanic reviews stream: $e'),
        );

    // Index 3: Chat
    bool isFirstLoadChats = true;
    _subscriptions[3] = _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (isFirstLoadChats) {
              isFirstLoadChats = false;
              return;
            }
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                 final data = change.doc.data();
                 final lastSenderId = data?['lastMessageSenderId'] as String?;
                 // Notify only if the sender is NOT the current user
                 if (lastSenderId != null && lastSenderId != uid) {
                   _setNotification(3, true);
                 }
              }
            }
          },
          onError: (e) => print('Error in mechanic chat stream: $e'),
        );
  }

  void _clearSubscriptions() {
    for (var sub in _subscriptions.values) {
      sub?.cancel();
    }
    _subscriptions.clear();
    _hasNotification.clear();
  }

  @override
  void dispose() {
    _clearSubscriptions();
    super.dispose();
  }


