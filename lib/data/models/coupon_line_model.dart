class CouponLineModel {
  final String code;
  final double? discount;

  CouponLineModel({
    required this.code,
    this.discount,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      if (discount != null) 'discount': discount.toString(),
    };
  }

  factory CouponLineModel.fromJson(Map<String, dynamic> json) {
    return CouponLineModel(
      code: json['code'] ?? '',
      discount: json['discount'] != null ? double.tryParse(json['discount'].toString()) : null,
    );
  }
}
