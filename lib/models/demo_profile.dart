import '../core/formatters.dart';
import 'customer_context.dart';
import 'payment_product.dart';

/// A synthetic customer of the bank, used in the demo.
///
/// Stands in for what a real bank would know once the customer logs in:
/// their credentials and their products, with balances and credit limits.
class DemoProfile {
  /// `user_id` sent to the API. The API keeps the behaviour variables of
  /// the model (average ticket, cashback sensitivity) under this id.
  final String id;
  final String name;

  /// Simulated login. Demo data only: a real app never stores passwords.
  final String username;
  final String password;

  /// The customer's products, with the money in each.
  final List<PaymentProduct> products;

  /// What sets this customer apart besides their money ("muy sensible al
  /// cashback"). Null when nothing does.
  final String? trait;

  const DemoProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.products,
    this.trait,
  });

  /// Balance, credit usage and payment methods, as sent to the API.
  CustomerContext get context => CustomerContext.fromProducts(products);

  /// The customer's money in one line, e.g. "Saldo de $150.000 · cupo de
  /// crédito usado al 15 %": the same numbers the app sends to the API.
  String get summary {
    final customer = context;
    return [
      'Saldo de ${Formatters.cop.format(customer.balanceCop)}',
      customer.hasCredit
          ? 'cupo de crédito usado al ${Formatters.percent(customer.creditUsage)}'
          : 'sin tarjeta de crédito',
      ?trait,
    ].join(' · ');
  }
}
