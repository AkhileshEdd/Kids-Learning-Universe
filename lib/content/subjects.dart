import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'characters.dart';

enum SubjectId { reading, math, puzzles, art, stories }

enum PlanetStyle { rings, craters, stripes, spots, moon }

class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.planetName,
    required this.tagline,
    required this.color,
    required this.host,
    required this.emoji,
    required this.style,
  });

  final SubjectId id;
  final String name;
  final String planetName;
  final String tagline;
  final Color color;
  final CharacterId host;
  final String emoji;
  final PlanetStyle style;

  CharacterInfo get hostInfo => characters[host]!;
}

const subjects = <SubjectId, Subject>{
  SubjectId.reading: Subject(
    id: SubjectId.reading,
    name: 'Reading',
    planetName: 'Alphabet Planet',
    tagline: 'Letters, sounds and words',
    color: AppColors.reading,
    host: CharacterId.lexi,
    emoji: '🔤',
    style: PlanetStyle.rings,
  ),
  SubjectId.math: Subject(
    id: SubjectId.math,
    name: 'Math',
    planetName: 'Number Planet',
    tagline: 'Counting, adding and more',
    color: AppColors.math,
    host: CharacterId.pip,
    emoji: '🔢',
    style: PlanetStyle.stripes,
  ),
  SubjectId.puzzles: Subject(
    id: SubjectId.puzzles,
    name: 'Thinking',
    planetName: 'Puzzle Planet',
    tagline: 'Shapes, patterns and brain games',
    color: AppColors.puzzles,
    host: CharacterId.dash,
    emoji: '🧩',
    style: PlanetStyle.spots,
  ),
  SubjectId.art: Subject(
    id: SubjectId.art,
    name: 'Art',
    planetName: 'Art Planet',
    tagline: 'Draw, color and create',
    color: AppColors.art,
    host: CharacterId.coco,
    emoji: '🎨',
    style: PlanetStyle.craters,
  ),
  SubjectId.stories: Subject(
    id: SubjectId.stories,
    name: 'Stories',
    planetName: 'Story Moon',
    tagline: 'Books to read and listen to',
    color: AppColors.stories,
    host: CharacterId.luna,
    emoji: '📚',
    style: PlanetStyle.moon,
  ),
};
