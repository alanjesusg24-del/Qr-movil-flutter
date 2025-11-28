import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'flutter_gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Order QR System'**
  String get app_title;

  /// No description provided for @home_title.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_title;

  /// No description provided for @home_nearby_businesses.
  ///
  /// In en, this message translates to:
  /// **'Nearby Businesses'**
  String get home_nearby_businesses;

  /// No description provided for @home_subscribed_businesses.
  ///
  /// In en, this message translates to:
  /// **'Subscribed Businesses'**
  String get home_subscribed_businesses;

  /// No description provided for @home_view_all.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get home_view_all;

  /// No description provided for @home_see_on_map.
  ///
  /// In en, this message translates to:
  /// **'See on Map'**
  String get home_see_on_map;

  /// No description provided for @home_empty_subscribed.
  ///
  /// In en, this message translates to:
  /// **'No businesses subscribed yet'**
  String get home_empty_subscribed;

  /// No description provided for @home_empty_nearby.
  ///
  /// In en, this message translates to:
  /// **'No businesses nearby'**
  String get home_empty_nearby;

  /// No description provided for @action_scan_qr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get action_scan_qr;

  /// No description provided for @action_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get action_save;

  /// No description provided for @action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get action_cancel;

  /// No description provided for @action_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get action_edit;

  /// No description provided for @action_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get action_delete;

  /// No description provided for @action_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get action_search;

  /// No description provided for @action_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get action_refresh;

  /// No description provided for @action_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get action_continue;

  /// No description provided for @action_accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get action_accept;

  /// No description provided for @action_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get action_close;

  /// No description provided for @action_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get action_back;

  /// No description provided for @action_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get action_logout;

  /// No description provided for @auth_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get auth_login;

  /// No description provided for @auth_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get auth_email;

  /// No description provided for @auth_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_password;

  /// No description provided for @auth_forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get auth_forgot_password;

  /// No description provided for @auth_google_signin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get auth_google_signin;

  /// No description provided for @auth_verify_email.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get auth_verify_email;

  /// No description provided for @auth_logout_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get auth_logout_confirm;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settings_account;

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

  /// No description provided for @settings_version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settings_version;

  /// No description provided for @business_details.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get business_details;

  /// No description provided for @business_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get business_address;

  /// No description provided for @business_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get business_phone;

  /// No description provided for @business_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get business_email;

  /// No description provided for @business_website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get business_website;

  /// No description provided for @business_hours.
  ///
  /// In en, this message translates to:
  /// **'Business Hours'**
  String get business_hours;

  /// No description provided for @order_status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get order_status_pending;

  /// No description provided for @order_status_ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get order_status_ready;

  /// No description provided for @order_status_delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get order_status_delivered;

  /// No description provided for @order_status_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get order_status_cancelled;

  /// No description provided for @error_network.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection'**
  String get error_network;

  /// No description provided for @error_unknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get error_unknown;

  /// No description provided for @error_unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized access'**
  String get error_unauthorized;

  /// No description provided for @error_not_found.
  ///
  /// In en, this message translates to:
  /// **'Resource not found'**
  String get error_not_found;

  /// No description provided for @error_server.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later'**
  String get error_server;

  /// No description provided for @success_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get success_saved;

  /// No description provided for @success_deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get success_deleted;

  /// No description provided for @success_updated.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully'**
  String get success_updated;

  /// No description provided for @subscription_premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get subscription_premium;

  /// No description provided for @subscription_free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get subscription_free;

  /// No description provided for @subscription_activate_premium.
  ///
  /// In en, this message translates to:
  /// **'Activate Premium'**
  String get subscription_activate_premium;

  /// No description provided for @subscription_deactivate_premium.
  ///
  /// In en, this message translates to:
  /// **'Change to Free'**
  String get subscription_deactivate_premium;

  /// No description provided for @map_title.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map_title;

  /// No description provided for @all_businesses_title.
  ///
  /// In en, this message translates to:
  /// **'All Businesses'**
  String get all_businesses_title;

  /// No description provided for @drawer_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get drawer_home;

  /// No description provided for @drawer_businesses.
  ///
  /// In en, this message translates to:
  /// **'All Businesses'**
  String get drawer_businesses;

  /// No description provided for @drawer_map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get drawer_map;

  /// No description provided for @drawer_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawer_settings;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @no_data.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get no_data;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
