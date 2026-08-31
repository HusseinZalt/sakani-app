import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/forgot_password_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/otp_verification_screen.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../../features/complaints/domain/entities/complaint.dart';
import '../../features/complaints/presentation/pages/add_complaint_screen.dart';
import '../../features/complaints/presentation/pages/complaint_detail_screen.dart';
import '../../features/complaints/presentation/pages/complaints_screen.dart';
import '../../features/groups/presentation/pages/groups_screen.dart';
import '../../features/home/domain/entities/home_dashboard.dart';
import '../../features/home/presentation/pages/ad_detail_screen.dart';
import '../../features/home/presentation/pages/all_ads_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/home/presentation/pages/main_shell_screen.dart';
import '../../features/housing_request/presentation/pages/housing_request_screen.dart';
import '../../features/maintenance/presentation/pages/create_maintenance_screen.dart';
import '../../features/maintenance/presentation/pages/maintenance_list_screen.dart';
import '../../features/notifications/presentation/pages/notifications_screen.dart';
import '../../features/profile/presentation/pages/documents_screen.dart';
import '../../features/profile/presentation/pages/edit_profile_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/settings/presentation/pages/change_password_screen.dart';
import '../../features/settings/presentation/pages/privacy_policy_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/settings/presentation/pages/support_screen.dart';
import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../features/wallet/presentation/pages/qr_scan_screen.dart';
import '../../features/wallet/presentation/pages/wallet_screen.dart';

/// أسماء ومسارات جميع شاشات التطبيق في مكان واحد، لتفادي كتابة السلاسل
/// النصية (Strings) يدوياً عبر الكود والتقليل من الأخطاء الإملائية.
class AppRoutes {
  const AppRoutes._();

  static const splash = 'splash';
  static const login = 'login';
  static const register = 'register';
  static const otp = 'otp';
  static const forgotPassword = 'forgotPassword';

  // ==================== تبويبات شريط التنقل السفلي الخمسة ====================
  static const profile = 'profile';
  static const notifications = 'notifications';
  static const groups = 'groups';
  static const housingRequest = 'housingRequest';
  static const home = 'home';

  // ==================== شاشات يُصل إليها بالدفع (Push) من الرئيسية ====================
  static const complaints = 'complaints';
  static const addComplaint = 'addComplaint';
  static const complaintDetails = 'complaintDetails';
  static const settings = 'settings';
  static const editProfile = 'editProfile';
  static const maintenanceList = 'maintenanceList';
  static const createMaintenance = 'createMaintenance';
  static const adDetails = 'adDetails';
  static const allAds = 'allAds';
  static const changePassword = 'changePassword';
  static const privacyPolicy = 'privacyPolicy';
  static const documents = 'documents';
  static const support = 'support';
  static const wallet = 'wallet';
  static const walletScan = 'walletScan';

  static const splashPath = '/splash';
  static const loginPath = '/login';
  static const registerPath = '/register';
  static const otpPath = '/otp';
  static const forgotPasswordPath = '/forgot-password';

  static const profilePath = '/profile';
  static const notificationsPath = '/notifications';
  static const groupsPath = '/groups';
  static const housingRequestPath = '/housing-request';
  static const homePath = '/home';

  static const complaintsPath = '/complaints';
  static const addComplaintPath = 'add';
  static const complaintDetailsPath = ':id';
  static const settingsPath = '/settings';
  static const editProfilePath = '/edit-profile';
  static const maintenanceListPath = '/maintenance';
  static const createMaintenancePath = 'new';
  static const adDetailsPath = '/ads/:id';
  static const allAdsPath = '/ads';
  static const changePasswordPath = '/change-password';
  static const privacyPolicyPath = '/privacy-policy';
  static const documentsPath = '/documents';
  static const supportPath = '/support';
  static const walletPath = '/wallet';
  static const walletScanPath = 'scan';
}

/// إعداد التنقل الموحّد للتطبيق باستخدام GoRouter.
///
/// يعتمد التطبيق على [StatefulShellRoute] لعرض شريط تنقل سفلي ثابت بخمسة
/// تبويبات (الملف، الإشعارات، الغروبات، طلب السكن، الرئيسية) مطابقة
/// للتصميم المعتمد، مع الحفاظ على حالة كل تبويب بشكل مستقل عند التنقل
/// بينها. الشاشات الأخرى (الخدمات، الشكاوى، الصيانة، الإعدادات) يُصل
/// إليها بالدفع (push) فوق التبويبات، وليست تبويبات مستقلة.
class AppRouter {
  const AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GlobalKey<NavigatorState> _profileNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'profileTab');
  static final GlobalKey<NavigatorState> _notificationsNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'notificationsTab');
  static final GlobalKey<NavigatorState> _groupsNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'groupsTab');
  static final GlobalKey<NavigatorState> _housingRequestNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'housingRequestTab');
  static final GlobalKey<NavigatorState> _homeNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'homeTab');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splashPath,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerPath,
        name: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpPath,
        name: AppRoutes.otp,
        builder: (context, state) {
          final args =
              state.extra as OtpRouteArgs? ??
              const OtpRouteArgs(identifier: '');
          return OtpVerificationScreen(
            identifier: args.identifier,
            password: args.password,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordPath,
        name: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsPath,
        name: AppRoutes.settings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfilePath,
        name: AppRoutes.editProfile,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePasswordPath,
        name: AppRoutes.changePassword,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicyPath,
        name: AppRoutes.privacyPolicy,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.supportPath,
        name: AppRoutes.support,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.documentsPath,
        name: AppRoutes.documents,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.complaintsPath,
        name: AppRoutes.complaints,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ComplaintsScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.addComplaintPath,
            name: AppRoutes.addComplaint,
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const AddComplaintScreen(),
          ),
          GoRoute(
            path: AppRoutes.complaintDetailsPath,
            name: AppRoutes.complaintDetails,
            parentNavigatorKey: rootNavigatorKey,
            builder:
                (context, state) => ComplaintDetailScreen(
                  complaintId: state.pathParameters['id']!,
                  complaint:
                      state.extra is Complaint
                          ? state.extra as Complaint
                          : null,
                ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.walletPath,
        name: AppRoutes.wallet,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WalletScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.walletScanPath,
            name: AppRoutes.walletScan,
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const QrScanScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.allAdsPath,
        name: AppRoutes.allAds,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AllAdsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adDetailsPath,
        name: AppRoutes.adDetails,
        parentNavigatorKey: rootNavigatorKey,
        builder:
            (context, state) => AdDetailScreen(
              adId: state.pathParameters['id']!,
              announcement:
                  state.extra is Announcement
                      ? state.extra as Announcement
                      : null,
            ),
      ),
      GoRoute(
        path: AppRoutes.maintenanceListPath,
        name: AppRoutes.maintenanceList,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MaintenanceListScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.createMaintenancePath,
            name: AppRoutes.createMaintenance,
            parentNavigatorKey: rootNavigatorKey,
            builder:
                (context, state) => CreateMaintenanceScreen(
                  initialCategory: state.extra as String?,
                ),
          ),
        ],
      ),

      // الحاوية الرئيسية (Shell) مع شريط التنقل السفلي.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.profilePath,
                name: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _notificationsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.notificationsPath,
                name: AppRoutes.notifications,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _groupsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.groupsPath,
                name: AppRoutes.groups,
                builder: (context, state) => const GroupsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _housingRequestNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.housingRequestPath,
                name: AppRoutes.housingRequest,
                builder: (context, state) => const HousingRequestScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.homePath,
                name: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
