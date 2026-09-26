import 'package:equatable/equatable.dart';

/// Un pokémon tel qu'affiché dans la liste (données minimales).
class Pokemon extends Equatable {
  final int id;
  final String name;
  final String imageUrl;

  const Pokemon({required this.id, required this.name, required this.imageUrl});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'imageUrl': imageUrl};

  factory Pokemon.fromJson(Map<String, dynamic> json) => Pokemon(
        id: json['id'] as int,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String,
      );

  @override
  List<Object?> get props => [id, name, imageUrl];
}
