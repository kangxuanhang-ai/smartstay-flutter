import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/chat/chat_bloc.dart';
import 'blocs/room/room_bloc.dart';
import 'blocs/work_order/work_order_bloc.dart';
import 'app.dart';

void main() {
  final authBloc = AuthBloc()..add(AuthBootstrapRequested());
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider.value(value: authBloc),
      BlocProvider(create: (_) => ChatBloc()),
      BlocProvider(create: (_) => RoomBloc()),
      BlocProvider(create: (_) => WorkOrderBloc()),
    ],
    child: SmartStayApp(router: AppRouter(authBloc).router),
  ));
}

class SmartStayApp extends StatelessWidget {
  final GoRouter router;
  const SmartStayApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '智宿云 SmartStay',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1677FF)),
        useMaterial3: true,
      ),
    );
  }
}
