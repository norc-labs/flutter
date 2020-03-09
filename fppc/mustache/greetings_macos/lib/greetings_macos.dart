// The url_launcher_platform_interface defaults to MethodChannelUrlLauncher
// as its instance, which is all the macOS implementation needs. This file
// is here to silence warnings when publishing to pub.

import 'dart:async';
import 'dart:html' as html;

// import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:meta/meta.dart';
import 'package:greetings_platform_interface/greetings_platform_interface.dart';
class GreetingsPlugin extends GreetingsPlatform {
  /// Registers this class as the default instance of [GreetingsPlatform].
  static void registerWith(Registrar registrar) {
    print("macos registerWith");
    GreetingsPlatform.instance = GreetingsPlugin();
  }
}
