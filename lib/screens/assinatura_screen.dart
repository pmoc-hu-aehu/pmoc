import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Tela dedicada de assinatura.
/// Usa GestureDetector + CustomPainter — sem pacote externo, sem conflito de scroll.
/// Retorna [Uint8List] PNG ao confirmar, ou null se cancelar.
class AssinaturaScreen extends StatefulWidget {
  const AssinaturaScreen({super.key});

  @override
  State<AssinaturaScreen> createState() => _AssinaturaScreenState();
}

class _AssinaturaScreenState extends State<AssinaturaScreen> {
  final List<List<Offset?>> _tracos = []; // null = levantar caneta
  final _repaintKey = GlobalKey();
  bool _temAssinatura = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _tracos.add([d.localPosition]);
      _temAssinatura = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _tracos.last.add(d.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() {
      _tracos.last.add(null); // marcador de fim de traço
    });
  }

  void _limpar() {
    setState(() {
      _tracos.clear();
      _temAssinatura = false;
    });
  }

  Future<void> _confirmar() async {
    if (!_temAssinatura) return;

    // Captura o widget como PNG
    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();

    if (mounted) Navigator.pop(context, bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e3a5f),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e3a5f),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: const Text(
          'Assinatura do Responsável',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          TextButton.icon(
            onPressed: _limpar,
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
            label: const Text('Limpar', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Instrução
          Container(
            color: Colors.white.withAlpha(15),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.draw_outlined, color: Colors.white54, size: 16),
                SizedBox(width: 6),
                Text(
                  'Assine com o dedo no campo branco abaixo',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),

          // Canvas de assinatura
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _temAssinatura
                          ? const Color(0xFF22c55e)
                          : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: _AssinaturaPainter(_tracos),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Botão confirmar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _temAssinatura ? _confirmar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22c55e),
                  disabledBackgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _temAssinatura
                      ? 'CONFIRMAR ASSINATURA'
                      : 'ASSINE ACIMA PARA CONTINUAR',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _temAssinatura ? Colors.white : Colors.white38,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssinaturaPainter extends CustomPainter {
  final List<List<Offset?>> tracos;

  _AssinaturaPainter(this.tracos);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final traco in tracos) {
      final pontos = traco.whereType<Offset>().toList();
      if (pontos.isEmpty) continue;

      final path = Path()..moveTo(pontos[0].dx, pontos[0].dy);

      for (int i = 1; i < pontos.length; i++) {
        // Verifica se há null antes deste ponto (fim de traço)
        if (i < traco.length && traco[i] == null) break;
        path.lineTo(pontos[i].dx, pontos[i].dy);
      }

      canvas.drawPath(path, paint);
    }

    // Ponto único (toque sem arrastar)
    for (final traco in tracos) {
      final validos = traco.whereType<Offset>().toList();
      if (validos.length == 1) {
        canvas.drawCircle(validos[0], 2.0, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      }
    }
  }

  @override
  bool shouldRepaint(_AssinaturaPainter old) => true;
}
