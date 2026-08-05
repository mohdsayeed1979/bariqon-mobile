import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/error/failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/entities/saved_address.dart';
import 'controllers/address_book_controller.dart';

/// Add/Edit form for a saved address — [existing] null means "add new".
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.existing});

  final SavedAddress? existing;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _labelController = TextEditingController(text: widget.existing?.label);
  late final _fullNameController = TextEditingController(
    text: widget.existing?.fullName,
  );
  late final _phoneController = TextEditingController(text: widget.existing?.phone);
  late final _addressLineController = TextEditingController(
    text: widget.existing?.addressLine,
  );
  late final _cityController = TextEditingController(text: widget.existing?.city);
  late final _countryController = TextEditingController(
    text: widget.existing?.country,
  );
  bool _isSaving = false;

  @override
  void dispose() {
    _labelController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  String _messageFor(Object error, AppLocalizations l10n) {
    if (error is Failure) return error.message;
    return l10n.genericErrorMessage;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final address = SavedAddress(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      label: _labelController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine: _addressLineController.text.trim(),
      city: _cityController.text.trim(),
      country: _countryController.text.trim(),
      isDefault: widget.existing?.isDefault ?? false,
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(addressBookControllerProvider.notifier).save(address);
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(error, l10n))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: BrandedAppBar(
        title: isEditing ? l10n.addressEditTitle : l10n.addressAddTitle,
        showSearchAction: false,
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          width: ContentWidth.wide,
          child: Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                AppTextField(
                  label: l10n.addressLabelField,
                  controller: _labelController,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.required(v, message: l10n.validationRequired),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.inquiryFormFullName,
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.required(v, message: l10n.validationRequired),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.inquiryFormMobile,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.phone(v, message: l10n.validationMobile),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.addressLineField,
                  controller: _addressLineController,
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                  validator: (v) =>
                      Validators.required(v, message: l10n.validationRequired),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.addressCityField,
                  controller: _cityController,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.required(v, message: l10n.validationRequired),
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
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.addressSaveCta),
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
