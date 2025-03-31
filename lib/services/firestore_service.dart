import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // Store all active stream subscriptions
  final List<StreamSubscription> _activeSubscriptions = [];
  
  // Method to add an existing subscription to the tracked list
  void trackSubscription(StreamSubscription subscription) {
    _activeSubscriptions.add(subscription);
    print('Added subscription. Active subscriptions: ${_activeSubscriptions.length}');
  }
  
  // Listen to a document with automatic tracking
  StreamSubscription<DocumentSnapshot> listenToDocument<T>(
    DocumentReference docRef, 
    Function(DocumentSnapshot) onData,
  ) {
    final subscription = docRef.snapshots().listen(
      onData,
      onError: (error) {
        print('Firestore listening error: $error');
        // Gracefully handle error without crashing
      },
      onDone: () {
        print('Document listener done for ${docRef.path}');
      },
      cancelOnError: true
    );
    
    _activeSubscriptions.add(subscription);
    print('Added document listener for ${docRef.path}. Active subscriptions: ${_activeSubscriptions.length}');
    return subscription;
  }
  
  // Listen to a query with automatic tracking
  StreamSubscription<QuerySnapshot> listenToQuery<T>(
    Query query,
    Function(QuerySnapshot) onData,
  ) {
    final subscription = query.snapshots().listen(
      onData,
      onError: (error) {
        print('Firestore query listening error: $error');
        // Gracefully handle error without crashing
      },
      onDone: () {
        print('Query listener done');
      },
      cancelOnError: true
    );
    
    _activeSubscriptions.add(subscription);
    String queryPath = 'Unknown query';
    try {
      if (query is CollectionReference) {
        queryPath = query.path;
      }
    } catch (e) {
      // Ignore any errors in getting path
    }
    print('Added query listener for $queryPath. Active subscriptions: ${_activeSubscriptions.length}');
    return subscription;
  }
  
  // Get a document once
  Future<DocumentSnapshot> getDocument(DocumentReference docRef) {
    return docRef.get();
  }
  
  // Get query results once
  Future<QuerySnapshot> getQueryResults(Query query) {
    return query.get();
  }
  
  // Cancel all active subscriptions
  Future<void> cancelAllSubscriptions() async {
    print('Canceling ${_activeSubscriptions.length} Firestore subscriptions');
    List<Future> cancelFutures = [];
    
    for (var subscription in _activeSubscriptions) {
      try {
        cancelFutures.add(subscription.cancel());
      } catch (e) {
        print('Error canceling subscription: $e');
      }
    }
    
    // Wait for all cancel operations to complete
    try {
      await Future.wait(cancelFutures);
    } catch (e) {
      print('Error waiting for subscription cancellations: $e');
    }
    
    _activeSubscriptions.clear();
    print('All Firestore subscriptions canceled');
  }
  
  // Cancel a specific subscription and remove it from the tracking list
  void cancelSubscription(StreamSubscription subscription) {
    try {
      subscription.cancel();
      _activeSubscriptions.remove(subscription);
      print('Canceled subscription. Remaining subscriptions: ${_activeSubscriptions.length}');
    } catch (e) {
      print('Error canceling subscription: $e');
    }
  }
  
  // Debug method to log all active subscriptions
  void logActiveSubscriptions() {
    print('Current active subscriptions: ${_activeSubscriptions.length}');
  }
}