import 'package:flutter/widgets.dart';
import 'overflow_sliver_child_delegate.dart';

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
  }) : super(key: key);

  /// The builder used to create children. Children and pages will be created
  /// until this returns null.
  final IndexedWidgetBuilder itemBuilder;

  @override
  _OverflowPageViewState createState() => _OverflowPageViewState();
}

class _OverflowPageViewState extends State<OverflowPageView> {
  Map<int, int> _pageItemCount;

  @override
  void initState() {
    super.initState();
    _pageItemCount = {};
  }

  Widget build(BuildContext context) => PageView.custom(
        childrenDelegate: OverflowSliverChildDelegate(
          itemBuilder: widget.itemBuilder,
          layoutCallback: (pageIndex, countLayedOut) {
            _pageItemCount[pageIndex] = countLayedOut;
          },
          startingItemIndexGetter: (pageIndex) {
            var sum = 0;
            for (var i = 0; i < pageIndex; ++i) {
              sum += _pageItemCount[i];
            }
            return sum;
          },
        ),
      );
}
