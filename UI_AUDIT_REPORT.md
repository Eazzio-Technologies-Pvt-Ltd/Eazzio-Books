# UI/UX STABILIZATION & POLISH AUDIT REPORT

This report details visual issues, layout glitches, responsiveness flaws, and loading experience shortcomings identified across the Eazzio Books mobile app.

---

## 1. Dashboard Screen Layout & Widgets

### KPI and Stats Cards Constraints (`childAspectRatio`)
* **Problem**: In `dashboard_screen.dart`, both the Top Summary stats cards (line 153) and the Monthly Metrics Grid cards (line 270) are placed inside a `GridView.count` widget with fixed aspect ratios (`childAspectRatio: 1.4` and `childAspectRatio: 1.8` respectively). 
* **Impact**: On narrow screens (width 320–360) or with high system font scaling, text/amounts like `₹12,34,56,789.00` wrap or clip, causing RenderFlex overflows.
* **Fix**: Replace GridView fixed ratios with flexible wrapped layouts or adaptive height constraints using `LayoutBuilder`.

### Inconsistent Theme Tokens
* **Problem**: The app contains two separate theme/design token files: `lib/core/theme/theme.dart` and `lib/core/theme/app_theme.dart`.
  * `theme.dart` defines `AppSpacing.s = 8.0`, `AppSpacing.m = 16.0`, and standard card borders with a border radius of `8.0`.
  * `app_theme.dart` uses `AppSpacing.sm = 8.0`, `AppSpacing.md = 16.0`, and defines cards using `AppRadius.md = 12.0` or `AppRadius.lg = 16.0`.
* **Impact**: Visual inconsistency across screens.
* **Fix**: Unify theme tokens.

---

## 2. Auth Screens (Login, Register, Forgot/Reset Password)

### Keyboard Overlap & Center-Nesting
* **Problem**: In `login_screen.dart`, the login form is rendered inside a `SingleChildScrollView` wrapped in a `SafeArea` and centered using `Center`.
* **Impact**: Opening the software keyboard shrinks the viewport, causing `Center` to calculate jittery scroll physics and layout jumps.
* **Fix**: Remove `Center` nesting around `SingleChildScrollView` and position the scroll container at the root.

### Session Initialization Delay (Splash Screen Timer)
* **Problem**: In `login_screen.dart`, a hardcoded `Future.delayed(Duration(milliseconds: 2200))` is used to show a splash screen before showing the login form.
* **Impact**: Jarring route transitions and delays when a session is already active.
* **Fix**: Bind splash screen visibility directly to session bootstrap completion.

---

## 3. Form Screens & Detail Screens

### Skeletons and Shimmer Loaders Lack
* **Problem**: Throughout the entire feature set (`quotes_screen.dart`, `quote_detail_screen.dart`, `invoice_form_screen.dart`, etc.), the loading state consists of a basic `Center(child: CircularProgressIndicator())` or a blank scaffold.
* **Impact**: Sudden content pop-ins and layout jumps.
* **Fix**: Create consistent skeleton/shimmer loader containers.

### Multiple Nested Loading Wheels
* **Problem**: The Dashboard screen features nested asynchronous providers. For example, `dashboardSummaryProvider` loads the main layout, but `projectedPaymentsProvider` and `projectedExpensesProvider` load their cards asynchronously.
* **Impact**: Jarring concurrent spinner states.
* **Fix**: Implement skeleton loaders for individual cards.
