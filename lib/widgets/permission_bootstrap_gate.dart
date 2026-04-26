import 'package:flutter/material.dart';

import '../services/aisee_permission_bootstrap_service.dart';
import 'auth_bootstrapping.dart';

class PermissionBootstrapGate extends StatefulWidget {
  const PermissionBootstrapGate({
    super.key,
    required this.child,
    this.ensurePermissions,
    this.onCompleted,
  });

  final Widget child;
  final Future<void> Function()? ensurePermissions;
  final VoidCallback? onCompleted;

  @override
  State<PermissionBootstrapGate> createState() =>
      _PermissionBootstrapGateState();
}

class _PermissionBootstrapGateState extends State<PermissionBootstrapGate> {
  late final Future<void> _future;
  bool _reportedCompletion = false;

  @override
  void initState() {
    super.initState();
    _future =
        (widget.ensurePermissions ??
        AiseePermissionBootstrapService.instance.ensureBootstrapped)();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AuthBootstrapping(
            title: 'Đang chuẩn bị quyền truy cập…',
          );
        }
        if (!_reportedCompletion && !snapshot.hasError) {
          _reportedCompletion = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCompleted?.call();
          });
        }
        return widget.child;
      },
    );
  }
}
