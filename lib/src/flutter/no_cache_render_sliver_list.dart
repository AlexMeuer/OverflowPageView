/// This is a modified version of the [sliver_list.dart] file in the flutter
/// rendering package.
/// This file does not conform to the effective_dart analysis because I want
/// to keep it as close to the original source as possible to make merging
/// uptream changes as simple as possible.

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// A sliver that places multiple box children in a linear array along the main
/// axis.
///
/// This is a modified version of [RenderSliverList] that stops displaying
/// children when it detects that the viewport has been filled. The last child
/// to be layed out is immediately garbage collected; This is because we need
/// to lay it out to discover whether or not it extends beyond the edge of the
/// viewport (so it will be created, but never shown).
class NoCacheRenderSliverList extends RenderSliverMultiBoxAdaptor {
  /// Creates a sliver that places multiple box children in a linear array along
  /// the main axis.
  ///
  /// The [childManager] argument must not be null.
  NoCacheRenderSliverList({
    @required RenderSliverBoxChildManager childManager,
  }) : super(childManager: childManager);

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = this.constraints.remainingPaintExtent;
    final BoxConstraints childConstraints = constraints.asBoxConstraints();
    int leadingGarbage = 0;
    int trailingGarbage = 0;
    bool reachedEnd = false;

    // This algorithm in principle is straight-forward: find the first child
    // that overlaps the given scrollOffset, creating more children at the top
    // of the list if necessary, then walk down the list updating and laying out
    // each child and adding more at the end if necessary until we have enough
    // children to cover the entire viewport.
    //
    // It is complicated by one minor issue, which is that any time you update
    // or create a child, it's possible that the some of the children that
    // haven't yet been laid out will be removed, leaving the list in an
    // inconsistent state, and requiring that missing nodes be recreated.
    //
    // To keep this mess tractable, this algorithm starts from what is currently
    // the first child, if any, and then walks up and/or down from there, so
    // that the nodes that might get removed are always at the edges of what has
    // already been laid out.

    // Make sure we have at least one child to start from.
    if (firstChild == null) {
      if (!addInitialChild()) {
        // There are no children.
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }

    // We have at least one child.

    // These variables track the range of children that we have laid out. Within
    // this range, the children have consecutive indices. Outside this range,
    // it's possible for a child to get removed without notice.
    RenderBox leadingChildWithLayout, trailingChildWithLayout;

    RenderBox earliestUsefulChild = firstChild;

    // A firstChild with null layout offset is likely a result of children
    // reordering.
    //
    // We rely on firstChild to have accurate layout offset. In the case of null
    // layout offset, we have to find the first child that has valid layout
    // offset.
    if (childScrollOffset(firstChild) == null) {
      int leadingChildrenWithoutLayoutOffset = 0;
      while (childScrollOffset(earliestUsefulChild) == null) {
        earliestUsefulChild = childAfter(firstChild);
        leadingChildrenWithoutLayoutOffset += 1;
      }
      // We should be able to destroy children with null layout offset safely,
      // because they are likely outside of viewport
      collectGarbage(leadingChildrenWithoutLayoutOffset, 0);
      assert(firstChild != null);
    }

    // Find the last child that is at or before the scrollOffset.
    earliestUsefulChild = firstChild;
    for (double earliestScrollOffset = childScrollOffset(earliestUsefulChild);
        earliestScrollOffset > scrollOffset;
        earliestScrollOffset = childScrollOffset(earliestUsefulChild)) {
      // We have to add children before the earliestUsefulChild.
      earliestUsefulChild =
          insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);
      if (earliestUsefulChild == null) {
        final SliverMultiBoxAdaptorParentData childParentData =
            firstChild.parentData as SliverMultiBoxAdaptorParentData;
        childParentData.layoutOffset = 0.0;

        if (scrollOffset == 0.0) {
          // insertAndLayoutLeadingChild only lays out the children before
          // firstChild. In this case, nothing has been laid out. We have
          // to lay out firstChild manually.
          firstChild.layout(childConstraints, parentUsesSize: true);
          earliestUsefulChild = firstChild;
          leadingChildWithLayout = earliestUsefulChild;
          trailingChildWithLayout ??= earliestUsefulChild;
          break;
        } else {
          // We ran out of children before reaching the scroll offset.
          // We must inform our parent that this sliver cannot fulfill
          // its contract and that we need a scroll offset correction.
          geometry = SliverGeometry(
            scrollOffsetCorrection: -scrollOffset,
          );
          return;
        }
      }

      final double firstChildScrollOffset =
          earliestScrollOffset - paintExtentOf(firstChild);
      // firstChildScrollOffset may contain double precision error
      if (firstChildScrollOffset < -precisionErrorTolerance) {
        // Let's assume there is no child before the first child. We will
        // correct it on the next layout if it is not.
        geometry = SliverGeometry(
          scrollOffsetCorrection: -firstChildScrollOffset,
        );
        final SliverMultiBoxAdaptorParentData childParentData =
            firstChild.parentData as SliverMultiBoxAdaptorParentData;
        childParentData.layoutOffset = 0.0;
        return;
      }

      final SliverMultiBoxAdaptorParentData childParentData =
          earliestUsefulChild.parentData as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = firstChildScrollOffset;
      assert(earliestUsefulChild == firstChild);
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout ??= earliestUsefulChild;
    }

    assert(childScrollOffset(firstChild) > -precisionErrorTolerance);

    // If the scroll offset is at zero, we should make sure we are
    // actually at the beginning of the list.
    if (scrollOffset < precisionErrorTolerance) {
      if (indexOf(firstChild) > 0) {
        final double earliestScrollOffset = childScrollOffset(firstChild);
        // We correct one child at a time. If there are more children before
        // the earliestUsefulChild, we will correct it once the scroll offset
        // reach zero again.
        earliestUsefulChild =
            insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);
        assert(earliestUsefulChild != null);
        final double firstChildScrollOffset =
            earliestScrollOffset - paintExtentOf(firstChild);
        geometry = SliverGeometry(
          scrollOffsetCorrection: -firstChildScrollOffset,
        );
        final SliverMultiBoxAdaptorParentData childParentData =
            firstChild.parentData as SliverMultiBoxAdaptorParentData;
        childParentData.layoutOffset = 0.0;
        return;
      }
    }

    // At this point, earliestUsefulChild is the first child, and is a child
    // whose scrollOffset is at or before the scrollOffset, and
    // leadingChildWithLayout and trailingChildWithLayout are either null or
    // cover a range of render boxes that we have laid out with the first being
    // the same as earliestUsefulChild and the last being either at or after the
    // scroll offset.

    assert(earliestUsefulChild == firstChild);
    assert(childScrollOffset(earliestUsefulChild) <= scrollOffset);

    // Make sure we've laid out at least one child.
    if (leadingChildWithLayout == null) {
      earliestUsefulChild.layout(childConstraints, parentUsesSize: true);
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout = earliestUsefulChild;
    }

    // Here, earliestUsefulChild is still the first child, it's got a
    // scrollOffset that is at or before our actual scrollOffset, and it has
    // been laid out, and is in fact our leadingChildWithLayout. It's possible
    // that some children beyond that one have also been laid out.

    bool inLayoutRange = true;
    RenderBox child = earliestUsefulChild;
    int index = indexOf(child);
    double endScrollOffset = childScrollOffset(child) + paintExtentOf(child);
    bool advance() {
      // returns true if we advanced, false if we have no more children
      // This function is used in two different places below, to avoid code duplication.
      assert(child != null);
      if (child == trailingChildWithLayout) inLayoutRange = false;
      child = childAfter(child);
      if (child == null) inLayoutRange = false;
      index += 1;
      if (!inLayoutRange) {
        if (child == null || indexOf(child) != index) {
          // We are missing a child. Insert it (and lay it out) if possible.
          child = insertAndLayoutChild(
            childConstraints,
            after: trailingChildWithLayout,
            parentUsesSize: true,
          );
          if (child == null) {
            // We have run out of children.
            return false;
          }
        } else {
          // Lay out the child.
          child.layout(childConstraints, parentUsesSize: true);
        }
        trailingChildWithLayout = child;
      }
      assert(child != null);
      final SliverMultiBoxAdaptorParentData childParentData =
          child.parentData as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = endScrollOffset;
      assert(childParentData.index == index);
      final tmp = childScrollOffset(child) + paintExtentOf(child);
      if (tmp > targetEndScrollOffset) {
        return false;
      }
      endScrollOffset = tmp;
      return true;
    }

    // Find the first child that ends after the scroll offset.
    while (endScrollOffset < scrollOffset) {
      leadingGarbage += 1;
      if (!advance()) {
        assert(leadingGarbage == childCount);
        assert(child == null);
        // we want to make sure we keep the last child around so we know the end scroll offset
        collectGarbage(leadingGarbage - 1, 0);
        assert(firstChild == lastChild);
        final double extent =
            childScrollOffset(lastChild) + paintExtentOf(lastChild);
        geometry = SliverGeometry(
          scrollExtent: extent,
          paintExtent: 0.0,
          maxPaintExtent: extent,
        );
        return;
      }
    }

    // Now find the first child that ends after our end.
    while (endScrollOffset < targetEndScrollOffset) {
      if (!advance()) {
        reachedEnd = true;
        break;
      }
    }

    // Finally count up all the remaining children and label them as garbage.
    if (child != null) {
      // child = childAfter(child);
      while (child != null) {
        trailingGarbage += 1;
        child = childAfter(child);
      }
    }

    // At this point everything should be good to go, we just have to clean up
    // the garbage and report the geometry.

    collectGarbage(leadingGarbage, trailingGarbage);

    assert(debugAssertChildListIsNonEmptyAndContiguous());
    double estimatedMaxScrollOffset;
    if (reachedEnd) {
      estimatedMaxScrollOffset = endScrollOffset;
    } else {
      estimatedMaxScrollOffset = childManager.estimateMaxScrollOffset(
        constraints,
        firstIndex: indexOf(firstChild),
        lastIndex: indexOf(lastChild),
        leadingScrollOffset: childScrollOffset(firstChild),
        trailingScrollOffset: endScrollOffset,
      );
      assert(estimatedMaxScrollOffset >=
          endScrollOffset - childScrollOffset(firstChild));
    }
    final double paintExtent = calculatePaintOffset(
      constraints,
      from: childScrollOffset(firstChild),
      to: endScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: childScrollOffset(firstChild),
      to: endScrollOffset,
    );
    final double targetEndScrollOffsetForPaint =
        constraints.scrollOffset + constraints.remainingPaintExtent;
    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow: endScrollOffset > targetEndScrollOffsetForPaint ||
          constraints.scrollOffset > 0.0,
    );

    // We may have started the layout while scrolled to the end, which would not
    // expose a new child.
    if (estimatedMaxScrollOffset == endScrollOffset)
      childManager.setDidUnderflow(true);
    childManager.didFinishLayout();
  }
}
