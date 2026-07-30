import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/error/failure.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/password_field.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'controllers/auth_controller.dart';

/// Registration screen — real Supabase `auth.signUp` as of Phase 7. If the
/// project requires email confirmation, [_pendingConfirmation] swaps the
/// form for a "check your email" success view instead of navigating to
/// Home, since there's no session to navigate into yet (see
/// [AuthController.register]/`RegisterResult`).
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _countryController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _pendingConfirmation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _countryController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _messageFor(Object error, AppLocalizations l10n) {
    // AuthFailure carries Supabase's own user-facing message (e.g. "User
    // already registered", "Password should be at least 6 characters") —
    // worth showing directly rather than flattening to a generic one.
    if (error is AuthFailure) return error.message;
    return l10n.genericErrorMessage;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final signedIn = await ref.read(authControllerProvider.notifier).register(
        fullName: _nameController.text.trim(),
        company: _companyController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        country: _countryController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (signedIn) {
        context.go('/home');
      } else {
        setState(() => _pendingConfirmation = true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(error, l10n))));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: BrandedAppBar(title: l10n.registerTitle, showSearchAction: false),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _pendingConfirmation
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mark_email_read_outlined,
                          size: AppIconSize.feature,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.registerPendingConfirmationHeading,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.registerPendingConfirmationMessage(
                            _emailController.text.trim(),
                          ),
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed: () =>
                              context.canPop() ? context.pop() : context.go('/auth/login'),
                          child: Text(l10n.forgotPasswordBackToSignIn),
                        ),
                      ],
                    )
                  : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: l10n.inquiryFormFullName,
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          Validators.required(v, message: l10n.validationRequired),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.inquiryFormCompany,
                      controller: _companyController,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.authEmailLabel,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) => Validators.email(v, message: l10n.validationEmail),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.inquiryFormMobile,
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) => Validators.phone(v, message: l10n.validationMobile),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.inquiryFormCountry,
                      controller: _countryController,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          Validators.required(v, message: l10n.validationRequired),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PasswordField(
                      label: l10n.authPasswordLabel,
                      controller: _passwordController,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          Validators.required(v, message: l10n.validationRequired),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PasswordField(
                      label: l10n.authConfirmPasswordLabel,
                      controller: _confirmPasswordController,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        final required = Validators.required(
                          v,
                          message: l10n.validationRequired,
                        );
                        if (required != null) return required;
                        if (v != _passwordController.text) {
                          return l10n.validationPasswordMismatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.authCreateAccountCta),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.authHaveAccountPrompt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.canPop() ? context.pop() : context.push('/auth/login'),
                          child: Text(l10n.authSignInCta),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
