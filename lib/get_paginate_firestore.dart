library get_paginate_firestore;

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/paginate_controller.dart';
import 'widgets/bottom_loader.dart';
import 'widgets/empty_display.dart';
import 'widgets/empty_separator.dart';
import 'widgets/error_display.dart';
import 'widgets/initial_loader.dart';

export 'controllers/paginate_controller.dart';

class PaginateFirestore<T> extends StatelessWidget {
  const PaginateFirestore({
    Key? key,
    required this.controller,
    required this.itemBuilder,
    required this.itemBuilderType,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
    ),
    this.onError,
    this.onReachedEnd,
    this.onLoaded,
    this.emptyDisplay = const EmptyDisplay(),
    this.separator = const EmptySeparator(),
    this.initialLoader = const InitialLoader(),
    this.bottomLoader = const BottomLoader(),
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.padding = const EdgeInsets.all(0),
    this.physics,
    this.scrollController,
    this.pageController,
    this.onPageChanged,
    this.header,
    this.footer,
  }) : super(key: key);

  final PaginateController<T> controller;
  final Widget bottomLoader;
  final Widget emptyDisplay;
  final SliverGridDelegate gridDelegate;
  final Widget initialLoader;
  final PaginateBuilderType itemBuilderType;
  final EdgeInsets padding;
  final ScrollPhysics? physics;
  final bool reverse;
  final ScrollController? scrollController;
  final PageController? pageController;
  final Axis scrollDirection;
  final Widget separator;
  final bool shrinkWrap;
  final Widget? header;
  final Widget? footer;

  final Widget Function(Exception)? onError;

  final Widget Function(int, DocumentSnapshot<T>) itemBuilder;

  final VoidCallback? onReachedEnd;

  final VoidCallback? onLoaded;

  final void Function(int)? onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Obx(_build);
  }

  Widget _build() {
    if (controller.initializing) {
      return initialLoader;
    }

    if (controller.items.isEmpty && controller.error != null) {
      return onError != null
          ? onError!(controller.error!)
          : ErrorDisplay(exception: controller.error!);
    }

    if (controller.items.isEmpty) {
      return emptyDisplay;
    }

    return itemBuilderType == PaginateBuilderType.listView
        ? _buildListView(controller.items)
        : itemBuilderType == PaginateBuilderType.gridView
            ? _buildGridView(controller.items)
            : _buildPageView(controller.items);
  }

  Widget _buildGridView(List<QueryDocumentSnapshot<T>> items) {
    return CustomScrollView(
      reverse: reverse,
      controller: scrollController,
      shrinkWrap: shrinkWrap,
      scrollDirection: scrollDirection,
      physics: physics,
      slivers: [
        if (header != null) header!,
        SliverPadding(
          padding: padding,
          sliver: SliverGrid(
            gridDelegate: gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= items.length) {
                  controller.fetchPaginatedList();
                  return bottomLoader;
                }
                return itemBuilder(index, items[index]);
              },
              childCount:
                  controller.hasReachedEnd ? items.length : items.length + 1,
            ),
          ),
        ),
        if (footer != null) footer!,
      ],
    );
  }

  Widget _buildListView(List<QueryDocumentSnapshot<T>> items) {
    return CustomScrollView(
      reverse: reverse,
      controller: scrollController,
      shrinkWrap: shrinkWrap,
      scrollDirection: scrollDirection,
      physics: physics,
      slivers: [
        if (header != null) header!,
        SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final itemIndex = index ~/ 2;
                if (index.isEven) {
                  if (itemIndex >= items.length) {
                    controller.fetchPaginatedList();
                    return bottomLoader;
                  }
                  return itemBuilder(itemIndex, items[itemIndex]);
                }
                return separator;
              },
              semanticIndexCallback: (widget, localIndex) {
                if (localIndex.isEven) {
                  return localIndex ~/ 2;
                }
                // ignore: avoid_returning_null
                return null;
              },
              childCount: max(
                  0,
                  (controller.hasReachedEnd ? items.length : items.length + 1) *
                          2 -
                      1),
            ),
          ),
        ),
        if (footer != null) footer!,
      ],
    );
  }

  Widget _buildPageView(List<QueryDocumentSnapshot<T>> items) {
    return Padding(
      padding: padding,
      child: PageView.custom(
        reverse: reverse,
        controller: pageController,
        scrollDirection: scrollDirection,
        physics: physics,
        onPageChanged: onPageChanged,
        childrenDelegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= items.length) {
              controller.fetchPaginatedList();
              return bottomLoader;
            }
            return itemBuilder(index, items[index]);
          },
          childCount:
              controller.hasReachedEnd ? items.length : items.length + 1,
        ),
      ),
    );
  }
}

enum PaginateBuilderType { listView, gridView, pageView }
