import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'sound.dart';

final routeObserver = RouteObserver<ModalRoute<void>>();

/// Screens mix this in to turn background music on (maps, menus) or off
/// (activities and stories, where the narrator needs to be heard).
mixin MusicAware<T extends StatefulWidget> on State<T> implements RouteAware {
  bool get wantsMusic;

  void _apply() {
    if (mounted) context.read<SoundService>().wantMusic(wantsMusic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() => _apply();

  @override
  void didPopNext() => _apply();

  @override
  void didPop() {}

  @override
  void didPushNext() {}
}
