import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_bootstrapping.dart';
import 'auth_shell.dart';

/// Lớp ngoài: chờ SharedPreferences sẵn sàng rồi mới mount [AuthShell]
/// (kiểm tra auth + Google Sign-In bên trong).
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<void> _prefsReady;

  @override
  void initState() {
    super.initState();
    _prefsReady = SharedPreferences.getInstance().then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _prefsReady,
      builder: (BuildContext context, AsyncSnapshot<void> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const AuthBootstrapping(title: 'Đang tải ứng dụng…');
        }
        return const AuthShell();
      },
    );
  }
}
