import 'package:aiseeapp/screens/subscription_screen.dart';
import 'package:aiseeapp/services/aisee_revenuecat_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('planNameForProduct matches the backend care catalog labels', () {
    expect(planNameForProduct(AiseeRevenueCatProduct.basic149k), 'Care Basic');
    expect(planNameForProduct(AiseeRevenueCatProduct.plus399k), 'Care Plus');
    expect(
      planNameForProduct(AiseeRevenueCatProduct.premium599k),
      'Care Premium',
    );
  });
}
