/// A synthetic buyer the recommendation API knows about (see `GET /v1/meta`).
/// Stands in for the customer data a real bank would provide.
class DemoProfile {
  /// `user_id` sent to the API.
  final String id;
  final String name;
  final String description;

  const DemoProfile({
    required this.id,
    required this.name,
    required this.description,
  });
}
