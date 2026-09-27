import 'package:flutter/material.dart';

/// A themed page of collectible stickers in the sticker book.
class StickerPack {
  const StickerPack({
    required this.id,
    required this.name,
    required this.cover,
    required this.color,
    required this.stickers,
    this.premium = false,
  });

  final String id;
  final String name;
  final String cover;
  final Color color;
  final List<String> stickers;
  final bool premium;
}

const stickerPacks = <StickerPack>[
  StickerPack(
    id: 'space',
    name: 'Outer Space',
    cover: '🚀',
    color: Color(0xFF5B4BDB),
    stickers: ['🚀', '🪐', '🌙', '⭐', '☄️', '🛸', '👽', '🌍', '🌞', '🔭', '🌌', '🧑‍🚀'],
  ),
  StickerPack(
    id: 'animals',
    name: 'Animal Friends',
    cover: '🐼',
    color: Color(0xFFFF9F1C),
    stickers: ['🐶', '🐱', '🐼', '🦁', '🐯', '🐸', '🐵', '🦊', '🐨', '🐰', '🐧', '🦉'],
  ),
  StickerPack(
    id: 'yummy',
    name: 'Yummy Treats',
    cover: '🧁',
    color: Color(0xFFFF5FA2),
    stickers: ['🍎', '🍌', '🍓', '🍉', '🍕', '🧁', '🍩', '🍪', '🍦', '🥕', '🌽', '🍇'],
  ),
  StickerPack(
    id: 'ocean',
    name: 'Under the Sea',
    cover: '🐳',
    color: Color(0xFF1FA2D6),
    premium: true,
    stickers: ['🐳', '🐬', '🐙', '🦀', '🐠', '🐡', '🦈', '🐢', '🦑', '🐚', '🦞', '🦭'],
  ),
  StickerPack(
    id: 'dinos',
    name: 'Dino World',
    cover: '🦕',
    color: Color(0xFF34C77B),
    premium: true,
    stickers: ['🦕', '🦖', '🥚', '🌋', '🌴', '🦴', '🐊', '🦎', '🐉', '🌿', '🍄', '🪨'],
  ),
  StickerPack(
    id: 'vehicles',
    name: 'Things That Go',
    cover: '🚒',
    color: Color(0xFFFF5A5F),
    premium: true,
    stickers: ['🚗', '🚒', '🚓', '🚑', '🚌', '🚜', '✈️', '🚁', '🚂', '⛵', '🚲', '🏎️'],
  ),
  StickerPack(
    id: 'magic',
    name: 'Magic Land',
    cover: '🦄',
    color: Color(0xFF8E6CF1),
    premium: true,
    stickers: ['🦄', '🌈', '🧚', '🪄', '👑', '💎', '🔮', '🏰', '🐲', '✨', '🎠', '🧜'],
  ),
];

StickerPack? packOf(String sticker) {
  for (final p in stickerPacks) {
    if (p.stickers.contains(sticker)) return p;
  }
  return null;
}
