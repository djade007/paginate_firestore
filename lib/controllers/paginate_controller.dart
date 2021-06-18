import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class PaginateController<T> extends GetxController {
  final Query<T> query;
  final int itemsPerPage;
  final DocumentSnapshot<T>? startAfterDocument;
  DocumentSnapshot<T>? _lastDocument;
  final bool isLive;
  final VoidCallback? onReachedEnd;
  final VoidCallback? onLoaded;

  final _items = <QueryDocumentSnapshot<T>>[].obs;

  List<QueryDocumentSnapshot<T>> get items => _items;

  final _initializing = true.obs;

  bool get initializing => _initializing.value;

  final _hasReachedEnd = false.obs;

  bool get hasReachedEnd => _hasReachedEnd.value;

  final _error = Rxn<Exception>();

  Exception? get error => _error.value;

  StreamSubscription? _baseStream;
  StreamSubscription? _paginatedStream;

  PaginateController({
    required this.query,
    this.itemsPerPage = 15,
    this.startAfterDocument,
    this.isLive = false,
    this.onReachedEnd,
    this.onLoaded,
  });

  @override
  void onInit() {
    super.onInit();
    _setUp();
  }

  void _setUp() {
    _hasReachedEnd.listen((end) {
      if (end && onReachedEnd != null) {
        onReachedEnd!();
      }
    });
    _initializing.listen((loading) {
      if (!loading && onLoaded != null) {
        onLoaded!();
      }
    });
    refreshPaginatedList();
  }

  void refreshPaginatedList() async {
    _lastDocument = null;
    final localQuery = _getQuery();
    if (isLive) {
      _baseStream?.cancel();
      _paginatedStream?.cancel();
      _baseStream = localQuery.snapshots().listen((querySnapshot) {
        _initializing.value = false;
        _hasReachedEnd.value = querySnapshot.docs.length < itemsPerPage;
        _items.assignAll(querySnapshot.docs);
      });
    } else {
      final querySnapshot = await localQuery.get();
      _items.assignAll(querySnapshot.docs);
      _initializing.value = false;
    }
  }

  void fetchPaginatedList() async {
    final localQuery = _getQuery();
    if (initializing) {
      refreshPaginatedList();
      return;
    }

    if (hasReachedEnd) return;

    // load more
    final previous = items.toList();

    if (isLive) {
      _paginatedStream?.cancel();
      _paginatedStream = localQuery.snapshots().listen((querySnapshot) {
        _hasReachedEnd.value = querySnapshot.docs.isEmpty;
        _items.assignAll(previous + querySnapshot.docs);
      });
    } else {
      final querySnapshot = await localQuery.get();
      _items.assignAll(previous + querySnapshot.docs);
    }
  }

  Query<T> _getQuery() {
    var localQuery = query;
    if (_lastDocument != null) {
      localQuery = localQuery.startAfterDocument(_lastDocument!);
    } else if (startAfterDocument != null) {
      localQuery = localQuery.startAfterDocument(_lastDocument!);
    }

    localQuery = localQuery.limit(itemsPerPage);
    return localQuery;
  }

  @override
  void onClose() {
    _baseStream?.cancel();
    _paginatedStream?.cancel();
    super.onClose();
  }
}
