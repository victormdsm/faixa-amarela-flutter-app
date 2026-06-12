import 'package:app_faixa_amarela/ui/core/widgets/skeleton_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SkeletonList renders requested items', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SkeletonList(itemCount: 3))),
    );

    expect(find.byType(SkeletonCard), findsNWidgets(3));
  });
}
