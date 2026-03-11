import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/db/database_helper.dart';
import 'package:workout_tracker/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.initDatabaseFactory();

  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const WorkoutTrackerApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
