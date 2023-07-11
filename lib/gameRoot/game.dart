import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/geometry.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResurrectionRumbleGame extends FlameGame
    with
        HasCollisionDetection,
        MouseMovementDetector,
        KeyboardEvents,
        HasGameRef {
  Ray2? ray;
  Ray2? reflection;
  Vector2 origin = Vector2(100, 100);
  double startAngle = 0;
  Paint paint = Paint();

  final _colorTween = ColorTween(
    begin: Colors.blue.withOpacity(0.2),
    end: Colors.red.withOpacity(0.2),
  );

  static const numberOfRays = 1000;
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
  void onMouseMove(PointerHoverInfo info) {
    startAngle = info.eventPosition.game.r / 100;
  }

  @override
  KeyEventResult onKeyEvent(
      RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isKeyDown = event is RawKeyDownEvent;
    var moveX = 0.0;
    var moveY = 0.0;

    if (isKeyDown) {
      final double movementSpeed = 10;

      if (keysPressed.contains(LogicalKeyboardKey.keyW)) {
        moveX = cos(startAngle) * movementSpeed;
        moveY = sin(startAngle) * movementSpeed;
      } else if (keysPressed.contains(LogicalKeyboardKey.keyA)) {
        moveX = cos(startAngle - pi / 2) * movementSpeed;
        moveY = sin(startAngle - pi / 2) * movementSpeed;
      } else if (keysPressed.contains(LogicalKeyboardKey.keyS)) {
        moveX = cos(startAngle + pi) * movementSpeed;
        moveY = sin(startAngle + pi) * movementSpeed;
      } else if (keysPressed.contains(LogicalKeyboardKey.keyD)) {
        moveX = cos(startAngle + pi / 2) * movementSpeed;
        moveY = sin(startAngle + pi / 2) * movementSpeed;
      } else {
        return KeyEventResult.ignored;
      }

      origin += Vector2(moveX, moveY);

      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }
  }

  var _timePassed = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _timePassed += dt;
    paint.color = _colorTween.transform(0.5 + (sin(_timePassed) / 2))!;
    collisionDetection.raycastAll(
      origin,
      startAngle: startAngle,
      sweepAngle: 1,
      numberOfRays: numberOfRays,
      rays: rays,
      out: results,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    renderResult(canvas, origin, results, paint);
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
      final intersectionPoint = result.intersectionPoint!.toOffset();
      canvas.drawLine(
        originOffset,
        intersectionPoint,
        paint,
      );

      canvas.drawLine(originOffset, originOffset + Offset.infinite,
          Paint()..color = Colors.purple);

      final double wallHeight = (45 * 5 / result.distance!) * 277;

      final double wallTop = gameRef.size.y / 2 - wallHeight / 2;
      final double wallBottom = gameRef.size.y / 2 + wallHeight / 2;

      final distanceRatio = result.distance! / 1300;

      final Color shadedColor = Colors.blue.withOpacity(1 - distanceRatio);
      final Paint wallPaint = Paint()..color = shadedColor;

      canvas.drawRect(
        Rect.fromLTRB(
          results.indexOf(result).toDouble() *
              (gameRef.size.x / results.length),
          wallTop,
          (results.indexOf(result).toDouble() + 1) *
              (gameRef.size.x / results.length),
          wallBottom,
        ),
        wallPaint,
      );
    }
  }
}
