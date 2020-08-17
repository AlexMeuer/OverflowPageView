# overflow_page_view

[![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://pub.dev/packages/effective_dart)

A page view that displays as many fully visible items as it can in a list before beginning to do the same on the next page.

[![Demo Gif][demo_gif]][demo_gif]

# Usage

Think of it like a `ListView.builder(..)` that gets displayed as pages.

```dart
OverflowPageView(
  itemBuilder: (context, index) {
    print('Building item for index: $index')
    return Container(
      height: 32,
      child: Center(
        child: Text('Item $index'),
      ),
    ),
  },
),
```

[demo_gif]: readme_assets/demo.gif