import 'package:flutter/material.dart';

class MiniMapWidget extends StatelessWidget {
  final int mapWidth;
  final int mapHeight;
  final double playerX;
  final double playerY;
  final String mapName;
  final List<Map<String, double>>? npcPositions;
  final List<Map<String, double>>? mobPositions;
  final Color backgroundColor;

  const MiniMapWidget({
    super.key,
    required this.mapWidth,
    required this.mapHeight,
    required this.playerX,
    required this.playerY,
    required this.mapName,
    this.npcPositions,
    this.mobPositions,
    this.backgroundColor = const Color(0xFF2c2c54),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      width: 180,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white30, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              mapName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          AspectRatio(
            aspectRatio: 1.5,
            child: CustomPaint(
              painter: _MapPainter(
                mapWidth: mapWidth,
                mapHeight: mapHeight,
                playerX: playerX,
                playerY: playerY,
                npcPositions: npcPositions ?? [],
                mobPositions: mobPositions ?? [],
              ),
              child: Container(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.person, size: 14, color: Colors.green),
                const Icon(Icons.location_city, size: 14, color: Colors.yellow),
                const Icon(Icons.skull_next_outlined, size: 14, color: Colors.red),
                Text(
                  '(${playerX.round()}, ${playerY.round()})',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final int mapWidth;
  final int mapHeight;
  final double playerX;
  final double playerY;
  final List<Map<String, double>> npcPositions;
  final List<Map<String, double>> mobPositions;

  _MapPainter({
    required this.mapWidth,
    required this.mapHeight,
    required this.playerX,
    required this.playerY,
    required this.npcPositions,
    required this.mobPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / mapWidth;
    final scaleY = size.height / mapHeight;

    final bgPaint = Paint()
      ..color = const Color(0xFF474787)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final linePaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), linePaint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }

    // NPC points (yellow)
    for (final pos in npcPositions) {
      final x = (pos['x'] ?? 0) * scaleX;
      final y = (pos['y'] ?? 0) * scaleY;
      canvas.drawCircle(
        Offset(x.clamp(0, size.width), y.clamp(0, size.height)),
        4.0,
        Paint()..color = Colors.yellow,
      );
    }

    // Mob points (red)
    for (final pos in mobPositions) {
      final x = (pos['x'] ?? 0) * scaleX;
      final y = (pos['y'] ?? 0) * scaleY;
      canvas.drawCircle(
        Offset(x.clamp(0, size.width), y.clamp(0, size.height)),
        3.0,
        Paint()..color = Colors.redAccent,
      );
    }

    // Player (green)
    final px = playerX * scaleX;
    final py = playerY * scaleY;
    canvas.drawCircle(
      Offset(px.clamp(5.0, size.width - 5), py.clamp(5.0, size.height - 5)),
      5.0,
      Paint()..color = Colors.greenAccent,
    );
    canvas.drawCircle(
      Offset(px.clamp(5.0, size.width - 5), py.clamp(5.0, size.height - 5)),
      8.0,
      Paint()
        ..color = Colors.greenAccent.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
