class EnumValues<T> {
  Map<String?, T> map;

  EnumValues(this.map);
}

enum UserType { parent, employee, admin }

enum STATUS {
  verified('Verified'),
  unverified('Not verified'),
  rejected('Rejected');

  final String val;

  const STATUS(this.val);
}

final getSTATUSEnum = EnumValues({
  'Verified': STATUS.verified,
  'Unverified': STATUS.unverified,
  'Rejected': STATUS.rejected,
  null: STATUS.unverified,
});
