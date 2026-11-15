class DeviceInfo {
  final String serial;
  final String model;
  final String brand;
  final String androidVersion;
  final int sdkInt;
  final int batteryLevel;
  final bool isCharging;
  final bool isAppInstalled;
  final bool isDeviceOwner;
  final bool isActiveAdmin;
  final List<String> accounts;
  final String status; // 'device', 'unauthorized', 'offline'

  const DeviceInfo({
    required this.serial,
    this.model = 'Unknown Model',
    this.brand = 'Android Device',
    this.androidVersion = '?',
    this.sdkInt = 0,
    this.batteryLevel = -1,
    this.isCharging = false,
    this.isAppInstalled = false,
    this.isDeviceOwner = false,
    this.isActiveAdmin = false,
    this.accounts = const [],
    this.status = 'device',
  });

  bool get isReady => status == 'device';
  bool get isUnauthorized => status == 'unauthorized';
  bool get isOffline => status == 'offline';
  bool get hasAccounts => accounts.isNotEmpty;

  String get displayName {
    if (brand.isNotEmpty && model.isNotEmpty && model != 'Unknown Model') {
      final b = brand[0].toUpperCase() + brand.substring(1).toLowerCase();
      return '$b $model';
    }
    return serial;
  }

  DeviceInfo copyWith({
    String? serial,
    String? model,
    String? brand,
    String? androidVersion,
    int? sdkInt,
    int? batteryLevel,
    bool? isCharging,
    bool? isAppInstalled,
    bool? isDeviceOwner,
    bool? isActiveAdmin,
    List<String>? accounts,
    String? status,
  }) {
    return DeviceInfo(
      serial: serial ?? this.serial,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      androidVersion: androidVersion ?? this.androidVersion,
      sdkInt: sdkInt ?? this.sdkInt,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      isAppInstalled: isAppInstalled ?? this.isAppInstalled,
      isDeviceOwner: isDeviceOwner ?? this.isDeviceOwner,
      isActiveAdmin: isActiveAdmin ?? this.isActiveAdmin,
      accounts: accounts ?? this.accounts,
      status: status ?? this.status,
    );
  }
}
