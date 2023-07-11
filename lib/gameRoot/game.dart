import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/geometry.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResurrectionRumbleGame extends FlameGame
    with
        HasCollisionDetection,
        KeyboardEvents,
        MouseMovementDetector,
        HasGameRef {
  Ray2? ray;
  Ray2? reflection;
  Vector2 origin = Vector2(100, 100);
  double movementSpeed = 0;
  double playerAngle = 0;
  Paint paint = Paint();

  final _colorTween = ColorTween(
    begin: Colors.blue.withOpacity(0.2),
    end: Colors.red.withOpacity(0.2),
  );

  static const numberOfRays = 1000;
  static const double fov = 60;
  final List<Ray2> rays = [];
  final List<RaycastResult<ShapeHitbox>> results = [];

  late Path path;
  @override
  Future<void> onLoad() async {
    final paint = BasicPalette.gray.paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    add(ScreenHitbox());
    add(
      CircleComponent(
        position: Vector2(100, 100),
        radius: 50,
        paint: paint,
        children: [CircleHitbox()],
      ),
    );
    add(
      CircleComponent(
        position: Vector2(150, 500),
        radius: 50,
        paint: paint,
        children: [CircleHitbox()],
      ),
    );
    add(
      RectangleComponent(
        position: Vector2.all(300),
        size: Vector2.all(100),
        paint: paint,
        children: [RectangleHitbox()],
      ),
    );
    add(
      RectangleComponent(
        position: Vector2.all(500),
        size: Vector2(100, 200),
        paint: paint,
        children: [RectangleHitbox()],
      ),
    );
    add(
      RectangleComponent(
        position: Vector2(550, 200),
        size: Vector2(200, 150),
        paint: paint,
        children: [RectangleHitbox()],
      ),
    );
  }

  @override
  KeyEventResult onKeyEvent(
      RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isKeyDown = event is RawKeyDownEvent;

    if (isKeyDown) {
      if (keysPressed.contains(LogicalKeyboardKey.keyW)) {
        movementSpeed = 100;
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyS)) {
        movementSpeed = -100;
      }

      return KeyEventResult.handled;
    } else {
      movementSpeed = 0;
      return KeyEventResult.ignored;
    }
  }

  @override
  void onMouseMove(PointerHoverInfo info) =>
      playerAngle = info.eventPosition.game.r / 100;

  var _timePassed = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    movePlayer(dt);
    _timePassed += dt;
    final startAngle = playerAngle + toRadians(fov);
    paint.color = _colorTween.transform(0.5 + (sin(_timePassed) / 2))!;
    collisionDetection.raycastAll(
      origin,
      startAngle: startAngle,
      sweepAngle: -toRadians(fov),
      numberOfRays: numberOfRays,
      rays: rays,
      out: results,
    );
  }

  void movePlayer(double dt) {
    origin.x += cos(playerAngle) * movementSpeed * dt;
    origin.y += sin(playerAngle) * movementSpeed * dt;
  }

  double toRadians(double deg) => (deg * pi) / 180;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    renderResult(canvas, origin, results, paint);
  }

  double fixFishEyeDistance(
      double rayAngle, double playerAngle, double distance) {
    final angleDiff = rayAngle - playerAngle;
    return distance * cos(angleDiff);
  }

  void renderResult(
    Canvas canvas,
    Vector2 origin,
    List<RaycastResult<ShapeHitbox>> results,
    Paint paint,
  ) {
    final originOffset = origin.toOffset();
    for (final result in results) {
      if (!result.isActive) {
        continue;
      }
      final resultIndex = results.indexOf(result);
      final intersectionPoint = result.intersectionPoint!.toOffset();
      canvas.drawLine(
        originOffset,
        intersectionPoint,
        paint,
      );

      canvas.drawLine(originOffset, originOffset + Offset.infinite,
          Paint()..color = Colors.purple);

      final double fixedDistance = fixFishEyeDistance(
        rays[resultIndex].direction.r,
        playerAngle,
        result.distance!,
      );

      final double wallHeight = (45 * 5 / result.distance!) * 277;

      final double wallTop = gameRef.size.y / 2 - wallHeight / 2;
      final double wallBottom = gameRef.size.y / 2 + wallHeight / 2;

      final distanceRatio = result.distance! / 2500;

      final Color wallShadedColor =
          Colors.blue.withOpacity(1 - distanceRatio * 1.5);
      final Paint wallPaint = Paint()..color = wallShadedColor;

      canvas.drawRect(
        Rect.fromLTRB(
          resultIndex.toDouble() * (gameRef.size.x / results.length),
          wallTop,
          (resultIndex.toDouble() + 1) * (gameRef.size.x / results.length),
          wallBottom,
        ),
        wallPaint,
      );

      final floorGradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.grey.withOpacity(1),
          Colors.grey.withOpacity(0),
        ],
        stops: const [0, 1],
      );

      final floorPaint = Paint()
        ..shader = floorGradient.createShader(
          Rect.fromLTRB(
            resultIndex.toDouble() * (gameRef.size.x / results.length),
            wallTop,
            (resultIndex.toDouble() + 1) * (gameRef.size.x / results.length),
            gameRef.size.y,
          ),
        );

      canvas.drawRect(
        Rect.fromLTRB(
          resultIndex.toDouble() * (gameRef.size.x / results.length),
          wallBottom,
          (resultIndex.toDouble() + 1) * (gameRef.size.x / results.length),
          gameRef.size.y,
        ),
        floorPaint,
      );
    }
  }
}
