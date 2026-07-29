import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/error/user_facing_message.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/entities/app_user.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

/// Edit Profile screen, per the Phase 4 brief — pre-filled from the
/// current [AppUser], saved back through [AuthController.updateProfile]
/// (mock only, no backend write).
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

  Future<void> _submit() async {
    final user = widget.user;
    if (user == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            user.copyWith(
              fullName: _nameController.text.trim(),
              company: _companyController.text.trim(),
              email: _emailController.text.trim(),
              mobile: _mobileController.text.trim(),
              country: _countryController.text.trim(),
            ),
          );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(context, e))),
      );
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
        child: ResponsiveCenter(
          width: ContentWidth.narrow,
          child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
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
      ),
    );
  }
}
