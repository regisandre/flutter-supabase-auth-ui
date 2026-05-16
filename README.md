# flutter-auth-ui :iphone:

<p float="left">
<img src="https://raw.githubusercontent.com/supabase/supabase/master/packages/common/assets/images/supabase-logo-wordmark--dark.png"  width="60%" height="50%" />
</p>
A simple library of predefined widgets to easily and quickly create auth components using Flutter and Supabase.

![Supabase Auth UI](https://raw.githubusercontent.com/supabase-community/flutter-auth-ui/main/screenshots/supabase_auth_ui.png 'Supabase Auth UI Sample')

## Email Auth

Use a `SupaEmailAuth` widget to create an email and password signin/ signup form.
It also contains a button to toggle to display a forgot password form.

You can pass `metadataFields` to add additional fields to the signup form to pass as metadata to Supabase.

You need to setup deep links in your app to if you have enabled email confirmation. Learn more about deep links on the [supabase_flutter README](https://pub.dev/packages/supabase_flutter#deep-links).

```dart
// Create a Email sign-in/sign-up form
SupaEmailAuth(
  redirectTo: kIsWeb ? null : 'io.mydomain.myapp://callback',
  onSignInComplete: (response) {
    // do something, for example: navigate('home');
  },
  onSignUpComplete: (response) {
    // do something, for example: navigate("wait_for_email");
  },
  metadataFields: [
    // Creates an additional TextField for string metadata, for example:
    // {'username': 'exampleUsername'}
    MetaDataField(
      prefixIcon: const Icon(Icons.person),
      label: 'Username',
      key: 'username',
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Please enter something';
        }
        return null;
      },
    ),

    // Creates a CheckboxListTile for boolean metadata, for example:
    // {'marketing_consent': true}
    BooleanMetaDataField(
      label: 'I wish to receive marketing emails',
      key: 'marketing_consent',
      checkboxPosition: ListTileControlAffinity.leading,
    ),
    // Supports interactive text. Fields can be marked as required, blocking form
    // submission unless the checkbox is checked.
    BooleanMetaDataField(
      key: 'terms_agreement',
      isRequired: true,
      checkboxPosition: ListTileControlAffinity.leading,
      richLabelSpans: [
        const TextSpan(
            text: 'I have read and agree to the '),
        TextSpan(
          text: 'Terms and Conditions',
          style: const TextStyle(
            color: Colors.blue,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              // do something, for example: navigate("terms_and_conditions");
            },
        ),
        // Or use some other custom widget.
        WidgetSpan()
      ],
    ),
  ]),
```

### CAPTCHA (Cloudflare Turnstile / hCaptcha)

When the Supabase project has CAPTCHA protection enabled (Dashboard →
Authentication → Attack Protection → Enable CAPTCHA Protection), **every**
auth endpoint requires a `captchaToken`: `signInWithPassword`, `signUp`,
`resetPasswordForEmail`, `signInWithOtp`. `SupaEmailAuth` forwards the token
to all three flows it owns via the `captchaToken` parameter.

This fork stays **mode-agnostic** — the widget doesn't care how you obtain
the token (Cloudflare Turnstile visible / invisible / non-interactive,
hCaptcha, …). Pick the mode in your app and surface the token via these
parameters:

| Parameter | Type | Purpose |
|---|---|---|
| `captchaToken` | `String?` | The latest token. Forwarded to `signInWithPassword`, `signUp`, `resetPasswordForEmail`. |
| `captchaBuilder` | `Widget Function(BuildContext)?` | Optional. Rendered inside the form, **right above the submit button** (Sign in / Sign up / Send password reset email). Use it to host a **visible** CAPTCHA widget. Omit it for **invisible** mode. |
| `onCaptchaMissing` | `bool Function()?` | Called when the user submits while `captchaToken` is null/empty. Return `false` to abort the submission (typical: show a snackbar and return false). |

We recommend exposing the mode through a dedicated `TURNSTILE_MODE` (or
similar) env var in your consumer app so you can switch between visible and
invisible without touching the code.

**Visible mode example** (Cloudflare widget set to *Managed* or *Non-interactive*):

```dart
SupaEmailAuth(
  onSignInComplete: (r) { /* ... */ },
  onSignUpComplete: (r) { /* ... */ },
  captchaToken: _captchaToken,
  captchaBuilder: (_) => MyTurnstileWidget(
    onTokenReceived: (token) => setState(() => _captchaToken = token),
  ),
  onCaptchaMissing: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please complete the verification below.')),
    );
    return false;
  },
);
```

**Invisible mode example** (Cloudflare widget set to *Invisible*):

```dart
SupaEmailAuth(
  onSignInComplete: (r) { /* ... */ },
  onSignUpComplete: (r) { /* ... */ },
  captchaToken: _captchaToken,
  // No captchaBuilder — the challenge runs in a headless WebView mounted
  // elsewhere in the tree. Pre-warm a token in initState and refresh it
  // after every submission (tokens are single-use, 5-min lifetime).
  onCaptchaMissing: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification in progress, please retry.')),
    );
    return false;
  },
);
```

> **Heads-up on Supabase's single secret key.** The Supabase Auth dashboard
> stores **one** CAPTCHA secret key per project. If you create two widgets
> in Cloudflare (e.g. a *Managed* one for web and an *Invisible* one for
> mobile), Supabase can only validate tokens from one of them — pick the
> mode on the widget itself and use the same site key everywhere.

## Magic Link Auth

Use `SupaMagicAuth` widget to create a magic link signIn form. You need to setup deep links in your app to use magic link. Learn more about deep links on the [supabase_flutter README](https://pub.dev/packages/supabase_flutter#deep-links).

```dart
SupaMagicAuth(
  redirectUrl: kIsWeb ? null : 'io.supabase.flutter://reset-callback/',
  onSuccess: (Session response) {
    // do something, for example: navigate('home');
  },
  onError: (error) {
    // do something, for example: navigate("wait_for_email");
  },
),
```

## Reset password

Use `SupaResetPassword` to create a password reset form.

```dart
SupaResetPassword(
  accessToken: supabase.auth.currentSession?.accessToken,
  onSuccess: (UserResponse response) {
    // do something, for example: navigate('home');
  },
  onError: (error) {
    // do something, for example: navigate("wait_for_email");
  },
),
```

## Social Auth

Use `SupaSocialsAuth` to create list of social login buttons. You need to setup deep links in your app to use social auth. Learn more about deep links on the [supabase_flutter README](https://pub.dev/packages/supabase_flutter#deep-links).

```dart
SupaSocialsAuth(
    socialProviders: [
        OAuthProvider.apple,
        OAuthProvider.google,
    ],
    colored: true,
    redirectUrl: kIsWeb
          ? null
          : 'io.supabase.flutter://reset-callback/',
    onSuccess: (Session response) {
        // do something, for example: navigate('home');
    },
    onError: (error) {
        // do something, for example: navigate("wait_for_email");
    },
),
```

## Theming

This library uses bare Flutter components so that you can control the appearance of the components using your own theme.
See theme example in example/lib/sign_in.dart
