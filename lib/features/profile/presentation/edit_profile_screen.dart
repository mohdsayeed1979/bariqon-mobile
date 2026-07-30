import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/error/failure.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/entities/app_user.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

/// Edit Profile screen — pre-filled from the current [AppUser], saved back
/// through [AuthController.updateProfile]. As of Phase 7 this is a real
/// write: Full Name and Email go to Supabase (Auth + the `profiles`
/// table); Company/Mobile/Country have no column in the real `profiles`
/// schema (confirmed: id/email/full_name/timestamps only) so they're kept
/// device-local — see [AuthController.updateProfile]'s doc comment.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final AppUser? user;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _countryController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController = TextEditingController(text: user?.fullName);
    _companyController = TextEditingController(text: user?.company);
    _emailController = TextEditingController(text: user?.email);
    _mobileController = TextEditingController(text: user?.mobile);
    _countryController = TextEditingController(text: user?.country);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  String _messageFor(Object error, AppLocalizations l10n) {
    if (error is AuthFailure) return error.message;
    return l10n.genericErrorMessage;
  }

  Future<void> _submit() async {
    final user = widget.user;
    if (user == null) return;
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newEmail = _emailController.text.trim();
    final emailChanged = newEmail != user.email;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            user.copyWith(
              fullName: _nameController.text.trim(),
              company: _companyController.text.trim(),
              email: newEmail,
              mobile: _mobileController.text.trim(),
              country: _countryController.text.trim(),
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailChanged
                ? l10n.profileEmailChangeConfirmationNotice(newEmail)
                : l10n.profileUpdateSuccessMessage,
          ),
        ),
      );
      context.pop();
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

    if (widget.user == null) {
      return Scaffold(
        appBar: BrandedAppBar(
          title: l10n.profileEditTitle,
          showSearchAction: false,
        ),
        body: Center(
          child: ErrorStateView(
            message: l10n.genericErrorMessage,
            actionLabel: MaterialLocalizations.of(context).backButtonTooltip,
            onRetry: () => context.canPop() ? context.pop() : context.go('/profile'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: BrandedAppBar(
        title: l10n.profileEditTitle,
        showSearchAction: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppTextField(
                label: l10n.inquiryFormFullName,
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    Validators.required(v, message: l10n.validationRequired),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.profileLocalOnlyFieldsNotice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
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
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    Validators.required(v, message: l10n.validationRequired),
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
                    : Text(l10n.profileSaveCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
