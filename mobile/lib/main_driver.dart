import 'package:flutter_driver/driver_extension.dart';

import 'bootstrap.dart' as boot;

/// Entry point for simulator MCP / Flutter Driver (Cursor dart MCP tools).
void main() {
  enableFlutterDriverExtension();
  boot.bootstrap();
}
