import 'package:flutter/foundation.dart';

import '../../../catalog/domain/entities/product.dart';

/// One line item in the Inquiry Cart — a product plus the quantity the
/// customer wants to ask about. Stores the [Product] itself (not just an
/// id) since the cart is local/in-memory for now and there's no
/// repository to re-fetch product details from — see
/// docs/API_CONTRACT.md §3 on the cart's still-unconfirmed backend shape.
@immutable
class InquiryItem {
  const InquiryItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get subtotal => product.price * quantity;

  InquiryItem copyWith({int? quantity}) =>
      InquiryItem(product: product, quantity: quantity ?? this.quantity);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InquiryItem &&
          other.product.id == product.id &&
          other.quantity == quantity);

  @override
  int get hashCode => Object.hash(product.id, quantity);
}
