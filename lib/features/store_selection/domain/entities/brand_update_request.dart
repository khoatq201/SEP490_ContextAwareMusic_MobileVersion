class BrandUpdateRequest {
  const BrandUpdateRequest({
    this.name,
    this.description,
    this.website,
    this.industry,
    this.primaryContactName,
    this.contactEmail,
    this.contactPhone,
    this.legalName,
    this.taxCode,
    this.billingAddress,
    this.technicalContactEmail,
    this.defaultTimeZone,
  });

  final String? name;
  final String? description;
  final String? website;
  final String? industry;
  final String? primaryContactName;
  final String? contactEmail;
  final String? contactPhone;
  final String? legalName;
  final String? taxCode;
  final String? billingAddress;
  final String? technicalContactEmail;
  final String? defaultTimeZone;

  Map<String, String> toFormFields() {
    return {
      if (name != null) 'name': name!,
      if (description != null) 'description': description!,
      if (website != null) 'website': website!,
      if (industry != null) 'industry': industry!,
      if (primaryContactName != null) 'primaryContactName': primaryContactName!,
      if (contactEmail != null) 'contactEmail': contactEmail!,
      if (contactPhone != null) 'contactPhone': contactPhone!,
      if (legalName != null) 'legalName': legalName!,
      if (taxCode != null) 'taxCode': taxCode!,
      if (billingAddress != null) 'billingAddress': billingAddress!,
      if (technicalContactEmail != null)
        'technicalContactEmail': technicalContactEmail!,
      if (defaultTimeZone != null) 'defaultTimeZone': defaultTimeZone!,
    };
  }
}
