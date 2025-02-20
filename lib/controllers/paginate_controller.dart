import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class PaginateController<T> extends GetxController {
  Query<T>? _query;
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
  StreamSubscription? _initializeStream;
  StreamSubscription? _endStream;

  PaginateController({
    Query<T>? query,
    this.itemsPerPage = 12,
    this.startAfterDocument,
    this.isLive = false,
    this.onReachedEnd,
    this.onLoaded,
  }) : _query = query;

  @override
  void onInit() {
    super.onInit();
    _setUp();
  }

  void setQuery(Query<T>? value) {
    closeStreams();
    if (value == null) return;

    _initializing.value = true;
    _query = value;
    _setUp();
  }

  void _setUp() {
    _endStream = _hasReachedEnd.listen((end) {
      if (end && onReachedEnd != null) {
        onReachedEnd!();
      }
    });

    _initializeStream = _initializing.listen((loading) {
      if (!loading && onLoaded != null) {
        onLoaded!();
      }
    });
    refreshPaginatedList();
  }

  void refreshPaginatedList() async {
    _lastDocument = null;
    final localQuery = _getQuery();
    if (localQuery == null) return;
    if (isLive) {
      _baseStream?.cancel();
      _paginatedStream?.cancel();
      _baseStream = localQuery.snapshots().listen((querySnapshot) {
        _initializing.value = false;
        _hasReachedEnd.value = querySnapshot.docs.length < itemsPerPage;
        _items.assignAll(querySnapshot.docs);
        _setLastDocument();
      })
        ..onError((e, s) {
          print(e);
          print(s);
          _error.value = e;
          _initializing.value = false;
        });
    } else {
      try {
        final querySnapshot = await localQuery.get();
        _items.assignAll(querySnapshot.docs);
        _setLastDocument();
        _initializing.value = false;
      } on Exception catch (e, s) {
        print(e);
        print(s);
        _error.value = e;
        _initializing.value = false;
      }
    }
  }

  void fetchPaginatedList() async {
    final localQuery = _getQuery();
    if (localQuery == null) return;

    if (initializing) {
      refreshPaginatedList();
      return;
    }

    if (hasReachedEnd) return;

    // load more
    final previous = items.toList();
    await Future.delayed(Duration(seconds: 1));

    if (isLive) {
      _paginatedStream?.cancel();
      _paginatedStream = localQuery.snapshots().listen((querySnapshot) {
        _hasReachedEnd.value = querySnapshot.docs.isEmpty;
        _items.assignAll(previous + querySnapshot.docs);
        _setLastDocument();
      });
    } else {
      final querySnapshot = await localQuery.get();
      _items.assignAll(previous + querySnapshot.docs);
      _setLastDocument();
    }
  }

  Query<T>? _getQuery() {
    var localQuery = _query;
    if (localQuery == null) return null;

    if (_lastDocument != null) {
      localQuery = localQuery.startAfterDocument(_lastDocument!);
    } else if (startAfterDocument != null) {
      localQuery = localQuery.startAfterDocument(_lastDocument!);
    }

    localQuery = localQuery.limit(itemsPerPage);
    return localQuery;
  }

  void _setLastDocument() {
    if (_items.isNotEmpty) {
      _lastDocument = _items.last;
    }
  }

  void closeStreams() {
    _baseStream?.cancel();
    _paginatedStream?.cancel();
    _initializeStream?.cancel();
    _endStream?.cancel();
  }

  @override
  void onClose() {
    closeStreams();
    super.onClose();
  }
}
