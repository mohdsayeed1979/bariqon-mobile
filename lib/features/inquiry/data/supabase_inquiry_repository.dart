import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_tables.dart';
import '../../../core/error/exception_mapper.dart';
import '../domain/entities/inquiry.dart';
import '../domain/inquiry_repository.dart';

/// Writes an inquiry to `cms_contact_messages`, the real table behind the
/// Inquiry form (confirmed to exist and accept anon-role inserts by direct
/// testing against production — see the commit that introduced this file
/// for the exact diagnostic steps).
///
/// The anon role can INSERT into this table but cannot SELECT from it, so
/// two things matter here that wouldn't for a normal repository:
/// - the insert deliberately does not chain `.select()` — doing so makes
///   supabase_flutter request the inserted row back (`Prefer:
///   return=representation`), which requires SELECT permission the anon
///   role doesn't have and turns an otherwise-successful insert into a
///   42501 RLS failure.
/// - there is no server-generated id/timestamp this app can ever read
///   back, so [Inquiry.referenceNumber] (generated client-side) is the
///   only reference number that will ever exist for this submission, not
///   a placeholder standing in for a "real" one.
///
/// Confirmed columns only four of which are required: `name`, `email`,
/// `sector`, `specs` (NOT NULL); `phone`, `company` are optional. There is
/// no `country`/`message`/`notes` column, so [Inquiry.contact.country] and
/// `.notes` are folded into `specs` instead of sent as their own fields.
class SupabaseInquiryRepository implements InquiryRepository {
  SupabaseInquiryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> submit(Inquiry inquiry, {required String sector}) async {
    try {
      await _client.from(SupabaseTables.contactMessages).insert({
        'name': inquiry.contact.fullName,
        'email': inquiry.contact.email,
        if (inquiry.contact.mobile.isNotEmpty) 'phone': inquiry.contact.mobile,
        if (inquiry.contact.company.isNotEmpty)
          'company': inquiry.contact.company,
        'sector': sector,
        'specs': _buildSpecs(inquiry),
      });
    } catch (error, stackTrace) {
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  String _buildSpecs(Inquiry inquiry) {
    final buffer = StringBuffer()
      ..writeln('Reference: ${inquiry.referenceNumber}');
    if (inquiry.contact.country.isNotEmpty) {
      buffer.writeln('Country: ${inquiry.contact.country}');
    }
    buffer
      ..writeln()
      ..writeln('Requested products:');
    for (final item in inquiry.items) {
      buffer.writeln('- ${item.product.nameEn} x${item.quantity}');
    }
    if (inquiry.contact.notes.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Notes:')
        ..writeln(inquiry.contact.notes);
    }
    return buffer.toString().trim();
  }
}
