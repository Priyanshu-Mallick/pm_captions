import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pm_captions/core/constants/caption_language.dart';
import 'package:pm_captions/presentation/providers/video_provider.dart';
import 'package:pm_captions/presentation/screens/video_picker/video_picker_screen.dart';
import 'package:pm_captions/presentation/widgets/settings/language_config_widget.dart';
import 'package:pm_captions/presentation/widgets/video_picker/language_selector_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('language selector includes Hinglish and reports selection', (
    tester,
  ) async {
    CaptionLanguage? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanguageSelectorWidget(
            selectedLanguage: CaptionLanguage.english,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    final dropdown = tester.widget<DropdownButton<CaptionLanguage>>(
      find.byType(DropdownButton<CaptionLanguage>),
    );
    expect(
      dropdown.items!.map((item) => item.value),
      contains(CaptionLanguage.hinglish),
    );
    dropdown.onChanged!(CaptionLanguage.hinglish);
    expect(selected, CaptionLanguage.hinglish);
  });

  testWidgets('default language setting loads and saves Hinglish', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'default_language': 'hinglish'});
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LanguageConfigWidget())),
    );
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<CaptionLanguage>>(
      find.byType(DropdownButton<CaptionLanguage>),
    );
    expect(dropdown.value, CaptionLanguage.hinglish);
  });

  testWidgets('video picker starts with the saved default language', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'default_language': 'hinglish'});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VideoProvider(),
        child: const MaterialApp(home: VideoPickerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final selector = tester.widget<LanguageSelectorWidget>(
      find.byType(LanguageSelectorWidget),
    );
    expect(selector.selectedLanguage, CaptionLanguage.hinglish);
  });
}
