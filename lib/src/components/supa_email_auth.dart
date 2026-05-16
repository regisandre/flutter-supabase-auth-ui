import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/src/localizations/supa_email_auth_localization.dart';
import 'package:supabase_auth_ui/src/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// {@template metadata_field}
/// Information about the metadata to pass to the signup form
///
/// You can use this object to create additional text fields that will be
/// passed to the metadata of the user upon signup.
/// For example, in order to create additional `username` field, you can use the following:
/// ```dart
/// MetaDataField(label: 'Username', key: 'username')
/// ```
///
/// Which will update the user's metadata in like the following:
///
/// ```dart
/// { 'username': 'Whatever your user entered' }
/// ```
/// {@endtemplate}
class MetaDataField {
  /// Label of the `TextFormField` for this metadata
  final String label;

  /// Key to be used when sending the metadata to Supabase
  final String key;

  /// Validator function for the metadata field
  final String? Function(String?)? validator;

  /// Icon to show as the prefix icon in TextFormField
  final Icon? prefixIcon;

  /// Autofill hints for the field (e.g. [AutofillHints.username])
  final List<String>? autofillHints;

  /// Keyboard type for the field (e.g. [TextInputType.emailAddress])
  final TextInputType? keyboardType;

  /// Whether the field content should be obscured (e.g. for referral codes)
  final bool obscureText;

  /// {@macro metadata_field}
  MetaDataField({
    required this.label,
    required this.key,
    this.validator,
    this.prefixIcon,
    this.autofillHints,
    this.keyboardType,
    this.obscureText = false,
  });
}

/// {@template boolean_metadata_field}
/// Represents a boolean metadata field for the signup form.
///
/// This class is used to create checkbox fields that will be passed
/// to the metadata of the user upon signup. It supports both simple
/// text labels and rich text labels with interactive elements.
///
/// For example, in order to add a simple consent checkbox,
/// you can use the following:
/// ```dart
/// BooleanMetaDataField(
///   label: 'I agree to marketing emails',
///   key: 'email_consent',
/// )
/// ```
///
/// Which will update the user's metadata accordingly:
///
/// ```dart
/// { 'email_consent': true }
/// ```
///
/// You can also use rich text labels with interactive elements.
/// For example:
/// ```dart
/// BooleanMetaDataField(
///   key: 'terms_and_conditions_consent',
///   required: true,
///   richLabelSpans: [
///     TextSpan(text: 'I have read and agree to the '),
///     TextSpan(
///       text: 'Terms and Conditions',
///       style: TextStyle(color: Colors.blue),
///       recognizer: TapGestureRecognizer()
///         ..onTap = () {
///           // Handle tap on 'Terms and Conditions'
///         },
///     ),
///   ],
/// )
/// ```
///
/// This will create a checkbox with a label that includes a link to the terms
/// and conditions. When the user taps on the link, you can handle the tap
/// event in your application. Because `required` is set to `true`, the user
/// must check the checkbox in order to sign up.
/// {@endtemplate}
class BooleanMetaDataField extends MetaDataField {
  /// Whether the checkbox is initially checked.
  final bool value;

  /// Rich text spans for the label. If provided, this will be used instead of [label].
  final List<InlineSpan>? richLabelSpans;

  /// Position of the checkbox in the [ListTile] created by this.
  ///
  /// Default is to ListTileControlAffinity.platform, which matches the default
  /// value of the underlying ListTile widget.
  final ListTileControlAffinity checkboxPosition;

  /// Whether the field is required.
  ///
  /// If true, the user must check the checkbox in order for the form to submit.
  final bool isRequired;

  /// Semantic label for the checkbox.
  final String? checkboxSemanticLabel;

  /// {@macro boolean_metadata_field}
  BooleanMetaDataField({
    String? label,
    this.value = false,
    this.richLabelSpans,
    this.checkboxSemanticLabel,
    this.isRequired = false,
    this.checkboxPosition = ListTileControlAffinity.platform,
    required super.key,
  })  : assert(label != null || richLabelSpans != null,
            'Either label or richLabelSpans must be provided'),
        super(label: label ?? '');

  Widget getLabelWidget(BuildContext context) {
    // This matches the default style of [TextField], to match the other fields
    // in the form. TextField's default style uses `bodyLarge` for Material 3,
    // or otherwise `titleMedium`.
    final defaultStyle = Theme.of(context).useMaterial3
        ? Theme.of(context).textTheme.bodyLarge
        : Theme.of(context).textTheme.titleMedium;
    return richLabelSpans != null
        ? RichText(
            text: TextSpan(
              style: defaultStyle,
              children: richLabelSpans,
            ),
          )
        : Text(label, style: defaultStyle);
  }
}

// Used to allow storing both bool and TextEditingController in the same map.
typedef MetadataController = Object;

/// {@template supa_email_auth}
/// UI component to create email and password signup/ signin form
///
/// ```dart
/// SupaEmailAuth(
///   onSignInComplete: (response) {
///     // handle sign in complete here
///   },
///   onSignUpComplete: (response) {
///     // handle sign up complete here
///   },
/// ),
/// ```
/// {@endtemplate}
class SupaEmailAuth extends StatefulWidget {
  /// Whether the email field should automatically focus when the form is shown
  final bool autofocus;

  /// The URL to redirect the user to when clicking on the link on the
  /// confirmation link after signing up.
  final String? redirectTo;

  /// The URL to redirect the user to when clicking on the link on the
  /// password recovery link.
  ///
  /// If unspecified, the [redirectTo] value will be used.
  final String? resetPasswordRedirectTo;

  /// Validator function for the password field
  ///
  /// If null, a default validator will be used that checks if
  /// the password is at least 6 characters long.
  final String? Function(String?)? passwordValidator;

  /// Callback for the user to complete a sign in.
  final void Function(AuthResponse response) onSignInComplete;

  /// Callback for the user to complete a signUp.
  ///
  /// If email confirmation is turned on, the user is
  final void Function(AuthResponse response) onSignUpComplete;

  /// Callback for sending the password reset email
  final void Function()? onPasswordResetEmailSent;

  /// Callback for when the auth action threw an exception
  ///
  /// If set to `null`, a snack bar with error color will show up.
  final void Function(Object error)? onError;

  /// Callback for toggling between sign in and sign up
  final void Function(bool isSigningIn)? onToggleSignIn;

  /// Callback for toggling between sign-in/ sign-up and password recovery
  final void Function(bool isRecoveringPassword)? onToggleRecoverPassword;

  /// Set of additional fields to the signup form that will become
  /// part of the user_metadata
  final List<MetaDataField>? metadataFields;

  /// Additional properties for user_metadata on signup
  final Map<String, dynamic>? extraMetadata;

  /// Localization for the form
  final SupaEmailAuthLocalization? localization;

  /// Whether the form should display sign-in or sign-up initially
  final bool isInitiallySigningIn;

  /// Icons or custom prefix widgets for email UI
  final Widget? prefixIconEmail;
  final Widget? prefixIconPassword;

  /// Whether the confirm password field should be displayed
  final bool showConfirmPasswordField;

  /// If `true`, clears password fields when an authentication error occurs
  final bool clearOnError;

  /// Optional widget builder to render above the form
  final Widget Function(BuildContext)? headerBuilder;

  /// Optional widget builder to render below the form
  final Widget Function(BuildContext)? footerBuilder;

  /// Cloudflare Turnstile (or hCaptcha) token. Required when the Supabase
  /// project has CAPTCHA protection enabled on the auth endpoints — the token
  /// is forwarded to `signInWithPassword`, `signUp`, and
  /// `resetPasswordForEmail`. Tokens are single-use and expire after 5 minutes,
  /// so the parent should refresh the widget after each submission.
  final String? captchaToken;

  /// Called right before each auth API call when [captchaToken] is null/empty.
  /// Use this to surface a "please complete the CAPTCHA" message in the parent.
  /// If non-null and returns false, the auth call is aborted.
  final bool Function()? onCaptchaMissing;

  /// {@macro supa_email_auth}
  const SupaEmailAuth({
    super.key,
    this.autofocus = true,
    this.redirectTo,
    this.resetPasswordRedirectTo,
    this.passwordValidator,
    required this.onSignInComplete,
    required this.onSignUpComplete,
    this.onPasswordResetEmailSent,
    this.onError,
    this.onToggleSignIn,
    this.onToggleRecoverPassword,
    this.metadataFields,
    this.extraMetadata,
    this.localization,
    this.isInitiallySigningIn = true,
    this.prefixIconEmail = const Icon(Icons.email),
    this.prefixIconPassword = const Icon(Icons.lock),
    this.showConfirmPasswordField = false,
    this.clearOnError = false,
    this.headerBuilder,
    this.footerBuilder,
    this.captchaToken,
    this.onCaptchaMissing,
  });

  @override
  State<SupaEmailAuth> createState() => _SupaEmailAuthState();
}

class _SupaEmailAuthState extends State<SupaEmailAuth> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late bool _isSigningIn;
  late final Map<String, MetadataController> _metadataControllers;

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _passwordHasText = false;
  bool _confirmPasswordHasText = false;

  /// Resolved localization (auto or manual)
  late SupaEmailAuthLocalization _localization;

  /// The user has pressed forgot password button
  bool _isRecoveringPassword = false;

  /// Focus node for email field
  final FocusNode _emailFocusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localization = widget.localization ??
        SupaEmailAuthLocalization.fromLocale(
            Localizations.maybeLocaleOf(context) ?? const Locale('en'));
  }

  @override
  void initState() {
    super.initState();
    _isSigningIn = widget.isInitiallySigningIn;
    _passwordController.addListener(() {
      final hasText = _passwordController.text.isNotEmpty;
      if (hasText != _passwordHasText) setState(() => _passwordHasText = hasText);
    });
    _confirmPasswordController.addListener(() {
      final hasText = _confirmPasswordController.text.isNotEmpty;
      if (hasText != _confirmPasswordHasText) setState(() => _confirmPasswordHasText = hasText);
    });
    _metadataControllers = Map.fromEntries((widget.metadataFields ?? []).map(
      (metadataField) => MapEntry(
        metadataField.key,
        metadataField is BooleanMetaDataField
            ? metadataField.value
            : TextEditingController(),
      ),
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final controller in _metadataControllers.values) {
      if (controller is TextEditingController) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = _localization;
    final form = AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              autofocus: widget.autofocus,
              focusNode: _emailFocusNode,
              textInputAction: _isRecoveringPassword
                  ? TextInputAction.done
                  : TextInputAction.next,
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    !EmailValidator.validate(_emailController.text)) {
                  return localization.validEmailError;
                }
                return null;
              },
              decoration: InputDecoration(
                prefixIcon: widget.prefixIconEmail,
                label: Text(localization.enterEmail),
              ),
              controller: _emailController,
              onFieldSubmitted: (_) {
                if (_isRecoveringPassword) {
                  _passwordRecovery();
                }
              },
            ),
            if (!_isRecoveringPassword) ...[
              spacer(16),
              TextFormField(
                autofillHints: _isSigningIn
                    ? [AutofillHints.password]
                    : [AutofillHints.newPassword],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: widget.metadataFields != null && !_isSigningIn
                    ? TextInputAction.next
                    : TextInputAction.done,
                validator: widget.passwordValidator ??
                    (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return localization.passwordLengthError;
                      }
                      return null;
                    },
                decoration: InputDecoration(
                  prefixIcon: widget.prefixIconPassword,
                  label: Text(localization.enterPassword),
                  suffixIcon: _passwordHasText
                      ? Align(
                          widthFactor: 1.0,
                          heightFactor: 1.0,
                          child: IconButton(
                            iconSize: 20,
                            tooltip: _isPasswordVisible
                                ? localization.hidePassword
                                : localization.showPassword,
                            icon: Icon(_isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        )
                      : null,
                ),
                obscureText: !_isPasswordVisible,
                controller: _passwordController,
                onFieldSubmitted: (_) {
                  if (widget.metadataFields == null || _isSigningIn) {
                    _signInSignUp();
                  }
                },
              ),
              if (widget.showConfirmPasswordField && !_isSigningIn) ...[
                spacer(16),
                TextFormField(
                  controller: _confirmPasswordController,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    prefixIcon: widget.prefixIconPassword,
                    label: Text(localization.confirmPassword),
                    suffixIcon: _confirmPasswordHasText
                        ? Align(
                            widthFactor: 1.0,
                            heightFactor: 1.0,
                            child: IconButton(
                              iconSize: 20,
                              tooltip: _isConfirmPasswordVisible
                                  ? localization.hidePassword
                                  : localization.showPassword,
                              icon: Icon(_isConfirmPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () => setState(() =>
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible),
                            ),
                          )
                        : null,
                  ),
                  obscureText: !_isConfirmPasswordVisible,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return localization.confirmPasswordError;
                    }
                    return null;
                  },
                ),
              ],
              spacer(16),
              if (widget.metadataFields != null && !_isSigningIn)
                ...widget.metadataFields!
                    .map((metadataField) => [
                          // Render a Checkbox that displays an error message
                          // beneath it if the field is required and the user
                          // hasn't checked it when submitting the form.
                          if (metadataField is BooleanMetaDataField)
                            FormField<bool>(
                              validator: metadataField.isRequired
                                  ? (bool? value) {
                                      if (value != true) {
                                        return localization.requiredFieldError;
                                      }
                                      return null;
                                    }
                                  : null,
                              builder: (FormFieldState<bool> field) {
                                final theme = Theme.of(context);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CheckboxListTile(
                                      title:
                                          metadataField.getLabelWidget(context),
                                      value: _metadataControllers[
                                          metadataField.key] as bool,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _metadataControllers[metadataField
                                              .key] = value ?? false;
                                        });
                                        field.didChange(value);
                                      },
                                      checkboxSemanticLabel:
                                          metadataField.checkboxSemanticLabel,
                                      controlAffinity:
                                          metadataField.checkboxPosition,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 4.0),
                                    ),
                                    if (field.hasError)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 16, top: 4),
                                        child: Text(
                                          field.errorText!,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            )
                          else
                            // Otherwise render a normal TextFormField matching
                            // the style of the other fields in the form.
                            TextFormField(
                              controller:
                                  _metadataControllers[metadataField.key]
                                      as TextEditingController,
                              autofillHints: metadataField.autofillHints,
                              keyboardType: metadataField.keyboardType,
                              obscureText: metadataField.obscureText,
                              textInputAction:
                                  widget.metadataFields!.last == metadataField
                                      ? TextInputAction.done
                                      : TextInputAction.next,
                              decoration: InputDecoration(
                                label: Text(metadataField.label),
                                prefixIcon: metadataField.prefixIcon,
                              ),
                              validator: metadataField.validator,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onFieldSubmitted: (_) {
                                if (metadataField !=
                                    widget.metadataFields!.last) {
                                  FocusScope.of(context).nextFocus();
                                } else {
                                  _signInSignUp();
                                }
                              },
                            ),
                          spacer(16),
                        ])
                    .expand((element) => element),
              ElevatedButton(
                onPressed: _isLoading ? null : _signInSignUp,
                child: (_isLoading)
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 1.5,
                        ),
                      )
                    : Text(_isSigningIn
                        ? localization.signIn
                        : localization.signUp),
              ),
              spacer(16),
              if (_isSigningIn) ...[
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRecoveringPassword = true;
                    });
                    widget.onToggleRecoverPassword?.call(_isRecoveringPassword);
                  },
                  child: Text(localization.forgotPassword),
                ),
              ],
              TextButton(
                key: const ValueKey('toggleSignInButton'),
                onPressed: () {
                  setState(() {
                    _isRecoveringPassword = false;
                    _isSigningIn = !_isSigningIn;
                  });
                  widget.onToggleSignIn?.call(_isSigningIn);
                  widget.onToggleRecoverPassword?.call(_isRecoveringPassword);
                },
                child: Text(_isSigningIn
                    ? localization.dontHaveAccount
                    : localization.haveAccount),
              ),
            ],
            if (_isSigningIn && _isRecoveringPassword) ...[
              spacer(16),
              ElevatedButton(
                onPressed: _isLoading ? null : _passwordRecovery,
                child: _isLoading
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 1.5,
                        ),
                      )
                    : Text(localization.sendPasswordReset),
              ),
              spacer(16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRecoveringPassword = false;
                  });
                  widget.onToggleRecoverPassword?.call(_isRecoveringPassword);
                },
                child: Text(localization.backToSignIn),
              ),
            ],
            spacer(16),
          ],
        ),
      ),
    );
    if (widget.headerBuilder == null && widget.footerBuilder == null) {
      return form;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.headerBuilder != null) widget.headerBuilder!(context),
        form,
        if (widget.footerBuilder != null) widget.footerBuilder!(context),
      ],
    );
  }

  void _signInSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final captchaToken = widget.captchaToken;
    if ((captchaToken == null || captchaToken.isEmpty) &&
        widget.onCaptchaMissing != null) {
      final shouldContinue = widget.onCaptchaMissing!.call();
      if (!shouldContinue) return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      if (_isSigningIn) {
        final response = await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          captchaToken: captchaToken,
        );
        widget.onSignInComplete.call(response);
      } else {
        final user = supabase.auth.currentUser;
        late final AuthResponse response;
        if (user?.isAnonymous == true) {
          await supabase.auth.updateUser(
            UserAttributes(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              data: _resolveData(),
            ),
            emailRedirectTo: widget.redirectTo,
          );
          final newSession = supabase.auth.currentSession;
          response = AuthResponse(session: newSession);
        } else {
          response = await supabase.auth.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            emailRedirectTo: widget.redirectTo,
            data: _resolveData(),
            captchaToken: captchaToken,
          );
        }
        widget.onSignUpComplete.call(response);
      }
    } on AuthException catch (error) {
      if (widget.onError == null && mounted) {
        context.showErrorSnackBar(error.message);
      } else {
        widget.onError?.call(error);
      }
      if (widget.clearOnError) {
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
      _emailFocusNode.requestFocus();
    } catch (error) {
      if (widget.onError == null && mounted) {
        context.showErrorSnackBar(
            '${_localization.unexpectedError}: $error');
      } else {
        widget.onError?.call(error);
      }
      if (widget.clearOnError) {
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
      _emailFocusNode.requestFocus();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _passwordRecovery() async {
    try {
      if (!_formKey.currentState!.validate()) {
        // Focus on email field if validation fails
        _emailFocusNode.requestFocus();
        return;
      }
      final captchaToken = widget.captchaToken;
      if ((captchaToken == null || captchaToken.isEmpty) &&
          widget.onCaptchaMissing != null) {
        final shouldContinue = widget.onCaptchaMissing!.call();
        if (!shouldContinue) return;
      }
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text.trim();
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: widget.resetPasswordRedirectTo ?? widget.redirectTo,
        captchaToken: captchaToken,
      );
      widget.onPasswordResetEmailSent?.call();
      // FIX use_build_context_synchronously
      if (!mounted) return;
      context.showSnackBar(_localization.passwordResetSent);
      setState(() {
        _isRecoveringPassword = false;
      });
    } on AuthException catch (error) {
      widget.onError?.call(error);
    } catch (error) {
      widget.onError?.call(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Resolve the user_metadata that we will send during sign-up
  ///
  /// In case both MetadataFields and extraMetadata have the same
  /// key in their map, the MetadataFields (form fields) win
  Map<String, dynamic> _resolveData() {
    var extra = widget.extraMetadata ?? <String, dynamic>{};
    extra.addAll(_resolveMetadataFieldsData());
    return extra;
  }

  /// Resolve the user_metadata coming from the metadataFields
  Map<String, dynamic> _resolveMetadataFieldsData() {
    return Map.fromEntries(_metadataControllers.entries.map((entry) => MapEntry(
        entry.key,
        entry.value is TextEditingController
            ? (entry.value as TextEditingController).text
            : entry.value)));
  }
}
