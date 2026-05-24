import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_state.dart';
import 'widgets/bottom_nav.dart';
import 'pages/home/home_page.dart';
import 'pages/map/map_page.dart';
import 'pages/facility/facility_page.dart';
import 'pages/login/login_page.dart';
import 'pages/change_password/change_password_page.dart';
import 'pages/room_control/room_control_page.dart';
import 'pages/ai_chat/ai_chat_page.dart';
import 'pages/work_order/work_order_page.dart';
import 'pages/bill/bill_page.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final router = GoRouter(
    refreshListenable: _AuthListenable(authBloc),
    redirect: (context, state) {
      final auth = authBloc.state;
      final loc = state.uri.toString();

      if (auth.status == AuthStatus.unauthenticated || auth.status == AuthStatus.initial) {
        if (loc != '/login') return '/login';
        return null;
      }

      if (auth.status == AuthStatus.passwordChangeRequired) {
        if (loc != '/change-password') return '/change-password';
        return null;
      }

      if (loc == '/login' || loc == '/change-password') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordPage()),
      ShellRoute(
        builder: (context, state, child) {
          final index = _getTabIndex(state.uri.toString());
          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNav(
              currentIndex: index,
              onTap: (i) {
                final paths = ['/home', '/room-control', '/ai-chat', '/work-orders', '/bill'];
                GoRouter.of(context).go(paths[i]);
              },
            ),
          );
        },
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(path: '/map', builder: (_, __) => const MapPage()),
          GoRoute(path: '/facility', builder: (_, __) => const FacilityPage()),
          GoRoute(path: '/room-control', builder: (_, __) => const RoomControlPage()),
          GoRoute(path: '/ai-chat', builder: (_, __) => const AIChatPage()),
          GoRoute(path: '/work-orders', builder: (_, __) => const WorkOrderPage()),
          GoRoute(path: '/bill', builder: (_, __) => const BillPage()),
        ],
      ),
    ],
  );

  static int _getTabIndex(String path) {
    if (path.startsWith('/home') || path.startsWith('/map') || path.startsWith('/facility')) return 0;
    if (path.startsWith('/room-control')) return 1;
    if (path.startsWith('/ai-chat')) return 2;
    if (path.startsWith('/work-orders')) return 3;
    if (path.startsWith('/bill')) return 4;
    return 0;
  }
}

class _AuthListenable extends ChangeNotifier {
  final AuthBloc bloc;
  _AuthListenable(this.bloc) {
    bloc.stream.listen((_) => notifyListeners());
  }
}
