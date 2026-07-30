import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/error/user_facing_message.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/inquiry_summary_card.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../catalog/presentation/controllers/catalog_providers.dart';
import '../../catalog/presentation/utils/catalog_selectors.dart';
import '../data/supabase_inquiry_repository.dart';
import '../domain/entities/inquiry.dart';
import '../domain/entities/inquiry_contact_details.dart';
import '../domain/entities/inquiry_item.dart';
import '../domain/inquiry_repository.dart';
import 'controllers/inquiry_cart_controller.dart';

/// The single place the inquiry-submission repository is chosen, mirroring
/// [inquiryCartRepositoryProvider] and the Catalog/Auth provider pattern.
final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  return SupabaseInquiryRepository(ref.watch(supabaseClientProvider));
});

/// Inquiry Details Form, per the Phase 3 brief — Name/Company/Email/
/// Mobile/Country/Notes. Submitting sends the form + cart snapshot to
/// `cms_contact_messages` via [InquiryRepository]; only on success does it
/// clear the cart and hand off to the Confirmation screen — a failed
/// submission leaves the cart and form intact so the user can retry.
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

  String _generateReferenceNumber() {
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix = (now.millisecondsSinceEpoch % 10000).toString().padLeft(
      4,
      '0',
    );
    return 'INQ-$datePart-$suffix';
  }

  /// `cms_contact_messages` has one free-text `sector` column per
  /// submission, not a per-item field, so every distinct category among
  /// the cart's items is resolved to its display name and joined — falling
  /// back to the raw category id for the (should-be-rare) case where
  /// [categoriesProvider] hasn't loaded a match, so a submission never
  /// blocks on that lookup.
  String _resolveSector(List<InquiryItem> items) {
    final categories = ref.read(categoriesProvider).value ?? const [];
    final names = <String>{};
    for (final item in items) {
      final category = categoryById(categories, item.product.categoryId);
      names.add(category?.nameEn ?? item.product.categoryId);
    }
    return names.join(', ');
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final items = ref.read(inquiryCartProvider);
    final inquiry = Inquiry(
      referenceNumber: _generateReferenceNumber(),
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
      await ref
          .read(inquiryRepositoryProvider)
          .submit(inquiry, sector: _resolveSector(items));
      if (!mounted) return;
      ref.read(inquiryCartProvider.notifier).clear();
      context.pushReplacement('/inquiry/confirmation', extra: inquiry);
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
    final items = ref.watch(inquiryCartProvider);
    final itemCount = ref.watch(inquiryCartItemCountProvider);
    final subtotal = ref.watch(inquiryCartSubtotalProvider);

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
                          onFieldSubmitted: (_) =>
                              _isSubmitting ? null : _submit(),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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
