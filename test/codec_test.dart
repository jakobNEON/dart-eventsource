library codec_test;

import "dart:async";
import "dart:convert";

import "package:test/test.dart";

import "package:eventsource/src/decoder.dart";
import "package:eventsource/src/encoder.dart";
import "package:eventsource/src/event.dart";

Map<Event, String> _VECTORS = {
  new Event(id: "1", event: "Add", data: "This is a test"):
      "id: 1\nevent: Add\ndata: This is a test\n\n",
  new Event(data: "This message, it\nhas two lines."):
      "data: This message, it\ndata: has two lines.\n\n",
};

void main() {
  group("encoder", () {
    test("vectors", () {
      var encoder = new EventSourceEncoder();
      for (Event event in _VECTORS.keys) {
        var encoded = _VECTORS[event]!;
        expect(encoder.convert(event), equals(utf8.encode(encoded)));
      }
    });
    //TODO add gzip test
  });

  group("decoder", () {
    test("vectors", () async {
      for (Event event in _VECTORS.keys) {
        var encoded = _VECTORS[event];
        var stream = new Stream.fromIterable([encoded])
            .transform(new Utf8Encoder())
            .transform(new EventSourceDecoder());
        stream.listen(expectAsync((decodedEvent) {
          expect(decodedEvent.id, equals(event.id));
          expect(decodedEvent.event, equals(event.event));
          expect(decodedEvent.data, equals(event.data));
        }, count: 1) as void Function(Event)?);
      }
    });
    test("pass retry value", () async {
      Event event = new Event(id: "1", event: "Add", data: "This is a test");
      String encodedWithRetry =
          "id: 1\nevent: Add\ndata: This is a test\nretry: 100\n\n";
      var changeRetryValue = expectAsync((Duration value) {
        expect(value.inMilliseconds, equals(100));
      }, count: 1);
      var stream = new Stream.fromIterable([encodedWithRetry])
          .transform(new Utf8Encoder())
          .transform(new EventSourceDecoder(retryIndicator: changeRetryValue as void Function(Duration)?));
      stream.listen(expectAsync((decodedEvent) {
        expect(decodedEvent.id, equals(event.id));
        expect(decodedEvent.event, equals(event.event));
        expect(decodedEvent.data, equals(event.data));
      }, count: 1) as void Function(Event)?);
    });
  });
}
