import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat wrapper. One entitlement ("premium") unlocks the app; it is
/// granted by the monthly subscription (7-day free trial) or the lifetime
/// purchase. Since 1.1.0 the paywall is hard for new users; people who
/// installed 1.0.0 keep the old free tier (see [legacy]).
///
/// RevenueCat dashboard (project "Pixi"):
///   Entitlement : premium
///   Products    : pixi_premium_monthly  (auto-renewable, 1 month, 7-day trial)
///                 pixi_premium_lifetime (non-consumable)
///                 pixi_premium_yearly   (legacy, no longer offered)
///   Offering    : default, packages $rc_monthly + $rc_lifetime
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
  static const monthlyId = 'pixi_premium_monthly';
  static const yearlyId = 'pixi_premium_yearly';
  static const lifetimeId = 'pixi_premium_lifetime';

  bool get isConfigured => apiKey.startsWith('appl_') && !apiKey.contains('REPLACE');

  final ValueNotifier<bool?> _pro = ValueNotifier<bool?>(null);

  /// null = unknown yet, true = entitled, false = not entitled.
  ValueListenable<bool?> get pro => _pro;
  bool get isPro => _pro.value == true;

  /// Last build that shipped with the free tier (1.0.0 (11)). Anyone whose
  /// original download is this build or older keeps it, also after a
  /// reinstall. The primary check is local (see Settings.legacyFree).
  static const int lastFreeBuild = 11;

  /// True when the App Store receipt says the app was first downloaded as a
  /// build with the free tier. Sandbox and TestFlight report "1.0" there,
  /// which is not a plain build number and therefore never counts.
  final ValueNotifier<bool> legacy = ValueNotifier<bool>(false);

  /// Technical reason of the last failed store call, shown small on the
  /// paywall's error box so a screenshot tells us what went wrong.
  String? lastError;

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
    final build = int.tryParse(info.originalApplicationVersion ?? '');
    if (build != null && build <= lastFreeBuild) legacy.value = true;
    _pro.value = info.entitlements.active.containsKey(entitlementId);
  }

  /// Debug builds only: pretend the entitlement is active.
  void debugGrant() {
    if (kDebugMode) _pro.value = true;
  }

  /// Current offering's packages: monthly first, then lifetime.
  Future<List<Package>> packages() async {
    if (!isConfigured) return const [];
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        lastError = 'no current offering';
        return const [];
      }
      lastError = null;
      final list = [...current.availablePackages];
      list.sort((a, b) => _rank(a).compareTo(_rank(b)));
      return list;
    } catch (e) {
      debugPrint('Offerings failed: $e');
      lastError = e is PlatformException ? (e.message ?? e.code) : '$e';
      return const [];
    }
  }

  int _rank(Package p) => switch (p.packageType) {
        PackageType.monthly => 0,
        PackageType.lifetime => 1,
        PackageType.annual => 2,
        _ => 3,
      };

  /// "3 Tage" style free trial of a package, null when there is none.
  static IntroductoryPrice? freeTrial(Package? p) {
    final intro = p?.storeProduct.introductoryPrice;
    if (intro == null || intro.price > 0) return null;
    return intro;
  }

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
