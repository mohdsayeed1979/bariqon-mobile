import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/constants/supabase_tables.dart';
import '../../../core/error/exception_mapper.dart';
import '../domain/entities/inquiry.dart';
import '../domain/inquiry_submission_repository.dart';

/// Real Supabase write — mirrors the website's own `/contact` form
/// submission handler exactly (confirmed by reading the live site's
/// bundled JS, `app/contact/page-*.js`), so a Mobile inquiry behaves
/// identically to a Website inquiry: same table, same RPC, same
/// notification endpoint. Three steps, in the same order and with the
/// same fire-and-forget error handling the website uses for steps 2–3
/// (a failure there is logged but never blocks the customer's
/// already-successful submission):
///
/// 1. Insert into `cms_contact_messages` (columns: `name, company, email,
///    phone, sector, specs` — confirmed live, see
///    docs/BACKEND_MAPPING_REPORT.md). There is no items/quantity/
///    reference column, so the cart's product list and the client-side
///    reference number are serialized into the free-text `specs` column
///    alongside any notes the customer typed — the same "cart → contact
///    form" serialization the website itself does when it pre-fills
///    `/contact?source=cart`. `status`/`submitted_at` are left for the
///    database's own defaults. A failure here **is** rethrown — nothing
///    was saved, so the customer needs to know and retry.
/// 2. For each cart item, call the `increment_product_inquiries` RPC
///    (product stats counter) — best-effort, matching the website's own
///    `try { await rpc(...) } catch { console.error(...) }` per item.
/// 3. POST the same 5 fields to `/api/inquiry` on the website's own
///    origin — the Next.js API route that sends the admin notification
///    email (`info@bariqon.bh`) and the customer confirmation email.
///    There is no Supabase Edge Function or DB trigger for this (per
///    docs/BACKEND_INTEGRATION_REPORT.md, confirmed live: no
///    `functions/v1` exists on the project) — the website's server route
///    is the only place this logic lives, so Mobile calls that same
///    route rather than reimplementing email sending. Best-effort, same
///    as the website: the insert already succeeded, so an email hiccup
///    doesn't fail the customer's submission.
class SupabaseInquirySubmissionRepository implements InquirySubmissionRepository {
  SupabaseInquirySubmissionRepository(this._client);

  final supabase.SupabaseClient _client;

  /// The website's own origin — `/api/inquiry` is a same-origin relative
  /// fetch in browser JS, which has no equivalent for a mobile client, so
  /// this is the absolute form of that same route.
  static const _inquiryNotificationUrl = 'https://www.bariqon.bh/api/inquiry';

  @override
  Future<void> submit(Inquiry inquiry) async {
    final payload = {
      'name': inquiry.contact.fullName,
      'company': inquiry.contact.company,
      'email': inquiry.contact.email,
      'phone': inquiry.contact.mobile,
      'sector': 'Product Inquiry',
      'specs': _buildSpecs(inquiry),
    };

    try {
      await _client.from(SupabaseTables.contactMessages).insert(payload);
    } catch (error, stackTrace) {
      throw ExceptionMapper.map(error, stackTrace);
    }

    for (final item in inquiry.items) {
      try {
        await _client.rpc(
          'increment_product_inquiries',
          params: {'product_id': int.parse(item.product.id)},
        );
      } catch (_) {
        // Best-effort stats counter — same as the website, never blocks
        // a submission that already succeeded.
      }
    }

    try {
      await http
          .post(
            Uri.parse(_inquiryNotificationUrl),
            // Origin/Referer match exactly what a browser sends for the
            // website's own same-origin `fetch("/api/inquiry")` call — a
            // Dart HTTP client doesn't set these on its own. Their
            // absence was distinguishing mobile-originated requests from
            // browser ones server-side, and the confirmation email's
            // template only renders correctly (real line breaks, not a
            // literal "\n") on the branch a browser request takes.
            headers: const {
              'Content-Type': 'application/json',
              'Origin': 'https://www.bariqon.bh',
              'Referer': 'https://www.bariqon.bh/contact',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Best-effort email notification — same as the website, never
      // blocks a submission that already succeeded.
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
