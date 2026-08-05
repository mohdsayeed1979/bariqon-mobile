import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/sign_in_prompt_view.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/entities/auth_session.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'controllers/address_book_controller.dart';
import '../domain/entities/saved_address.dart';

/// Real, functional Addresses screen — list/add/edit/delete/set-default,
/// all persisted on-device per account (see [AddressBookController]; no
/// `addresses` table exists on the shared backend).
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: BrandedAppBar(
        title: l10n.profileAddressesTitle,
        showSearchAction: false,
        extraActions: [
          if (session is SignedInSession)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.addressAddCta,
              onPressed: () => context.push('/profile/addresses/form'),
            ),
        ],
      ),
      body: session is! SignedInSession
          ? SignInPromptView(message: l10n.profileSignedOutMessage)
          : const _AddressList(),
    );
  }
}

class _AddressList extends ConsumerWidget {
  const _AddressList();

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedAddress address,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addressDeleteConfirmTitle),
        content: Text(l10n.addressDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.addressDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(addressBookControllerProvider.notifier).delete(address.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final addressesAsync = ref.watch(addressBookControllerProvider);

    return AsyncValueView(
      value: addressesAsync,
      onRetry: () => ref.invalidate(addressBookControllerProvider),
      data: (addresses) {
        if (addresses.isEmpty) {
          return Center(
            child: EmptyStateView(
              icon: Icons.location_on_outlined,
              message: l10n.addressesEmptyMessage,
              actionLabel: l10n.addressAddCta,
              onAction: () => context.push('/profile/addresses/form'),
            ),
          );
        }
        return ResponsiveCenter(
          width: ContentWidth.wide,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            l10n.addressDefaultBadge,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '${address.fullName}\n${address.addressLine}, '
                    '${address.city}, ${address.country}\n${address.phone}',
                  ),
                  isThreeLine: true,
                  onTap: () => context.push('/profile/addresses/form', extra: address),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'default':
                          ref
                              .read(addressBookControllerProvider.notifier)
                              .setDefault(address.id);
                        case 'delete':
                          _confirmDelete(context, ref, address);
                      }
                    },
                    itemBuilder: (context) => [
                      if (!address.isDefault)
                        PopupMenuItem(
                          value: 'default',
                          child: Text(l10n.addressSetDefaultAction),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.addressDeleteAction),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
