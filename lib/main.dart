import 'package:fastswipe/app.dart';
import 'package:fastswipe/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(FastSwipeApp(authRepository: MockAuthRepository()));
}
