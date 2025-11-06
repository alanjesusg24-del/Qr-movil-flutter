class Business {
  final int businessId;
  final String businessName;
  final String? phone;
  final String? address;

  Business({
    required this.businessId,
    required this.businessName,
    this.phone,
    this.address,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      businessId: json['business_id'] as int,
      businessName: json['business_name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'business_name': businessName,
      'phone': phone,
      'address': address,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'business_id': businessId,
      'business_name': businessName,
      'phone': phone,
      'address': address,
    };
  }

  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      businessId: map['business_id'] as int,
      businessName: map['business_name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
    );
  }
}
