import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/constants/supabase_tables.dart';
import '../../../core/error/exception_mapper.dart';
import '../domain/entities/inquiry.dart';
import '../domain/inquiry_submission_repository.dart';

/// Real Supabase write, per Phase 7 — inserts into `cms_contact_messages`,
/// the confirmed live table backing the website's own contact/inquiry
/// form (columns: `name, company, email, phone, sector, specs, id,
/// status, submitted_at` — re-verified live, see
/// docs/BACKEND_MAPPING_REPORT.md). There is no items/quantity/reference
/// column, so — per an explicit product decision rather than inventing a
/// schema change — the cart's product list and the client-side reference
/// number are serialized into the free-text `specs` column alongside any
/// notes the customer typed. `status`/`submitted_at` are left for the
/// database's own defaults.
class SupabaseInquirySubmissionRepository implements InquirySubmissionRepository {
  SupabaseInquirySubmissionRepository(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<void> submit(Inquiry inquiry) async {
    try {
      await _client.from(SupabaseTables.contactMessages).insert({
        'name': inquiry.contact.fullName,
        'company': inquiry.contact.company,
        'email': inquiry.contact.email,
        'phone': inquiry.contact.mobile,
        'sector': 'Product Inquiry',
        'specs': _buildSpecs(inquiry),
      });
    } catch (error, stackTrace) {
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  String _buildSpecs(Inquiry inquiry) {
    final buffer = StringBuffer()
      ..writeln('Reference: ${inquiry.referenceNumber}')
      ..writeln('Country: ${inquiry.contact.country}')
      ..writeln('Items (${inquiry.totalQuantity}):');
    for (final item in inquiry.items) {
      buffer.writeln('- ${item.product.nameEn} x${item.quantity} (id: ${item.product.id})');
    }
    final notes = inquiry.contact.notes.trim();
    if (notes.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Notes: $notes');
    }
    return buffer.toString().trim();
  }
}
