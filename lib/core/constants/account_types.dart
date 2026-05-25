class AccountType {
  final String id;
  final String name;
  final bool isCredit;

  const AccountType({required this.id, required this.name, required this.isCredit});
}

const accountTypes = <AccountType>[
  AccountType(id: 'cash', name: '现金', isCredit: false),
  AccountType(id: 'wechat', name: '微信', isCredit: false),
  AccountType(id: 'alipay', name: '支付宝', isCredit: false),
  AccountType(id: 'bank_card', name: '银行卡', isCredit: false),
  AccountType(id: 'credit_card', name: '信用卡', isCredit: true),
  AccountType(id: 'meituan', name: '美团', isCredit: false),
  AccountType(id: 'jd', name: '京东', isCredit: false),
  AccountType(id: 'ant_credit', name: '花呗', isCredit: true),
  AccountType(id: 'jd_baitiao', name: '京东白条', isCredit: true),
  AccountType(id: 'other', name: '自定义', isCredit: false),
];
