import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

/// オフライン起動と初期化失敗を区別する。
enum ExampleEmojiStatus { online, offline, failed }

class ExampleStartup {
  const ExampleStartup({required this.status, this.config, this.error});

  final ExampleEmojiStatus status;
  final MfmRenderConfig? config;
  final Exception? error;
}

Future<ExampleStartup> resolveExampleStartup({
  required bool offline,
  required Future<MfmRenderConfig> Function() online,
}) async {
  if (offline) {
    return const ExampleStartup(status: ExampleEmojiStatus.offline);
  }
  try {
    return ExampleStartup(
      status: ExampleEmojiStatus.online,
      config: await online(),
    );
  } on Exception catch (error) {
    return ExampleStartup(status: ExampleEmojiStatus.failed, error: error);
  }
}
