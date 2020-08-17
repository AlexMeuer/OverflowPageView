import 'package:flutter/widgets.dart';
import 'only_fully_visible_list_view.dart';
import 'page_aware_sliver_child_builder_delegate.dart';

typedef StartingItemIndexGetter = int Function(int pageIndex);

/// A [SliverChildDelegate] that lays out children in vertical lists. Lists only
/// show fully visible children, the first partially-visible child recreated as
/// the first item in the next list.
///
/// Caveats:
///   - The final item of each list is built, even though it won't be displayed.
///   - The final item of each list is built a second time as the first item
///       of the following list.
///   - The first item of each list is created in order to determine if out
///       build method should return null. Combined with the caveats above,
///       this means that the first item of each list may be built _far_ more
///       often that it ought to be!
class OverflowSliverChildDelegate extends SliverChildDelegate {
  /// Create a new [OverflowSliverChildDelegate]. None of the arguments may be
  /// null.
  OverflowSliverChildDelegate({
    @required this.itemBuilder,
    @required this.startingItemIndexGetter,
    @required this.layoutCallback,
  })  : assert(itemBuilder != null),
        assert(startingItemIndexGetter != null),
        assert(layoutCallback != null),
        super();

  /// The function used to create children. Should return null when no more
  /// children are available.
  final IndexedWidgetBuilder itemBuilder;

  /// Used to find out which index to start with for a given page.
  final StartingItemIndexGetter startingItemIndexGetter;

  /// Used to notify the parent of how many children were layed out for a
  /// given page.
  final OverflowLayoutCallback layoutCallback;

  @override
  Widget build(BuildContext context, int pageIndex) {
    final startIndex = startingItemIndexGetter(pageIndex);
    if (itemBuilder(context, startIndex) == null) {
      return null;
    }
    return OnlyFullyVisibleListView(
      delegate: PageAwareSliverChildBuilderDelegate(
        itemBuilder: (context, itemIndex) =>
            itemBuilder(context, startIndex + itemIndex),
        layoutCallback: layoutCallback,
        pageIndex: pageIndex,
      ),
    );
  }

  @override
  bool shouldRebuild(SliverChildDelegate oldDelegate) => true;
}
