import '../generated/l10n/app_localizations.dart';
import '../widgets/user_low_vision_bottom_nav.dart';

const List<NavItemData> familyDashboardNavItems = [
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_graph.svg',
    label: 'Chăm sóc',
    semanticsLabel: 'Mục 1 trên 5: Chăm sóc',
  ),
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_heart.svg',
    label: 'Sức khỏe',
    semanticsLabel: 'Mục 2 trên 5: Sức khỏe',
  ),
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_calendar.svg',
    label: 'Thuốc',
    semanticsLabel: 'Mục 3 trên 5: Thuốc',
  ),
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_activity.svg',
    label: 'Hoạt động',
    semanticsLabel: 'Mục 4 trên 5: Hoạt động',
  ),
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_location.svg',
    label: 'Vị trí',
    semanticsLabel: 'Mục 5 trên 5: Vị trí',
  ),
];

List<NavItemData> familyDashboardNavItemsLocalized(AppLocalizations l) => [
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_graph.svg',
    label: l.familyDashboardCareTabLabel,
    semanticsLabel: 'Mục 1 trên 5: ${l.familyDashboardCareTabLabel}',
  ),
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_heart.svg',
    label: l.familyDashboardHealthTabLabel,
    semanticsLabel: 'Mục 2 trên 5: ${l.familyDashboardHealthTabLabel}',
  ),
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_calendar.svg',
    label: l.familyDashboardMedsTabLabel,
    semanticsLabel: 'Mục 3 trên 5: ${l.familyDashboardMedsTabLabel}',
  ),
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_activity.svg',
    label: l.familyDashboardAuditTabLabel,
    semanticsLabel: 'Mục 4 trên 5: ${l.familyDashboardAuditTabLabel}',
  ),
  NavItemData(
    iconAsset: 'assets/icons/nav/ic_location.svg',
    label: l.familyDashboardLocationTabLabel,
    semanticsLabel: 'Mục 5 trên 5: ${l.familyDashboardLocationTabLabel}',
  ),
];
