import 'package:flutter/widgets.dart';

typedef OverflowLayoutCallback = void Function(
  int pageIndex,
  int countLayedOut,
);

/// A [SliverChildBuilderDelegate] that invokes a callback when it knows how
/// many children it has layed out.
class PageAwareSliverChildBuilderDelegate extends SliverChildBuilderDelegate {
  /// Creates a new [SliverChildBuilderDelegate] with a given page index and
  /// callback function.
  PageAwareSliverChildBuilderDelegate({
    @required IndexedWidgetBuilder itemBuilder,
    @required this.layoutCallback,
    @required this.pageIndex,
    int childCount,
  })  : assert(itemBuilder != null),
        assert(layoutCallback != null),
        super(itemBuilder, childCount: childCount);

  /// The layout callback. Invoked by [didFinishLayout] with the page index
  /// and the number of children.
  final OverflowLayoutCallback layoutCallback;

  /// The page index given by the constructor. Passed to [layoutCallback] and
  /// typically used by the parent.
  final int pageIndex;

  @override
  void didFinishLayout(int firstItemIndex, int lastItemIndex) {
    assert(firstItemIndex == 0);
    assert(lastItemIndex >= 0);
    layoutCallback(pageIndex, lastItemIndex);
  }

  @override
  bool shouldRebuild(SliverChildDelegate oldDelegate) => true;
}
