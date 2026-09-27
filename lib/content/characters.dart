import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The friendly hosts who guide children around the universe.
enum CharacterId { cosmo, lexi, pip, dash, luna, coco }

class CharacterInfo {
  const CharacterInfo({
    required this.id,
    required this.name,
    required this.species,
    required this.role,
    required this.color,
  });

  final CharacterId id;
  final String name;
  final String species;
  final String role;
  final Color color;

  String get fullName => '$name the $species';
}

const characters = <CharacterId, CharacterInfo>{
  CharacterId.cosmo: CharacterInfo(
    id: CharacterId.cosmo,
    name: 'Cosmo',
    species: 'Bear',
    role: 'Space captain and your learning buddy',
    color: Color(0xFFB9784A),
  ),
  CharacterId.lexi: CharacterInfo(
    id: CharacterId.lexi,
    name: 'Lexi',
    species: 'Fox',
    role: 'Letters, phonics and reading',
    color: AppColors.reading,
  ),
  CharacterId.pip: CharacterInfo(
    id: CharacterId.pip,
    name: 'Pip',
    species: 'Penguin',
    role: 'Numbers, counting and math',
    color: AppColors.math,
  ),
  CharacterId.dash: CharacterInfo(
    id: CharacterId.dash,
    name: 'Dash',
    species: 'Dino',
    role: 'Puzzles, shapes and thinking games',
    color: AppColors.puzzles,
  ),
  CharacterId.luna: CharacterInfo(
    id: CharacterId.luna,
    name: 'Luna',
    species: 'Owl',
    role: 'Storytime and books',
    color: AppColors.stories,
  ),
  CharacterId.coco: CharacterInfo(
    id: CharacterId.coco,
    name: 'Coco',
    species: 'Bunny',
    role: 'Drawing, coloring and art',
    color: AppColors.art,
  ),
};
