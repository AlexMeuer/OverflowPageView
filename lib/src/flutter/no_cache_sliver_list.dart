import 'package:flutter/widgets.dart';

import 'no_cache_render_sliver_list.dart';

/// A sliver that places multiple box children in a linear array along the main
/// axis but will only display children that are fully visible.
///
/// Each child is forced to have the [SliverConstraints.crossAxisExtent] in the
/// cross axis but determines its own main axis extent.
///
/// Children will be built until one of them is partially visible (off the
/// viewport). This final child is immediately garbage collected but still needs
/// to be created in order to find out where to stop.
///
/// See also:
///
///  * [SliverList], which allows scrolling.
class NoCacheSliverList extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places box children in a linear array.
  const NoCacheSliverList({
    Key key,
    @required SliverChildDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  NoCacheRenderSliverList createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return NoCacheRenderSliverList(childManager: element);
  }
}
