import 'package:flutter/material.dart';
import 'flutter/no_cache_sliver_list.dart';

/// Lays out children until it comes across one that is only partially visible.
/// The partially visible child is layed out but is not shown.
/// Cannot be scrolled.
class OnlyFullyVisibleListView extends StatelessWidget {
  /// Create a new list view that only shows fully visible children and cannot
  /// be scrolled.
  const OnlyFullyVisibleListView({
    Key key,
    @required this.delegate,
  }) : super(key: key);

  /// The delegate used to acquire children,
  /// typically a [SliverChildBuilderDelegate].
  final SliverChildDelegate delegate;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      cacheExtent: 0.0,
      slivers: [
        NoCacheSliverList(delegate: delegate),
      ],
    );
  }
}
