import 'package:flutter/material.dart';

class CustomPositionedElements {
  static Positioned starIconTopRight() {
    return Positioned(
      top: 10,
      right: 18,
      child: Transform.rotate(
        angle: 0.5,
        child: Icon(Icons.star,
            size: 36, color: Colors.orangeAccent.withOpacity(0.18)),
      ),
    );
  }

  static Positioned taaIconTopRight() {
    return Positioned(
      top: 38,
      right: 0,
      child: Transform.rotate(
        angle: 0.3,
        child: Opacity(
          opacity: 0.12,
          child: Image.asset(
            'assets/icons/taa.png',
            width: 32,
            height: 32,
          ),
        ),
      ),
    );
  }

  static Positioned khaIconRightMiddle() {
    return Positioned(
      top: 210,
      right: 0,
      child: Opacity(
        opacity: 0.12,
        child: Transform.rotate(
          angle: 5.9,
          child: Image.asset(
            'assets/icons/kha.png',
            width: 38,
            height: 38,
          ),
        ),
      ),
    );
  }

  static Positioned haaIconBottomRight() {
    return Positioned(
      bottom: 80,
      right: 5,
      child: Opacity(
        opacity: 0.12,
        child: Transform.rotate(
          angle: 0.4,
          child: Image.asset(
            'assets/icons/haa.png',
            width: 38,
            height: 38,
          ),
        ),
      ),
    );
  }

  static Positioned fourIconTopLeft() {
    return Positioned(
      top: 0,
      left: 5,
      child: Opacity(
        opacity: 0.12,
        child: Transform.rotate(
          angle: 0.0,
          child: Image.asset(
            'assets/icons/four.png',
            width: 32,
            height: 32,
          ),
        ),
      ),
    );
  }

  static Positioned dashIconTopLeft() {
    return Positioned(
      top: 60,
      left: 0,
      child: Opacity(
        opacity: 0.12,
        child: Transform.rotate(
          angle: 0.0,
          child: Image.asset(
            'assets/icons/dash.png',
            width: 32,
            height: 32,
          ),
        ),
      ),
    );
  }

  static Positioned seenIconMiddleLeft() {
    return Positioned(
      top: 170,
      left: 5,
      child: Opacity(
        opacity: 0.18,
        child: Transform.rotate(
          angle: 5.8,
          child: Image.asset(
            'assets/icons/seen.png',
            width: 36,
            height: 36,
          ),
        ),
      ),
    );
  }

  static Positioned noonIconBottomLeft() {
    return Positioned(
      bottom: 170,
      left: 5,
      child: Opacity(
        opacity: 0.18,
        child: Transform.rotate(
          angle: 5.5,
          child: Image.asset(
            'assets/icons/noon.png',
            width: 38,
            height: 38,
          ),
        ),
      ),
    );
  }

  static Positioned starIconBottomLeft() {
    return Positioned(
      bottom: 10,
      left: 0,
      child: Transform.rotate(
        angle: 0.5,
        child: Icon(Icons.star,
            size: 36, color: Colors.blueAccent.withOpacity(0.13)),
      ),
    );
  }
}
