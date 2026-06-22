import '../generated/l10n/app_localizations.dart';
import '../widgets/user_low_vision_bottom_nav.dart';

const List<NavItemData> familyDashboardNavItems = [
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_graph.svg',
    label: 'Chăm sóc',
    semanticsLabel: 'Mục 1 trên 3: Chăm sóc',
  ),
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_activity.svg',
    label: 'Hoạt động',
    semanticsLabel: 'Mục 2 trên 3: Hoạt động',
  ),
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_location.svg',
    label: 'Vị trí',
    semanticsLabel: 'Mục 3 trên 3: Vị trí',
  ),
];

List<NavItemData> familyDashboardNavItemsLocalized(AppLocalizations l) => [
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_graph.svg',
    label: l.familyDashboardCareTabLabel,
    semanticsLabel: 'Mục 1 trên 3: ${l.familyDashboardCareTabLabel}',
  ),
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_activity.svg',
    label: l.familyDashboardAuditTabLabel,
    semanticsLabel: 'Mục 2 trên 3: ${l.familyDashboardAuditTabLabel}',
  ),
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_location.svg',
    label: l.familyDashboardLocationTabLabel,
    semanticsLabel: 'Mục 3 trên 3: ${l.familyDashboardLocationTabLabel}',
  ),
];
