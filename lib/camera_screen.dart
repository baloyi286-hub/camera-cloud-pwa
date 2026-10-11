import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;

@JS('cameraCloud')
external CameraCloud get cameraCloud;

@JS()
extension type CameraCloud(JSObject _) implements JSObject {
  external web.HTMLVideoElement preview();
  external JSPromise<JSAny?> start(JSBoolean front);
  external JSPromise<JSAny?> photo(JSString apiBase);
  external JSPromise<JSAny?> record(JSString apiBase);
  external JSPromise<JSAny?> stop();
  external void close();
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const apiBase = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  bool front = false, recording = false, busy = false;
  String status = 'Ready. Allow camera access to begin.';
  bool registered = false;

  @override
  void initState() {
    super.initState();
    ui.platformViewRegistry.registerViewFactory('camera-preview', (_) => cameraCloud.preview());
    registered = true;
  }

  Future<void> action(Future<void> Function() run) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await run();
    } catch (e) {
      setState(() => status = 'Error: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    cameraCloud.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Camera Cloud'), centerTitle: true),
    body: SafeArea(child: Column(children: [
      Expanded(child: Container(color: Colors.black, width: double.infinity,
        child: registered ? const HtmlElementView(viewType: 'camera-preview') : const SizedBox())),
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Text(status, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
          FilledButton.tonalIcon(onPressed: busy || recording ? null : () => action(() async {
            await cameraCloud.start(front.toJS).toDart;
            setState(() => status = 'Camera ready');
          }), icon: const Icon(Icons.videocam), label: const Text('Open camera')),
          OutlinedButton.icon(onPressed: busy || recording ? null : () => action(() async {
            front = !front;
            await cameraCloud.start(front.toJS).toDart;
            setState(() => status = front ? 'Front camera' : 'Rear camera');
          }), icon: const Icon(Icons.flip_camera_ios), label: const Text('Switch')),
          FilledButton.icon(onPressed: busy || recording ? null : () => action(() async {
            await cameraCloud.photo(apiBase.toJS).toDart;
            setState(() => status = 'Photo uploaded');
          }), icon: const Icon(Icons.camera_alt), label: const Text('Photo')),
          FilledButton.icon(onPressed: busy ? null : () => action(() async {
            if (recording) {
              await cameraCloud.stop().toDart;
              setState(() { recording = false; status = 'Recording finished'; });
            } else {
              await cameraCloud.record(apiBase.toJS).toDart;
              setState(() { recording = true; status = 'Recording and uploading chunks'; });
            }
          }), icon: Icon(recording ? Icons.stop : Icons.fiber_manual_record),
            label: Text(recording ? 'Stop' : 'Record')),
        ]),
      ])),
    ])),
  );
}
