///Contains the list of debugging levels
enum LogLevel {
  ///disables all debugging
  off(-1),

  ///default level, shows minimal SDK integration related logging
  info(0),

  ///shows debug output
  debug(2),

  ///shows verbose output
  verbose(3);

  const LogLevel(this.value);

  final int value;
}
