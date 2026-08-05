import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/error/failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/inquiry_summary_card.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/entities/auth_session.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'controllers/inquiry_cart_controller.dart';
import '../domain/entities/inquiry.dart';
import '../domain/entities/inquiry_contact_details.dart';

/// Inquiry Details Form — Name/Company/Email/Mobile/Country/Notes, then a
/// real submission: builds an [Inquiry] snapshot (with a client-generated
/// reference number for display/tracking, since the backend table has no
/// reference column — see [SupabaseInquirySubmissionRepository]), sends
/// it via [inquirySubmissionRepositoryProvider], clears the cart only on
/// success, and hands off to the Confirmation screen.
///
/// A signed-in user's account email is used automatically (shown as
/// "Logged in as: ..." instead of an input, with an explicit way to
/// change it) rather than asked for again — see [_editingEmail]. A guest
/// still gets the plain, always-editable email field.
class InquiryDetailsFormScreen extends ConsumerStatefulWidget {
  const InquiryDetailsFormScreen({super.key});

  @override
  ConsumerState<InquiryDetailsFormScreen> createState() =>
      _InquiryDetailsFormScreenState();
}

class _InquiryDetailsFormScreenState
    extends ConsumerState<InquiryDetailsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _countryController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  /// True whenever the email field should be a normal editable input:
  /// always for a guest, or once a signed-in user explicitly asks to
  /// change the account email that's prefilled by default.
  bool _editingEmail = true;

  @override
  void initState() {
    super.initState();
    final session = ref.read(authControllerProvider);
    if (session is SignedInSession) {
      final user = session.user;
      _editingEmail = false;
      _emailController.text = user.email;
      _nameController.text = user.fullName;
      _companyController.text = user.company;
      _mobileController.text = user.mobile;
      _countryController.text = user.country;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _countryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generateMockReference() {
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix = (now.millisecondsSinceEpoch % 10000).toString().padLeft(
      4,
      '0',
    );
    return 'INQ-$datePart-$suffix';
  }

  String _messageFor(Object error, AppLocalizations l10n) {
    if (error is Failure) return error.message;
    return l10n.genericErrorMessage;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final items = ref.read(inquiryCartProvider);
    final inquiry = Inquiry(
      referenceNumber: _generateMockReference(),
      items: items,
      contact: InquiryContactDetails(
        fullName: _nameController.text.trim(),
        company: _companyController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        country: _countryController.text.trim(),
        notes: _notesController.text.trim(),
      ),
      submittedAt: DateTime.now(),
    );

    setState(() => _isSubmitting = true);
    try {
      await ref.read(inquirySubmissionRepositoryProvider).submit(inquiry);
      if (!mounted) return;
      ref.read(inquiryCartProvider.notifier).clear();
      context.pushReplacement('/inquiry/confirmation', extra: inquiry);
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
    final items = ref.watch(inquiryCartProvider);
    final itemCount = ref.watch(inquiryCartItemCountProvider);
    final subtotal = ref.watch(inquiryCartSubtotalProvider);
    final session = ref.watch(authControllerProvider);
    final showLoggedInEmail = session is SignedInSession && !_editingEmail;

    return Scaffold(
      appBar: BrandedAppBar(title: l10n.inquiryFormTitle, showSearchAction: false),
      body: SafeArea(
        child: items.isEmpty
            ? Center(
                child: EmptyStateView(
                  icon: Icons.shopping_bag_outlined,
                  message: l10n.inquiryCartEmptyMessage,
                  actionLabel: l10n.inquiryCartEmptyCta,
                  onAction: () => context.go('/products'),
                ),
              )
            : ResponsiveCenter(
                width: ContentWidth.wide,
                child: Form(
                    key: _formKey,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        InquirySummaryCard(
                          itemsLabel: l10n.inquiryCartItemsLabel(itemCount),
                          totalLabel: l10n.inquiryEstimatedTotalLabel,
                          estimatedTotal: subtotal,
                        ),
                        const SizedBox(height: AppSpacing.lg),
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
                        if (showLoggedInEmail)
                          _LoggedInEmailRow(
                            label: l10n.authLoggedInAsLabel,
                            email: _emailController.text,
                            changeLabel: l10n.authChangeEmailAction,
                            onChange: () => setState(() => _editingEmail = true),
                          )
                        else
                          AppTextField(
                            label: l10n.inquiryFormEmail,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                Validators.email(v, message: l10n.validationEmail),
                          ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: l10n.inquiryFormMobile,
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              Validators.phone(v, message: l10n.validationMobile),
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
                        AppTextField(
                          label: l10n.inquiryFormNotes,
                          controller: _notesController,
                          maxLines: 4,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(l10n.inquiryFormSubmit),
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
      ),
    );
  }
}

/// Read-only replacement for the email field when a signed-in user's
/// account email is being used automatically — "Logged in as:
/// user@email.com" plus a "Change" action that reveals the normal,
/// editable field instead.
class _LoggedInEmailRow extends StatelessWidget {
  const _LoggedInEmailRow({
    required this.label,
    required this.email,
    required this.changeLabel,
    required this.onChange,
  });

  final String label;
  final String email;
  final String changeLabel;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: Text(changeLabel)),
        ],
      ),
    );
  }
}
