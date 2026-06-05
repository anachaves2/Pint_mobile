import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:pint_mobile/utils/constants.dart';

// Utilização da câmara — Aula 11
// Padrão do professor Paulo Tomé (ESTGV)
// Fases: obter câmaras → inicializar CameraController → CameraPreview → tirar foto
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _aTirarFoto = false;

  @override
  void initState() {
    super.initState();
    _inicializarCamera();
  }

  // Obter lista de câmaras disponíveis e inicializar a primeira
  Future<void> _inicializarCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    // Criar e inicializar CameraController
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // Libertar o controller quando o ecrã é destruído
    _controller.dispose();
    super.dispose();
  }

  // Registar foto através do CameraController
  Future<void> _tirarFoto() async {
    try {
      setState(() => _aTirarFoto = true);
      await _initializeControllerFuture;
      final foto = await _controller.takePicture();
      if (mounted) {
        // Devolve o caminho da foto ao ecrã anterior
        Navigator.pop(context, foto.path);
      }
    } catch (e) {
      debugPrint('Erro ao tirar foto: $e');
    } finally {
      if (mounted) setState(() => _aTirarFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Câmara',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      // FutureBuilder — Aula 6
      // Aguarda a inicialização do CameraController antes de mostrar o preview
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppConstants.corPrimaria),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erro: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white)),
            );
          } else {
            // Mostrar pré-visualização da câmara (CameraPreview)
            return Column(
              children: [
                Expanded(child: CameraPreview(_controller)),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GestureDetector(
                    onTap: _aTirarFoto ? null : _tirarFoto,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _aTirarFoto ? Colors.grey : Colors.white,
                        border: Border.all(color: Colors.grey, width: 3),
                      ),
                      child: _aTirarFoto
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.camera_alt,
                              color: Colors.black, size: 32),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}