@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_mfm_renderer/misskey_mfm_renderer.dart';

// Exercise NetworkImage's real response/decode path without sockets or a CDN.
class _Client implements HttpClient {
  _Client(this.response);
  final _Response response;
  final requests = <Uri>[];

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requests.add(url);
    return _Request(response);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request implements HttpClientRequest {
  _Request(this.response);
  final _Response response;

  @override
  Future<HttpClientResponse> close() async => response;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.statusCode, this.bytes);
  @override
  final int statusCode;
  final List<int> bytes;

  @override
  int get contentLength => bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final outcome in ['success', '404', 'decode']) {
    testWidgets('network PNG $outcome via controlled HTTP client', (
      tester,
    ) async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      var bytes = <int>[0, 1, 2];
      if (outcome == 'success') {
        bytes = (await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          Canvas(recorder).drawColor(Colors.green, BlendMode.src);
          final picture = recorder.endRecording();
          final image = await picture.toImage(2, 2);
          picture.dispose();
          try {
            return (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!.buffer.asUint8List();
          } finally {
            image.dispose();
          }
        }))!;
      }
      final client = _Client(_Response(outcome == '404' ? 404 : 200, bytes));
      final previous = debugNetworkImageHttpClientProvider;
      debugNetworkImageHttpClientProvider = () => client;
      try {
        final helper = MfmTwemojiBuilder.network(
          baseUrl: Uri.parse('https://fixture.test:8443/a%20b/png/'),
        );
        final widget = helper.build(
          '❤️',
          const MfmEmojiContext(fontSize: 20, scale: 1),
        );
        expect(client.requests, isEmpty);
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: widget),
          ),
        );
        // Codec futures run outside the fake clock. Poll with a bounded
        // wait, and assert the rendered result rather than invoking callbacks.
        for (var i = 0; i < 50; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
          if (outcome == 'success'
              ? find.byType(RawImage).evaluate().isNotEmpty
              : find.text('❤️').evaluate().isNotEmpty) {
            break;
          }
        }
        expect(client.requests, [
          Uri.parse('https://fixture.test:8443/a%20b/png/2764.png'),
        ]);
        if (outcome == 'success') {
          expect(
            tester.widget<RawImage>(find.byType(RawImage)).image,
            isNotNull,
          );
          expect(find.text('❤️'), findsNothing);
        } else {
          expect(find.text('❤️'), findsOneWidget);
          expect(find.byType(RawImage), findsNothing);
        }
        expect(tester.takeException(), isNull);
      } finally {
        debugNetworkImageHttpClientProvider = previous;
      }
    });
  }
}
