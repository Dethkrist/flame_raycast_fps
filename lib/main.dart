import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame_raycast_fps/gameRoot/game.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.device.fullScreen();
  Flame.device.setLandscape();
  runApp(
    GameWidget(
      game: ResurrectionRumbleGame(),
    ),
  );
}
