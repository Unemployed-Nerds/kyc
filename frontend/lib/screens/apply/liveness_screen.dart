import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/kyc_models.dart';
import '../../theme/app_theme.dart';
import '../../theme/palette.dart';
import 'review_screen.dart';

enum _Challenge { center, turnOne, turnTwo, smile, done }

class LivenessScreen extends StatefulWidget {
  final ApplicationDraft draft;

  const LivenessScreen({super.key, required this.draft});

  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _camera;
  late final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // smiling probability
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  _Challenge _challenge = _Challenge.center;
  double? _firstTurnSign; // +1 or -1, whichever direction was turned first
  bool _processing = false;
  bool _capturing = false;
  String? _cameraError;
  File? _captured;
  int _steadyFrames = 0;

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _captured == null) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera was found on this device.');
        return;
      }
      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        _camera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      await controller.startImageStream(_onFrame);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraError = null;
      });
    } on CameraException catch (e) {
      setState(
        () => _cameraError = e.code == 'CameraAccessDenied'
            ? 'Camera access is turned off. Allow camera access in Settings, then try again.'
            : 'The camera could not be started. Close other camera apps and try again.',
      );
    } catch (_) {
      setState(
        () => _cameraError =
            'The camera could not be started. Close other camera apps and try again.',
      );
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _camera;
    final controller = _controller;
    if (camera == null || controller == null) return null;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    } else {
      var compensation = _orientations[controller.value.deviceOrientation];
      if (compensation == null) return null;
      compensation = camera.lensDirection == CameraLensDirection.front
          ? (camera.sensorOrientation + compensation) % 360
          : (camera.sensorOrientation - compensation + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_processing || _capturing || _challenge == _Challenge.done) return;
    _processing = true;
    try {
      final input = _toInputImage(image);
      if (input == null) return;
      final faces = await _detector.processImage(input);
      if (!mounted) return;
      _evaluate(faces);
    } catch (_) {
      // Skip unreadable frames; the stream keeps flowing.
    } finally {
      _processing = false;
    }
  }

  void _evaluate(List<Face> faces) {
    if (faces.length != 1) {
      // Lost the face (or found several): restart the sequence.
      if (_challenge != _Challenge.center || _steadyFrames != 0) {
        setState(() {
          _challenge = _Challenge.center;
          _firstTurnSign = null;
          _steadyFrames = 0;
        });
      }
      return;
    }

    final face = faces.first;
    final angle = face.headEulerAngleY ?? 0;
    final smile = face.smilingProbability ?? 0;

    switch (_challenge) {
      case _Challenge.center:
        if (angle.abs() < 12) {
          _steadyFrames++;
          if (_steadyFrames >= 3) {
            setState(() {
              _challenge = _Challenge.turnOne;
              _steadyFrames = 0;
            });
          }
        } else {
          _steadyFrames = 0;
        }
      case _Challenge.turnOne:
        if (angle.abs() > 20) {
          setState(() {
            _firstTurnSign = angle.sign;
            _challenge = _Challenge.turnTwo;
          });
        }
      case _Challenge.turnTwo:
        if (_firstTurnSign != null &&
            angle.sign == -_firstTurnSign! &&
            angle.abs() > 20) {
          setState(() => _challenge = _Challenge.smile);
        }
      case _Challenge.smile:
        if (smile > 0.65 && angle.abs() < 15) {
          _capture();
        }
      case _Challenge.done:
        break;
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() {
      _capturing = true;
      _challenge = _Challenge.done;
    });
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final shot = await controller.takePicture();
      if (!mounted) return;
      setState(() => _captured = File(shot.path));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _challenge = _Challenge.center;
        _firstTurnSign = null;
      });
      await controller.startImageStream(_onFrame);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The photo could not be taken. Try once more.'),
        ),
      );
    }
  }

  Future<void> _retake() async {
    setState(() {
      _captured = null;
      _capturing = false;
      _challenge = _Challenge.center;
      _firstTurnSign = null;
      _steadyFrames = 0;
    });
    if (_controller == null) {
      await _initCamera();
    } else if (!_controller!.value.isStreamingImages) {
      await _controller!.startImageStream(_onFrame);
    }
  }

  void _accept() {
    widget.draft.selfie = _captured;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReviewScreen(draft: widget.draft)),
    );
  }

  Future<void> _pickFallbackSelfie() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 92,
      );
      if (file != null) setState(() => _captured = File(file.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open your photos. Allow photo access in Settings.',
          ),
        ),
      );
    }
  }

  String get _instruction => switch (_challenge) {
    _Challenge.center => 'Center your face in the frame',
    _Challenge.turnOne => 'Slowly turn your head to one side',
    _Challenge.turnTwo => 'Now turn to the other side',
    _Challenge.smile => 'Great. Now smile',
    _Challenge.done => 'Hold still…',
  };

  int get _challengeIndex => switch (_challenge) {
    _Challenge.center => 0,
    _Challenge.turnOne => 1,
    _Challenge.turnTwo => 2,
    _Challenge.smile => 3,
    _Challenge.done => 4,
  };

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Palette.inkSurface,
        appBar: AppBar(
          backgroundColor: Palette.inkSurface,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text(
            'Step 3 of 4',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Palette.onDarkMuted,
            ),
          ),
        ),
        body: SafeArea(
          child: _captured != null
              ? _CapturePreview(
                  file: _captured!,
                  onRetake: _retake,
                  onAccept: _accept,
                )
              : _cameraError != null
              ? _CameraError(
                  message: _cameraError!,
                  onRetry: _initCamera,
                  onPickFromGallery: _pickFallbackSelfie,
                )
              : _LiveView(
                  controller: _controller,
                  instruction: _instruction,
                  challengeIndex: _challengeIndex,
                ),
        ),
      ),
    );
  }
}

class _LiveView extends StatelessWidget {
  final CameraController? controller;
  final String instruction;
  final int challengeIndex;

  const _LiveView({
    required this.controller,
    required this.instruction,
    required this.challengeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final ready = controller != null && controller!.value.isInitialized;
    final duration = reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'A live selfie',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Follow the prompts so we know it is really you.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Palette.onDarkMuted),
          ),
        ),
        Expanded(
          child: Center(
            child: ClipOval(
              child: SizedBox(
                width: 280,
                height: 280 * 4 / 3,
                child: ready
                    ? CameraPreview(controller!)
                    : Container(
                        color: Palette.inkSurfaceHi,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Palette.onDarkMuted,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: duration,
          child: Text(
            instruction,
            key: ValueKey(instruction),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 4; i++) ...[
              AnimatedContainer(
                duration: duration,
                width: i < challengeIndex ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i < challengeIndex ? Palette.success : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              if (i < 3) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _CapturePreview extends StatelessWidget {
  final File file;
  final VoidCallback onRetake;
  final VoidCallback onAccept;

  const _CapturePreview({
    required this.file,
    required this.onRetake,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        children: [
          Text(
            'How does this look?',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: ClipOval(
                child: SizedBox(
                  width: 280,
                  height: 280 * 4 / 3,
                  child: Image.file(file, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Palette.ink,
            ),
            onPressed: onAccept,
            child: const Text('Use this photo'),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Palette.onDarkMuted),
            onPressed: onRetake,
            child: const Text('Retake the selfie'),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onPickFromGallery;

  const _CameraError({
    required this.message,
    required this.onRetry,
    required this.onPickFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Palette.inkSurfaceHi,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.no_photography_outlined,
              color: Palette.onDarkMuted,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Camera unavailable',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Palette.onDarkMuted,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Palette.ink,
            ),
            onPressed: onRetry,
            child: const Text('Try the camera again'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Palette.onDarkMuted),
            onPressed: onPickFromGallery,
            child: const Text('Upload a selfie instead'),
          ),
        ],
      ),
    );
  }
}
