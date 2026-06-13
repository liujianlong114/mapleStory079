class GameMap {
  final int id;
  final String name;
  final String description;
  final int width;
  final int height;
  final String? music;
  final String? background;

  GameMap({
    required this.id,
    required this.name,
    required this.description,
    required this.width,
    required this.height,
    this.music,
    this.background,
  });

  factory GameMap.fromJson(Map<String, dynamic> json) {
    return GameMap(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      width: json['width'] ?? 800,
      height: json['height'] ?? 600,
      music: json['music'],
      background: json['background'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'width': width,
      'height': height,
      'music': music,
      'background': background,
    };
  }
}
