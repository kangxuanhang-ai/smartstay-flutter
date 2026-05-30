import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_state.dart';
import 'core/ws_service.dart';
import 'widgets/bottom_nav.dart';
import 'pages/home/home_page.dart';
import 'pages/map/map_page.dart';
import 'pages/facility/facility_page.dart';
import 'pages/login/login_page.dart';
import 'pages/change_password/change_password_page.dart';
import 'pages/room_control/room_control_page.dart';
import 'pages/ai_chat/ai_chat_page.dart';
import 'pages/work_order/work_order_page.dart';
import 'pages/my/my_page.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final router = GoRouter(
    refreshListenable: _AuthListenable(authBloc),
    redirect: (context, state) {
      final auth = authBloc.state;
      final loc = state.uri.toString();

      // Only force password change redirect
      if (auth.status == AuthStatus.passwordChangeRequired) {
        if (loc != '/change-password') return '/change-password';
        return null;
      }

      // All routes allow anonymous access - pages handle their own auth UI
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
                final paths = ['/home', '/room-control', '/ai-chat', '/work-orders', '/my'];
                GoRouter.of(context).go(paths[i]);
              },
            ),
          );
        },
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(path: '/room-control', builder: (_, __) => const RoomControlPage()),
          GoRoute(path: '/ai-chat', builder: (_, __) => const AIChatPage()),
          GoRoute(path: '/work-orders', builder: (_, __) => const WorkOrderPage()),
          GoRoute(path: '/my', builder: (_, __) => const MyPage()),
          GoRoute(path: '/map', builder: (_, __) => const MapPage()),
          GoRoute(path: '/facility', builder: (_, __) => const FacilityPage()),
        ],
      ),
    ],
  );

  static int _getTabIndex(String path) {
    if (path.startsWith('/home') || path.startsWith('/map') || path.startsWith('/facility')) return 0;
    if (path.startsWith('/room-control')) return 1;
    if (path.startsWith('/ai-chat')) return 2;
    if (path.startsWith('/work-orders')) return 3;
    if (path.startsWith('/my')) return 4;
    return 0;
  }
}

class _AuthListenable extends ChangeNotifier {
  final AuthBloc bloc;
  StreamSubscription? _sub;
  final _ws = WsService();

  _AuthListenable(this.bloc) {
    _sub = bloc.stream.listen((state) {
      if (state.status == AuthStatus.authenticated) {
        _ws.connect();
      } else {
        _ws.disconnect();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ws.disconnect();
    super.dispose();
  }
}
