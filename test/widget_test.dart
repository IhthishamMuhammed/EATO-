import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:eato/main.dart';
import 'package:eato/core/providers_setup.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: ProvidersSetup.providers,
        child: const EatoApp(),
      ),
    );
    expect(find.byType(EatoApp), findsOneWidget);
  });
}
