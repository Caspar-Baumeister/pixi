import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat wrapper. One entitlement ("premium") unlocks unlimited maps and
/// statistics; it is granted by either the yearly subscription or the
/// lifetime purchase.
///
/// RevenueCat dashboard (project "Pixi"):
///   Entitlement : premium
///   Products    : pixi_premium_yearly   (auto-renewable, 1 year)
///                 pixi_premium_lifetime (non-consumable)
///   Offering    : default, packages $rc_annual + $rc_lifetime
class PremiumService {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  /// RevenueCat *public* Apple SDK key (starts with "appl_"). Safe to ship.
  /// Override at build time with --dart-define=RC_API_KEY=appl_xxx
  static const apiKey = String.fromEnvironment(
    'RC_API_KEY',
    defaultValue: 'appl_YTabUqHlHSzCYOwcIiBWnWZAKzB',
  );

  static const entitlementId = 'premium';
  static const yearlyId = 'pixi_premium_yearly';
  static const lifetimeId = 'pixi_premium_lifetime';

  bool get isConfigured => apiKey.startsWith('appl_') && !apiKey.contains('REPLACE');

  final ValueNotifier<bool?> _pro = ValueNotifier<bool?>(null);

  /// null = unknown yet, true = entitled, false = not entitled.
  ValueListenable<bool?> get pro => _pro;
  bool get isPro => _pro.value == true;

  Future<void> init() async {
    if (!isConfigured) {
      _pro.value = false;
      return;
    }
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      Purchases.addCustomerInfoUpdateListener(_onInfo);
      _onInfo(await Purchases.getCustomerInfo());
    } catch (e) {
      debugPrint('Purchases init failed: $e');
      _pro.value ??= false;
    }
  }

  void _onInfo(CustomerInfo info) {
    _pro.value = info.entitlements.active.containsKey(entitlementId);
  }

  /// Current offering's packages: lifetime first, then yearly.
  Future<List<Package>> packages() async {
    if (!isConfigured) return const [];
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return const [];
      final list = [...current.availablePackages];
      list.sort((a, b) => _rank(a).compareTo(_rank(b)));
      return list;
    } catch (e) {
      debugPrint('Offerings failed: $e');
      return const [];
    }
  }

  int _rank(Package p) => switch (p.packageType) {
        PackageType.lifetime => 0,
        PackageType.annual => 1,
        _ => 2,
      };

  /// True when the entitlement is active afterwards. A cancelled sheet is false.
  Future<bool> purchase(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      _onInfo(result.customerInfo);
      return isPro;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('Purchase failed: $e');
      }
      return false;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  Future<bool> restore() async {
    if (!isConfigured) return false;
    try {
      _onInfo(await Purchases.restorePurchases());
      return isPro;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }
}
