import 'models.dart';

/// Distinguishes an omitted nullable PATCH field from an explicit JSON null.
class FieldUpdate<T> {
  const FieldUpdate.omitted()
      : isPresent = false,
        value = null;
  const FieldUpdate.set(this.value) : isPresent = true;
  final bool isPresent;
  final T? value;
}

Map<String, dynamic> _nonEmpty(Map<String, dynamic> json) {
  if (json.isEmpty) {
    throw ArgumentError('An update requires at least one field');
  }
  return json;
}

class LoginRequest {
  const LoginRequest({required this.email, required this.password});
  final String email;
  final String password;
  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class SelectTenantRequest {
  const SelectTenantRequest({required this.tenantId});
  final String tenantId;
  Map<String, dynamic> toJson() => {
        'tenantId': tenantId,
      };
}

class CreateTenantRequest {
  const CreateTenantRequest({required this.name, required this.slug});
  final String name;
  final String slug;
  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
      };
}

class CreateUserRequest {
  const CreateUserRequest(
      {required this.name,
      required this.email,
      required this.password,
      this.roleId});
  final String name;
  final String email;
  final String password;
  final String? roleId;
  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        if (roleId != null) 'roleId': roleId,
      };
}

class UpdateUserRequest {
  const UpdateUserRequest(
      {this.name, this.email, this.password, this.roleId, this.status});
  final String? name;
  final String? email;
  final String? password;
  final String? roleId;
  final UserStatus? status;
  Map<String, dynamic> toJson() => _nonEmpty({
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (password != null) 'password': password,
        if (roleId != null) 'roleId': roleId,
        if (status != null) 'status': status!.name,
      });
}

class CreateCampaignRequest {
  const CreateCampaignRequest({required this.name, this.description});
  final String name;
  final String? description;
  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
      };
}

class UpdateCampaignRequest {
  const UpdateCampaignRequest(
      {this.name, this.description = const FieldUpdate.omitted(), this.status});
  final String? name;
  final FieldUpdate<String> description;
  final CampaignStatus? status;
  Map<String, dynamic> toJson() => _nonEmpty({
        if (name != null) 'name': name,
        if (description.isPresent) 'description': description.value,
        if (status != null) 'status': status!.name,
      });
}

class UpdateProspectRequest {
  const UpdateProspectRequest(
      {this.name,
      this.category = const FieldUpdate.omitted(),
      this.address = const FieldUpdate.omitted(),
      this.phone = const FieldUpdate.omitted(),
      this.email = const FieldUpdate.omitted(),
      this.website = const FieldUpdate.omitted(),
      this.language = const FieldUpdate.omitted(),
      this.status,
      this.metadata = const FieldUpdate.omitted()});
  final String? name;
  final FieldUpdate<String> category;
  final FieldUpdate<String> address;
  final FieldUpdate<String> phone;
  final FieldUpdate<String> email;
  final FieldUpdate<String> website;
  final FieldUpdate<String> language;
  final ProspectStatus? status;
  final FieldUpdate<Map<String, dynamic>> metadata;
  Map<String, dynamic> toJson() => _nonEmpty({
        if (name != null) 'name': name,
        if (category.isPresent) 'category': category.value,
        if (address.isPresent) 'address': address.value,
        if (phone.isPresent) 'phone': phone.value,
        if (email.isPresent) 'email': email.value,
        if (website.isPresent) 'website': website.value,
        if (language.isPresent) 'language': language.value,
        if (status != null) 'status': status!.name,
        if (metadata.isPresent) 'metadata': metadata.value,
      });
}

class CreateProspectingJobRequest {
  const CreateProspectingJobRequest(
      {required this.campaignId, required this.query});
  final String campaignId;
  final ProspectingQuery query;
  Map<String, dynamic> toJson() => {
        'campaignId': campaignId,
        'query': query.toJson(),
      };
}
