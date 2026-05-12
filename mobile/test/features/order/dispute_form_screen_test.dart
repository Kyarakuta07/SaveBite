// DisputeFormScreen Widget Tests — test-plan.md Section 9.11–9.13
//
// WHY these tests are critical:
// The dispute form is a legal/compliance feature — users file formal complaints
// with photo + video evidence. The backend (DisputeController.php:48-52)
// validates `reason: required|string`, `photo_proof: required|image`,
// `video_proof: required|mimes:mp4,mov,avi`. The Flutter client must replicate
// these validations client-side so users get instant feedback instead of
// waiting for a round-trip 422 response. A broken form = lost customer trust.
//
// Pattern follows `/flutter-add-widget-test` skill:
//   Step 1: pumpWidget with ProviderScope + MaterialApp wrapper
//   Step 2: find.byType for render check
//   Step 3: Simulate tap → pump → expect error text
//
// NOTE: The form is long (info banner + reason field + photo picker + video
// picker + submit button), so the default test viewport (800×600) pushes the
// submit button off-screen. We use `tester.ensureVisible()` to scroll it into
// view before tapping — matching real user behavior on smaller devices.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savebite/features/order/presentation/screens/dispute_form_screen.dart';

void main() {
  // Helper: wraps DisputeFormScreen in the required ProviderScope + MaterialApp
  // scaffold so inherited widgets (Theme, Directionality, Navigator) are present.
  Widget buildTestWidget({int orderId = 1}) {
    return ProviderScope(
      child: MaterialApp(
        home: DisputeFormScreen(orderId: orderId),
      ),
    );
  }

  // ── Test 9.11 ───────────────────────────────────
  // WHY: If the screen crashes on render (missing provider, theme error,
  // null reference in build()), the entire dispute flow is dead.
  // This smoke test catches regressions early.
  testWidgets('9.11 — renders without crash', (WidgetTester tester) async {
    // Use a phone-sized viewport so the form layout doesn't overflow.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestWidget());

    // Verify the widget tree contains DisputeFormScreen.
    expect(find.byType(DisputeFormScreen), findsOneWidget);

    // Verify key UI elements are present.
    expect(find.text('Ajukan Komplain'), findsOneWidget);
    expect(find.text('Alasan Komplain'), findsOneWidget);
    expect(find.text('Foto Bukti'), findsOneWidget);
    expect(find.text('Video Bukti'), findsOneWidget);
  });

  // ── Test 9.12 ───────────────────────────────────
  // WHY: The backend requires `photo_proof: required|image` (line 50).
  // Submitting without a photo would result in a 422 error after uploading
  // a potentially large video file — wasting bandwidth and time.
  // Client-side validation prevents this entirely.
  testWidgets('9.12 — submit without photo shows snackbar error',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestWidget());

    // Enter a valid reason (≥ 20 chars) so the form validator passes,
    // isolating the photo check.
    await tester.enterText(
      find.byType(TextFormField),
      'Makanan yang diterima sudah basi dan berbau tidak sedap',
    );

    // Scroll the submit button into view before tapping.
    final submitButton = find.text('Kirim Komplain');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();

    // Tap the submit button.
    await tester.tap(submitButton);
    await tester.pump(); // Process the snackbar animation frame.

    // The _submit() method checks `_photo == null` and calls
    // `_showError('Foto bukti wajib dilampirkan')` (line 61).
    expect(find.text('Foto bukti wajib dilampirkan'), findsOneWidget);
  });

  // ── Test 9.13 ───────────────────────────────────
  // WHY: Backend allows reason up to 1000 chars but Flutter enforces
  // a minimum of 20 chars (line 175-176 of dispute_form_screen.dart).
  // Short reasons like "jelek" provide no actionable detail for the
  // dispute resolution team. This validation ensures quality complaints.
  testWidgets('9.13 — reason < 20 chars shows form validation error',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestWidget());

    // Enter a short reason (< 20 chars).
    await tester.enterText(
      find.byType(TextFormField),
      'Makanan basi',
    );

    // Scroll the submit button into view before tapping.
    final submitButton = find.text('Kirim Komplain');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();

    // Tap submit to trigger form validation.
    await tester.tap(submitButton);
    await tester.pump(); // Process the validation frame.

    // The TextFormField validator returns 'Alasan minimal 20 karakter'
    // when reason.trim().length < 20 (line 176).
    expect(find.text('Alasan minimal 20 karakter'), findsOneWidget);
  });
}
