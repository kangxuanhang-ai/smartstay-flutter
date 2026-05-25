import 'dart:async';
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

const _anonymousRoutes = ['/home', '/map', '/facility'];

class AppRouter {
  final AuthBloc authBloc;
  String? _pendingRedirect;

  AppRouter(this.authBloc);

  late final router = GoRouter(
    refreshListenable: _AuthListenable(authBloc),
    redirect: (context, state) {
      final auth = authBloc.state;
      final loc = state.uri.toString();

      // 1. 账户安全最高优先级：强制改密刚性阻断一切（含匿名白名单）
      if (auth.status == AuthStatus.passwordChangeRequired) {
        if (loc != '/change-password') return '/change-password';
        return null;
      }

      // 2. 健康状态或免登用户，享受匿名白名单放行
      if (_anonymousRoutes.any((r) => loc.startsWith(r))) return null;

      // 3. 未登录用户精准强刷阻断，并动态缓存目标路由
      if (auth.status == AuthStatus.unauthenticated || auth.status == AuthStatus.initial) {
        if (loc != '/login') {
          _pendingRedirect = loc == '/' ? null : loc;
          return '/login';
        }
        return null;
      }

      // 4. 纯净重定向闸：只有真正已登录状态，才允许消耗重定向缓存并放行
      // loading 等中间态安全 fall through 到最后的 return null，原地等待登录 API 成功返回后再触发跳转
      if (auth.status == AuthStatus.authenticated) {
        if (loc == '/login' || loc == '/change-password') {
          final target = _pendingRedirect ?? '/home';
          _pendingRedirect = null;
          return target;
        }
      }
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
          GoRoute(path: '/room-control', builder: (_, __) => const RoomControlPage()),
          GoRoute(path: '/ai-chat', builder: (_, __) => const AIChatPage()),
          GoRoute(path: '/work-orders', builder: (_, __) => const WorkOrderPage()),
          GoRoute(path: '/bill', builder: (_, __) => const BillPage()),
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
    if (path.startsWith('/bill')) return 4;
    return 0;
  }
}

class _AuthListenable extends ChangeNotifier {
  final AuthBloc bloc;
  StreamSubscription? _sub;

  _AuthListenable(this.bloc) {
    _sub = bloc.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
