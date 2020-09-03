import 'package:flutter/widgets.dart';
import 'overflow_sliver_child_delegate.dart';

typedef PageChangedCallback = void Function(
  int firstVisibleIndex,
  int lastVisibleIndex,
);

/// A [PageView] that lays its children in vertical lists.
///
/// Shows as many children as it can on each page before filling up the next
/// page. There will be unused space at the bottom of each page because
/// partially visible children are not allowed; They will become the first
/// child on the next page.
///
/// It's a known issue that items that appear at the top of pages may be built
/// far more often than they need to be.
class OverflowPageView extends StatefulWidget {
  /// Creates a new [PageView] that displays as many children as it can
  /// vertically on each page.
  OverflowPageView({
    Key key,
    @required this.itemBuilder,
    this.onPageChanged,
    this.invokeOnPageChangedOnFirstPage = true,
  }) : super(key: key);

  /// The builder used to create children. Children and pages will be created
  /// until this returns null.
  final IndexedWidgetBuilder itemBuilder;

  /// Invoked when the current page changes with the indices of the first and
  /// last visible widgets, as they would have been passed to the [itemBuilder].
  final PageChangedCallback onPageChanged;

  /// If we should invoke the [onPageChanged] callback once we've layed out
  /// the first page (i.e. on first build before the page has changed).
  final bool invokeOnPageChangedOnFirstPage;

  @override
  _OverflowPageViewState createState() => _OverflowPageViewState();
}

class _OverflowPageViewState extends State<OverflowPageView> {
  Map<int, int> _pageItemCount;
  bool _hasInvokedOnPageChangedForFirstPage;

  bool get _shouldInvokeOnPageChangedForFirstPage =>
      widget.invokeOnPageChangedOnFirstPage &&
      !_hasInvokedOnPageChangedForFirstPage;

  @override
  void initState() {
    super.initState();
    _pageItemCount = <int, int>{};
    _hasInvokedOnPageChangedForFirstPage = false;
  }

  Widget build(BuildContext context) => PageView.custom(
        childrenDelegate: OverflowSliverChildDelegate(
          itemBuilder: widget.itemBuilder,
          layoutCallback: _onLayout,
          startingItemIndexGetter: getStartIndexForPage,
        ),
        onPageChanged: widget.onPageChanged == null ? null : _onPageChanged,
      );

  int getStartIndexForPage(int pageIndex) {
    assert(pageIndex >= 0);
    if (pageIndex == 0) {
      return 0;
    }

    // We start at 1 because we're going to count the number of items on each
    // page and we want the next index after that sum.
    var sum = 1;
    for (var i = 0; i < pageIndex; ++i) {
      assert(_pageItemCount.containsKey(i));
      sum += _pageItemCount[i];
    }
    return sum;
  }

  void _onLayout(pageIndex, countLayedOut) {
    assert(countLayedOut > 0);
    _pageItemCount[pageIndex] = countLayedOut;

    if (pageIndex == 0 && _shouldInvokeOnPageChangedForFirstPage) {
      _hasInvokedOnPageChangedForFirstPage = true;
      _onPageChanged(0);
    }
  }

  void _onPageChanged(int pageIndex) {
    assert(widget.onPageChanged != null);
    assert(_pageItemCount.containsKey(pageIndex));
    final start = getStartIndexForPage(pageIndex);
    final end = start + _pageItemCount[pageIndex];
    widget.onPageChanged(start, end);
  }
}
