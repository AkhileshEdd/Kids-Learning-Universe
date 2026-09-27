import 'package:flutter/material.dart';

import '../models/grade.dart';
import 'characters.dart';

enum SceneBg { space, night, sky, meadow, forest, snow, ocean, beach, indoor, rain, sunset }

enum SpriteMotion { none, bob, sway, drift, pulse, spin }

/// Something placed in a storybook illustration.
class Sprite {
  const Sprite(this.emoji, this.x, this.y, {this.size = 0.28, this.motion = SpriteMotion.bob, this.flip = false})
      : character = null;

  const Sprite.char(this.character, this.x, this.y, {this.size = 0.5, this.motion = SpriteMotion.bob})
      : emoji = null,
        flip = false;

  final String? emoji;
  final CharacterId? character;

  /// Center position as a fraction of the scene (0..1).
  final double x;
  final double y;

  /// Height as a fraction of the scene height.
  final double size;
  final SpriteMotion motion;
  final bool flip;
}

class Scene {
  const Scene(this.bg, this.sprites);
  final SceneBg bg;
  final List<Sprite> sprites;
}

class BookPage {
  const BookPage(this.en, this.es, this.scene);
  final String en;
  final String es;
  final Scene scene;

  String text(bool spanish) => spanish ? es : en;
}

enum BookKind { story, nonfiction }

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.titleEs,
    required this.cover,
    required this.color,
    required this.kind,
    required this.pages,
    this.minGrade = Grade.preschool,
    this.maxGrade = Grade.grade2,
    this.premium = false,
  });

  final String id;
  final String title;
  final String titleEs;
  final Scene cover;
  final Color color;
  final BookKind kind;
  final List<BookPage> pages;
  final Grade minGrade;
  final Grade maxGrade;
  final bool premium;

  String titleIn(bool spanish) => spanish ? titleEs : title;
  bool fitsGrade(Grade g) => g >= minGrade && g <= maxGrade;
}

const books = <Book>[
  Book(
    id: 'cosmo_trip',
    title: "Cosmo's Big Trip",
    titleEs: 'El gran viaje de Cosmo',
    color: Color(0xFF5B4BDB),
    kind: BookKind.story,
    maxGrade: Grade.grade1,
    cover: Scene(SceneBg.space, [
      Sprite.char(CharacterId.cosmo, 0.38, 0.55, size: 0.62),
      Sprite('🚀', 0.72, 0.4, size: 0.34, motion: SpriteMotion.drift),
      Sprite('⭐', 0.12, 0.2, size: 0.12, motion: SpriteMotion.pulse),
    ]),
    pages: [
      BookPage(
        'This is Cosmo the Bear. Cosmo has a shiny rocket.',
        'Este es Cosmo el Oso. Cosmo tiene un cohete brillante.',
        Scene(SceneBg.space, [
          Sprite.char(CharacterId.cosmo, 0.34, 0.58, size: 0.6),
          Sprite('🚀', 0.72, 0.5, size: 0.4, motion: SpriteMotion.bob),
        ]),
      ),
      BookPage(
        '3, 2, 1... Blast off! Cosmo zooms up into the stars.',
        '3, 2, 1... ¡Despegue! Cosmo sube volando hacia las estrellas.',
        Scene(SceneBg.space, [
          Sprite('🚀', 0.5, 0.5, size: 0.45, motion: SpriteMotion.drift),
          Sprite('⭐', 0.15, 0.25, size: 0.12, motion: SpriteMotion.pulse),
          Sprite('✨', 0.85, 0.3, size: 0.14, motion: SpriteMotion.pulse),
          Sprite('🌍', 0.2, 0.8, size: 0.2, motion: SpriteMotion.spin),
        ]),
      ),
      BookPage(
        "First, Cosmo visits Alphabet Planet. Lexi the Fox says, 'A, B, C!'",
        "Primero, Cosmo visita el Planeta Alfabeto. Lexi la Zorrita dice: '¡A, B, C!'",
        Scene(SceneBg.sunset, [
          Sprite.char(CharacterId.lexi, 0.35, 0.58, size: 0.58),
          Sprite('🔤', 0.72, 0.4, size: 0.24, motion: SpriteMotion.bob),
        ]),
      ),
      BookPage(
        "Next is Number Planet. Pip the Penguin counts, '1, 2, 3!'",
        "Luego está el Planeta de los Números. Pip el Pingüino cuenta: '¡1, 2, 3!'",
        Scene(SceneBg.snow, [
          Sprite.char(CharacterId.pip, 0.35, 0.58, size: 0.58),
          Sprite('🔢', 0.72, 0.4, size: 0.24, motion: SpriteMotion.bob),
        ]),
      ),
      BookPage(
        'On Puzzle Planet, Dash the Dino builds a tall tower.',
        'En el Planeta de los Rompecabezas, Dash el Dino construye una torre alta.',
        Scene(SceneBg.forest, [
          Sprite.char(CharacterId.dash, 0.33, 0.58, size: 0.58),
          Sprite('🧱', 0.7, 0.78, size: 0.16, motion: SpriteMotion.none),
          Sprite('🧱', 0.7, 0.62, size: 0.16, motion: SpriteMotion.none),
          Sprite('🧩', 0.7, 0.44, size: 0.16, motion: SpriteMotion.sway),
        ]),
      ),
      BookPage(
        'Coco the Bunny paints a rainbow on Art Planet.',
        'Coco la Conejita pinta un arcoíris en el Planeta del Arte.',
        Scene(SceneBg.meadow, [
          Sprite('🌈', 0.62, 0.32, size: 0.4, motion: SpriteMotion.none),
          Sprite.char(CharacterId.coco, 0.3, 0.6, size: 0.56),
          Sprite('🎨', 0.78, 0.72, size: 0.18, motion: SpriteMotion.sway),
        ]),
      ),
      BookPage(
        'Last, Luna the Owl reads a story on Story Moon. Goodnight, friends!',
        'Por último, Luna la Lechuza lee un cuento en la Luna de los Cuentos. ¡Buenas noches, amigos!',
        Scene(SceneBg.night, [
          Sprite.char(CharacterId.luna, 0.35, 0.58, size: 0.58),
          Sprite('📚', 0.7, 0.72, size: 0.2, motion: SpriteMotion.none),
          Sprite('🌙', 0.8, 0.22, size: 0.2, motion: SpriteMotion.pulse),
        ]),
      ),
    ],
  ),
  Book(
    id: 'little_seed',
    title: 'The Little Seed',
    titleEs: 'La semillita',
    color: Color(0xFF34C77B),
    kind: BookKind.nonfiction,
    maxGrade: Grade.grade1,
    cover: Scene(SceneBg.meadow, [
      Sprite('🌻', 0.5, 0.45, size: 0.55, motion: SpriteMotion.sway),
      Sprite('🐝', 0.75, 0.25, size: 0.14, motion: SpriteMotion.drift),
    ]),
    pages: [
      BookPage(
        'A little seed sleeps in the soil.',
        'Una semillita duerme en la tierra.',
        Scene(SceneBg.meadow, [Sprite('🌰', 0.5, 0.85, size: 0.14, motion: SpriteMotion.pulse), Sprite('☁️', 0.25, 0.22, size: 0.18, motion: SpriteMotion.drift)]),
      ),
      BookPage(
        'Rain falls. Drip, drop! The seed drinks the water.',
        'Cae la lluvia. ¡Plic, plac! La semilla bebe el agua.',
        Scene(SceneBg.rain, [
          Sprite('🌧️', 0.5, 0.2, size: 0.3, motion: SpriteMotion.drift),
          Sprite('💧', 0.38, 0.5, size: 0.1, motion: SpriteMotion.bob),
          Sprite('💧', 0.6, 0.55, size: 0.1, motion: SpriteMotion.bob),
          Sprite('🌰', 0.5, 0.85, size: 0.14, motion: SpriteMotion.none),
        ]),
      ),
      BookPage(
        'The sun shines. The seed feels warm and cozy.',
        'Brilla el sol. La semilla se siente calentita.',
        Scene(SceneBg.sky, [Sprite('☀️', 0.78, 0.22, size: 0.32, motion: SpriteMotion.spin), Sprite('🌰', 0.5, 0.85, size: 0.14, motion: SpriteMotion.pulse)]),
      ),
      BookPage(
        'Pop! A tiny green sprout peeks out.',
        '¡Pop! Un pequeño brote verde se asoma.',
        Scene(SceneBg.meadow, [Sprite('🌱', 0.5, 0.74, size: 0.22, motion: SpriteMotion.sway), Sprite('☀️', 0.8, 0.2, size: 0.22, motion: SpriteMotion.spin)]),
      ),
      BookPage(
        'The sprout grows taller and taller.',
        'El brote crece más y más alto.',
        Scene(SceneBg.meadow, [Sprite('🌿', 0.5, 0.6, size: 0.45, motion: SpriteMotion.sway), Sprite('🐞', 0.62, 0.5, size: 0.1, motion: SpriteMotion.bob)]),
      ),
      BookPage(
        'Now it is a big, bright sunflower! A bee comes to say hello.',
        '¡Ahora es un girasol grande y brillante! Una abeja viene a saludar.',
        Scene(SceneBg.meadow, [Sprite('🌻', 0.45, 0.48, size: 0.62, motion: SpriteMotion.sway), Sprite('🐝', 0.75, 0.3, size: 0.15, motion: SpriteMotion.drift)]),
      ),
    ],
  ),
  Book(
    id: 'pip_hat',
    title: "Where Is Pip's Hat?",
    titleEs: '¿Dónde está el gorro de Pip?',
    color: Color(0xFF3FA9F5),
    kind: BookKind.story,
    maxGrade: Grade.kindergarten,
    cover: Scene(SceneBg.snow, [
      Sprite.char(CharacterId.pip, 0.42, 0.56, size: 0.6),
      Sprite('❓', 0.72, 0.3, size: 0.2, motion: SpriteMotion.pulse),
    ]),
    pages: [
      BookPage(
        "Pip the Penguin can't find his hat.",
        'Pip el Pingüino no encuentra su gorro.',
        Scene(SceneBg.snow, [Sprite.char(CharacterId.pip, 0.4, 0.58, size: 0.6), Sprite('❓', 0.72, 0.3, size: 0.2, motion: SpriteMotion.pulse)]),
      ),
      BookPage(
        "Is it under the bed? No, that's a sock!",
        '¿Está debajo de la cama? ¡No, es un calcetín!',
        Scene(SceneBg.indoor, [Sprite('🛏️', 0.5, 0.62, size: 0.42, motion: SpriteMotion.none), Sprite('🧦', 0.52, 0.86, size: 0.14, motion: SpriteMotion.sway)]),
      ),
      BookPage(
        "Is it in the box? No, that's a ball!",
        '¿Está en la caja? ¡No, es una pelota!',
        Scene(SceneBg.indoor, [Sprite('📦', 0.5, 0.72, size: 0.36, motion: SpriteMotion.none), Sprite('⚽', 0.5, 0.42, size: 0.16, motion: SpriteMotion.bob)]),
      ),
      BookPage(
        "Is it behind the tree? No, that's a bird!",
        '¿Está detrás del árbol? ¡No, es un pájaro!',
        Scene(SceneBg.snow, [Sprite('🌲', 0.45, 0.55, size: 0.62, motion: SpriteMotion.none), Sprite('🐦', 0.66, 0.4, size: 0.16, motion: SpriteMotion.bob, flip: true)]),
      ),
      BookPage(
        'Is it on the snowman? Yes! There it is!',
        '¿Lo tiene el muñeco de nieve? ¡Sí! ¡Ahí está!',
        Scene(SceneBg.snow, [Sprite('⛄', 0.5, 0.58, size: 0.55, motion: SpriteMotion.none), Sprite('🧢', 0.52, 0.28, size: 0.16, motion: SpriteMotion.pulse)]),
      ),
      BookPage(
        'Pip puts on his hat. Now he is warm and happy!',
        'Pip se pone su gorro. ¡Ahora está calentito y feliz!',
        Scene(SceneBg.snow, [Sprite.char(CharacterId.pip, 0.45, 0.58, size: 0.6), Sprite('❤️', 0.75, 0.3, size: 0.14, motion: SpriteMotion.pulse)]),
      ),
    ],
  ),
  Book(
    id: 'counting_stars',
    title: 'Counting Stars',
    titleEs: 'Contando estrellas',
    color: Color(0xFF2A1A6E),
    kind: BookKind.story,
    maxGrade: Grade.kindergarten,
    cover: Scene(SceneBg.night, [
      Sprite('🌕', 0.72, 0.28, size: 0.3, motion: SpriteMotion.pulse),
      Sprite('⭐', 0.25, 0.3, size: 0.14, motion: SpriteMotion.pulse),
      Sprite('⭐', 0.4, 0.6, size: 0.12, motion: SpriteMotion.pulse),
    ]),
    pages: [
      BookPage(
        "It's bedtime. Let's count what we see in the night sky.",
        'Es hora de dormir. Contemos lo que vemos en el cielo de noche.',
        Scene(SceneBg.night, [Sprite('🛏️', 0.5, 0.8, size: 0.3, motion: SpriteMotion.none), Sprite('🌙', 0.8, 0.2, size: 0.2, motion: SpriteMotion.pulse)]),
      ),
      BookPage('One big moon.', 'Una luna grande.', Scene(SceneBg.night, [Sprite('🌕', 0.5, 0.45, size: 0.45, motion: SpriteMotion.pulse)])),
      BookPage(
        'Two sleepy owls.',
        'Dos búhos dormilones.',
        Scene(SceneBg.night, [Sprite('🦉', 0.35, 0.55, size: 0.3), Sprite('🦉', 0.65, 0.55, size: 0.3, flip: true)]),
      ),
      BookPage(
        'Three shooting stars.',
        'Tres estrellas fugaces.',
        Scene(SceneBg.night, [
          Sprite('🌠', 0.25, 0.3, size: 0.2, motion: SpriteMotion.drift),
          Sprite('🌠', 0.55, 0.5, size: 0.2, motion: SpriteMotion.drift),
          Sprite('🌠', 0.8, 0.3, size: 0.2, motion: SpriteMotion.drift),
        ]),
      ),
      BookPage(
        'Four flying bats.',
        'Cuatro murciélagos volando.',
        Scene(SceneBg.night, [
          Sprite('🦇', 0.2, 0.35, size: 0.16, motion: SpriteMotion.drift),
          Sprite('🦇', 0.42, 0.55, size: 0.16, motion: SpriteMotion.drift),
          Sprite('🦇', 0.62, 0.3, size: 0.16, motion: SpriteMotion.drift),
          Sprite('🦇', 0.82, 0.55, size: 0.16, motion: SpriteMotion.drift),
        ]),
      ),
      BookPage(
        'Five twinkly stars. Goodnight, stars!',
        'Cinco estrellitas brillantes. ¡Buenas noches, estrellas!',
        Scene(SceneBg.night, [
          Sprite('⭐', 0.15, 0.4, size: 0.15, motion: SpriteMotion.pulse),
          Sprite('⭐', 0.33, 0.25, size: 0.15, motion: SpriteMotion.pulse),
          Sprite('⭐', 0.5, 0.5, size: 0.15, motion: SpriteMotion.pulse),
          Sprite('⭐', 0.67, 0.25, size: 0.15, motion: SpriteMotion.pulse),
          Sprite('⭐', 0.85, 0.4, size: 0.15, motion: SpriteMotion.pulse),
        ]),
      ),
    ],
  ),
  Book(
    id: 'colors_everywhere',
    title: 'Colors Everywhere',
    titleEs: 'Colores por todas partes',
    color: Color(0xFFFF5FA2),
    kind: BookKind.story,
    maxGrade: Grade.kindergarten,
    cover: Scene(SceneBg.sky, [
      Sprite('🌈', 0.5, 0.42, size: 0.5, motion: SpriteMotion.none),
      Sprite('🎨', 0.8, 0.75, size: 0.18, motion: SpriteMotion.sway),
    ]),
    pages: [
      BookPage('Red is a juicy apple.', 'Rojo es una manzana jugosa.', Scene(SceneBg.sky, [Sprite('🍎', 0.5, 0.55, size: 0.45)])),
      BookPage('Orange is a crunchy carrot.', 'Naranja es una zanahoria crujiente.', Scene(SceneBg.meadow, [Sprite('🥕', 0.5, 0.55, size: 0.45, motion: SpriteMotion.sway)])),
      BookPage('Yellow is the bright sun.', 'Amarillo es el sol brillante.', Scene(SceneBg.sky, [Sprite('🌞', 0.5, 0.45, size: 0.5, motion: SpriteMotion.spin)])),
      BookPage('Green is a hopping frog.', 'Verde es una rana saltarina.', Scene(SceneBg.meadow, [Sprite('🐸', 0.5, 0.6, size: 0.42)])),
      BookPage('Blue is a big whale.', 'Azul es una ballena grande.', Scene(SceneBg.ocean, [Sprite('🐳', 0.5, 0.5, size: 0.48, motion: SpriteMotion.drift)])),
      BookPage('Purple is sweet grapes.', 'Morado son las uvas dulces.', Scene(SceneBg.sky, [Sprite('🍇', 0.5, 0.55, size: 0.45, motion: SpriteMotion.sway)])),
      BookPage('All the colors make a rainbow!', '¡Todos los colores forman un arcoíris!', Scene(SceneBg.sky, [Sprite('🌈', 0.5, 0.45, size: 0.6, motion: SpriteMotion.none), Sprite('☁️', 0.2, 0.7, size: 0.18, motion: SpriteMotion.drift)])),
    ],
  ),
  Book(
    id: 'lexi_shares',
    title: 'Lexi Learns to Share',
    titleEs: 'Lexi aprende a compartir',
    color: Color(0xFFFF7A59),
    kind: BookKind.story,
    maxGrade: Grade.grade1,
    cover: Scene(SceneBg.indoor, [
      Sprite.char(CharacterId.lexi, 0.32, 0.58, size: 0.56),
      Sprite.char(CharacterId.dash, 0.68, 0.58, size: 0.56),
    ]),
    pages: [
      BookPage(
        'Lexi the Fox has a big box of crayons.',
        'Lexi la Zorrita tiene una caja grande de crayones.',
        Scene(SceneBg.indoor, [Sprite.char(CharacterId.lexi, 0.35, 0.58, size: 0.6), Sprite('🖍️', 0.72, 0.62, size: 0.22, motion: SpriteMotion.sway)]),
      ),
      BookPage(
        'Dash wants to draw too, but he has no crayons.',
        'Dash también quiere dibujar, pero no tiene crayones.',
        Scene(SceneBg.indoor, [Sprite.char(CharacterId.dash, 0.4, 0.58, size: 0.6), Sprite('😢', 0.72, 0.3, size: 0.16, motion: SpriteMotion.pulse)]),
      ),
      BookPage(
        'Lexi thinks for a moment. Sharing can be hard.',
        'Lexi piensa un momento. Compartir puede ser difícil.',
        Scene(SceneBg.indoor, [Sprite.char(CharacterId.lexi, 0.4, 0.58, size: 0.6), Sprite('💭', 0.72, 0.28, size: 0.2, motion: SpriteMotion.pulse)]),
      ),
      BookPage(
        "'Here, Dash. Let's draw together!' says Lexi.",
        "'Toma, Dash. ¡Dibujemos juntos!', dice Lexi.",
        Scene(SceneBg.indoor, [
          Sprite.char(CharacterId.lexi, 0.28, 0.58, size: 0.55),
          Sprite('🖍️', 0.5, 0.66, size: 0.16, motion: SpriteMotion.bob),
          Sprite.char(CharacterId.dash, 0.72, 0.58, size: 0.55),
        ]),
      ),
      BookPage(
        'Lexi draws a sun. Dash draws a big dinosaur.',
        'Lexi dibuja un sol. Dash dibuja un dinosaurio grande.',
        Scene(SceneBg.indoor, [Sprite('☀️', 0.32, 0.45, size: 0.3, motion: SpriteMotion.spin), Sprite('🦖', 0.68, 0.5, size: 0.36)]),
      ),
      BookPage(
        'Drawing together is more fun. Sharing makes friends happy!',
        'Dibujar juntos es más divertido. ¡Compartir hace felices a los amigos!',
        Scene(SceneBg.indoor, [
          Sprite.char(CharacterId.lexi, 0.3, 0.6, size: 0.55),
          Sprite('❤️', 0.5, 0.28, size: 0.16, motion: SpriteMotion.pulse),
          Sprite.char(CharacterId.dash, 0.7, 0.6, size: 0.55),
        ]),
      ),
    ],
  ),
  Book(
    id: 'animal_homes',
    title: 'Animal Homes',
    titleEs: 'Casas de animales',
    color: Color(0xFFB9784A),
    kind: BookKind.nonfiction,
    minGrade: Grade.kindergarten,
    cover: Scene(SceneBg.forest, [
      Sprite('🪺', 0.35, 0.5, size: 0.28),
      Sprite('🐌', 0.68, 0.72, size: 0.2, motion: SpriteMotion.drift),
      Sprite('🐦', 0.36, 0.3, size: 0.16),
    ]),
    pages: [
      BookPage('Animals need homes, just like you!', '¡Los animales necesitan casas, igual que tú!', Scene(SceneBg.meadow, [Sprite('🏠', 0.5, 0.55, size: 0.45, motion: SpriteMotion.none), Sprite('🐾', 0.8, 0.8, size: 0.14)])),
      BookPage('Birds build nests from twigs, grass and mud.', 'Los pájaros construyen nidos con ramitas, pasto y lodo.', Scene(SceneBg.forest, [Sprite('🪺', 0.5, 0.6, size: 0.3, motion: SpriteMotion.none), Sprite('🐦', 0.62, 0.35, size: 0.18)])),
      BookPage('Bees live in a hive with thousands of other bees.', 'Las abejas viven en una colmena con miles de otras abejas.', Scene(SceneBg.meadow, [Sprite('🍯', 0.5, 0.58, size: 0.3, motion: SpriteMotion.none), Sprite('🐝', 0.3, 0.35, size: 0.14, motion: SpriteMotion.drift), Sprite('🐝', 0.7, 0.3, size: 0.14, motion: SpriteMotion.drift)])),
      BookPage('Rabbits dig burrows under the ground to stay safe.', 'Los conejos cavan madrigueras bajo la tierra para estar seguros.', Scene(SceneBg.meadow, [Sprite('🐰', 0.45, 0.62, size: 0.3), Sprite('🕳️', 0.7, 0.85, size: 0.16, motion: SpriteMotion.none)])),
      BookPage('Beavers build lodges out of sticks in the water.', 'Los castores construyen sus casas con palos en el agua.', Scene(SceneBg.forest, [Sprite('🦫', 0.4, 0.62, size: 0.3), Sprite('🪵', 0.7, 0.78, size: 0.2, motion: SpriteMotion.none)])),
      BookPage('A snail carries its home on its back wherever it goes!', '¡El caracol lleva su casa en la espalda a dondequiera que va!', Scene(SceneBg.meadow, [Sprite('🐌', 0.5, 0.7, size: 0.35, motion: SpriteMotion.drift)])),
      BookPage('Where do you live? What does your home look like?', '¿Dónde vives tú? ¿Cómo es tu casa?', Scene(SceneBg.sky, [Sprite('🏡', 0.5, 0.55, size: 0.45, motion: SpriteMotion.none), Sprite('😊', 0.8, 0.28, size: 0.14, motion: SpriteMotion.pulse)])),
    ],
  ),
  Book(
    id: 'dinosaur_days',
    title: 'Dinosaur Days',
    titleEs: 'Días de dinosaurios',
    color: Color(0xFF2FA86A),
    kind: BookKind.nonfiction,
    minGrade: Grade.kindergarten,
    premium: true,
    cover: Scene(SceneBg.forest, [
      Sprite('🦕', 0.35, 0.52, size: 0.5),
      Sprite('🦖', 0.72, 0.6, size: 0.36, flip: true),
      Sprite('🌋', 0.8, 0.25, size: 0.2, motion: SpriteMotion.none),
    ]),
    pages: [
      BookPage('Long, long ago, before there were people, dinosaurs lived on Earth.', 'Hace mucho, mucho tiempo, antes de que hubiera personas, los dinosaurios vivían en la Tierra.', Scene(SceneBg.forest, [Sprite('🦕', 0.3, 0.55, size: 0.42), Sprite('🦖', 0.7, 0.6, size: 0.34, flip: true), Sprite('🌋', 0.85, 0.22, size: 0.2, motion: SpriteMotion.none)])),
      BookPage('Some dinosaurs were huge. Brachiosaurus was as tall as a building! It ate leaves from tall trees.', 'Algunos dinosaurios eran enormes. ¡El braquiosaurio era tan alto como un edificio! Comía hojas de los árboles altos.', Scene(SceneBg.forest, [Sprite('🦕', 0.4, 0.5, size: 0.62), Sprite('🌴', 0.75, 0.5, size: 0.5, motion: SpriteMotion.sway)])),
      BookPage('Tyrannosaurus rex had sharp teeth and strong legs. It ate meat.', 'El tiranosaurio rex tenía dientes afilados y patas fuertes. Comía carne.', Scene(SceneBg.sunset, [Sprite('🦖', 0.5, 0.55, size: 0.55)])),
      BookPage('Triceratops had three horns on its face to protect itself.', 'El tricerátops tenía tres cuernos en la cara para protegerse.', Scene(SceneBg.meadow, [Sprite('🦏', 0.5, 0.6, size: 0.45), Sprite('🌿', 0.82, 0.78, size: 0.18, motion: SpriteMotion.sway)])),
      BookPage('Dinosaurs hatched from eggs, just like birds do today.', 'Los dinosaurios salían de huevos, igual que las aves de hoy.', Scene(SceneBg.meadow, [Sprite('🥚', 0.38, 0.7, size: 0.22, motion: SpriteMotion.pulse), Sprite('🐣', 0.62, 0.68, size: 0.24)])),
      BookPage('Scientists learn about dinosaurs by finding fossils, like bones and footprints.', 'Los científicos aprenden sobre los dinosaurios encontrando fósiles, como huesos y huellas.', Scene(SceneBg.beach, [Sprite('🦴', 0.35, 0.7, size: 0.22, motion: SpriteMotion.none), Sprite('🔍', 0.62, 0.5, size: 0.26, motion: SpriteMotion.sway)])),
      BookPage('Dinosaurs are gone now, but their cousins, the birds, are all around us!', '¡Los dinosaurios ya no están, pero sus primos, las aves, están a nuestro alrededor!', Scene(SceneBg.sky, [Sprite('🐦', 0.35, 0.45, size: 0.22, motion: SpriteMotion.drift), Sprite('🦅', 0.7, 0.35, size: 0.26, motion: SpriteMotion.drift)])),
    ],
  ),
  Book(
    id: 'solar_system',
    title: 'Our Solar System',
    titleEs: 'Nuestro sistema solar',
    color: Color(0xFF120B3A),
    kind: BookKind.nonfiction,
    minGrade: Grade.grade1,
    premium: true,
    cover: Scene(SceneBg.space, [
      Sprite('☀️', 0.2, 0.5, size: 0.4, motion: SpriteMotion.spin),
      Sprite('🌍', 0.55, 0.5, size: 0.18, motion: SpriteMotion.spin),
      Sprite('🪐', 0.8, 0.45, size: 0.3),
    ]),
    pages: [
      BookPage('The Sun is a star at the center of our solar system.', 'El Sol es una estrella en el centro de nuestro sistema solar.', Scene(SceneBg.space, [Sprite('☀️', 0.5, 0.5, size: 0.55, motion: SpriteMotion.spin)])),
      BookPage('Eight planets travel around the Sun. Each one follows its own path, called an orbit.', 'Ocho planetas viajan alrededor del Sol. Cada uno sigue su propio camino, llamado órbita.', Scene(SceneBg.space, [Sprite('☀️', 0.25, 0.5, size: 0.35, motion: SpriteMotion.spin), Sprite('🌍', 0.55, 0.35, size: 0.14, motion: SpriteMotion.drift), Sprite('🪐', 0.78, 0.6, size: 0.24, motion: SpriteMotion.drift)])),
      BookPage('Mercury is the closest planet to the Sun. It is small and very hot.', 'Mercurio es el planeta más cercano al Sol. Es pequeño y muy caliente.', Scene(SceneBg.space, [Sprite('☀️', 0.2, 0.5, size: 0.5, motion: SpriteMotion.spin), Sprite('🌑', 0.6, 0.5, size: 0.14, motion: SpriteMotion.bob)])),
      BookPage('Earth is our home. It is the only planet we know that has life.', 'La Tierra es nuestro hogar. Es el único planeta que conocemos que tiene vida.', Scene(SceneBg.space, [Sprite('🌍', 0.5, 0.5, size: 0.5, motion: SpriteMotion.spin), Sprite('🌙', 0.82, 0.28, size: 0.14, motion: SpriteMotion.pulse)])),
      BookPage('Mars is called the Red Planet. It is covered in red dust.', 'Marte se llama el Planeta Rojo. Está cubierto de polvo rojo.', Scene(SceneBg.space, [Sprite('🔴', 0.45, 0.5, size: 0.4, motion: SpriteMotion.bob), Sprite('🛸', 0.8, 0.3, size: 0.16, motion: SpriteMotion.drift)])),
      BookPage('Jupiter is the biggest planet. It has a giant storm that looks like a red spot.', 'Júpiter es el planeta más grande. Tiene una tormenta gigante que parece una mancha roja.', Scene(SceneBg.space, [Sprite('🟠', 0.5, 0.5, size: 0.6, motion: SpriteMotion.bob)])),
      BookPage('Saturn has beautiful rings made of ice and rock.', 'Saturno tiene hermosos anillos hechos de hielo y roca.', Scene(SceneBg.space, [Sprite('🪐', 0.5, 0.5, size: 0.55, motion: SpriteMotion.bob)])),
      BookPage('Uranus and Neptune are far away, cold and blue. Which planet would you like to visit?', 'Urano y Neptuno están muy lejos, y son fríos y azules. ¿Qué planeta te gustaría visitar?', Scene(SceneBg.space, [Sprite('🔵', 0.3, 0.45, size: 0.26, motion: SpriteMotion.bob), Sprite('🧑‍🚀', 0.68, 0.55, size: 0.36, motion: SpriteMotion.drift)])),
    ],
  ),
  Book(
    id: 'ocean_friends',
    title: 'Ocean Friends',
    titleEs: 'Amigos del océano',
    color: Color(0xFF1FA2D6),
    kind: BookKind.nonfiction,
    premium: true,
    cover: Scene(SceneBg.ocean, [
      Sprite('🐳', 0.35, 0.4, size: 0.4, motion: SpriteMotion.drift),
      Sprite('🐠', 0.72, 0.62, size: 0.18, motion: SpriteMotion.drift, flip: true),
      Sprite('🐙', 0.62, 0.3, size: 0.2),
    ]),
    pages: [
      BookPage('The ocean is big and deep. Many animals live there.', 'El océano es grande y profundo. Muchos animales viven allí.', Scene(SceneBg.ocean, [Sprite('🐠', 0.3, 0.4, size: 0.18, motion: SpriteMotion.drift), Sprite('🐟', 0.65, 0.6, size: 0.18, motion: SpriteMotion.drift, flip: true), Sprite('🪸', 0.5, 0.88, size: 0.2, motion: SpriteMotion.sway)])),
      BookPage('The blue whale is the biggest animal on Earth!', '¡La ballena azul es el animal más grande de la Tierra!', Scene(SceneBg.ocean, [Sprite('🐋', 0.5, 0.5, size: 0.55, motion: SpriteMotion.drift)])),
      BookPage('An octopus has eight arms. It can change color to hide.', 'Un pulpo tiene ocho brazos. Puede cambiar de color para esconderse.', Scene(SceneBg.ocean, [Sprite('🐙', 0.5, 0.55, size: 0.48)])),
      BookPage('Sea turtles swim far. They come to the beach to lay their eggs.', 'Las tortugas marinas nadan lejos. Vienen a la playa a poner sus huevos.', Scene(SceneBg.beach, [Sprite('🐢', 0.45, 0.68, size: 0.34, motion: SpriteMotion.drift), Sprite('🥚', 0.75, 0.82, size: 0.12, motion: SpriteMotion.none)])),
      BookPage('Dolphins are smart and playful. They talk with clicks and whistles.', 'Los delfines son listos y juguetones. Hablan con clics y silbidos.', Scene(SceneBg.ocean, [Sprite('🐬', 0.4, 0.45, size: 0.4, motion: SpriteMotion.drift), Sprite('🎵', 0.72, 0.28, size: 0.14, motion: SpriteMotion.pulse)])),
      BookPage('Crabs walk sideways on the sandy sea floor.', 'Los cangrejos caminan de lado por el fondo arenoso del mar.', Scene(SceneBg.ocean, [Sprite('🦀', 0.5, 0.8, size: 0.3, motion: SpriteMotion.sway)])),
      BookPage("Let's keep the ocean clean for all our ocean friends!", '¡Mantengamos el océano limpio para todos nuestros amigos del mar!', Scene(SceneBg.ocean, [Sprite('🐡', 0.3, 0.45, size: 0.22, motion: SpriteMotion.drift), Sprite('💙', 0.52, 0.3, size: 0.16, motion: SpriteMotion.pulse), Sprite('🐠', 0.72, 0.55, size: 0.22, motion: SpriteMotion.drift, flip: true)])),
    ],
  ),
  Book(
    id: 'busy_bee',
    title: 'The Busy Bee',
    titleEs: 'La abeja trabajadora',
    color: Color(0xFFFFB321),
    kind: BookKind.nonfiction,
    minGrade: Grade.kindergarten,
    premium: true,
    cover: Scene(SceneBg.meadow, [
      Sprite('🐝', 0.4, 0.4, size: 0.4, motion: SpriteMotion.drift),
      Sprite('🌼', 0.72, 0.7, size: 0.22, motion: SpriteMotion.sway),
      Sprite('🍯', 0.2, 0.75, size: 0.2, motion: SpriteMotion.none),
    ]),
    pages: [
      BookPage('Buzz, buzz! Meet a honeybee.', '¡Bzz, bzz! Te presento a una abeja.', Scene(SceneBg.meadow, [Sprite('🐝', 0.5, 0.45, size: 0.48, motion: SpriteMotion.drift)])),
      BookPage('Bees live together in a home called a hive.', 'Las abejas viven juntas en una casa llamada colmena.', Scene(SceneBg.forest, [Sprite('🍯', 0.5, 0.55, size: 0.34, motion: SpriteMotion.none), Sprite('🐝', 0.3, 0.3, size: 0.14, motion: SpriteMotion.drift), Sprite('🐝', 0.72, 0.4, size: 0.14, motion: SpriteMotion.drift)])),
      BookPage('Bees fly to flowers to drink sweet nectar.', 'Las abejas vuelan a las flores para beber néctar dulce.', Scene(SceneBg.meadow, [Sprite('🌸', 0.3, 0.7, size: 0.24, motion: SpriteMotion.sway), Sprite('🌼', 0.7, 0.7, size: 0.24, motion: SpriteMotion.sway), Sprite('🐝', 0.5, 0.35, size: 0.2, motion: SpriteMotion.drift)])),
      BookPage('Yellow pollen sticks to their fuzzy bodies. They carry it from flower to flower, which helps new plants grow!', 'El polen amarillo se pega a sus cuerpos peludos. Lo llevan de flor en flor, ¡y eso ayuda a crecer nuevas plantas!', Scene(SceneBg.meadow, [Sprite('🌻', 0.45, 0.55, size: 0.5, motion: SpriteMotion.sway), Sprite('🐝', 0.75, 0.3, size: 0.16, motion: SpriteMotion.drift)])),
      BookPage('Bees turn nectar into honey. Yum!', 'Las abejas convierten el néctar en miel. ¡Qué rico!', Scene(SceneBg.indoor, [Sprite('🍯', 0.5, 0.58, size: 0.42, motion: SpriteMotion.none), Sprite('😋', 0.78, 0.3, size: 0.16, motion: SpriteMotion.pulse)])),
      BookPage('Bees do a waggle dance to tell their friends where the flowers are.', 'Las abejas hacen un baile para decirles a sus amigas dónde están las flores.', Scene(SceneBg.meadow, [Sprite('🐝', 0.35, 0.45, size: 0.26, motion: SpriteMotion.spin), Sprite('🐝', 0.65, 0.5, size: 0.2, motion: SpriteMotion.drift)])),
      BookPage('Thank you, bees, for all your hard work!', '¡Gracias, abejas, por todo su trabajo!', Scene(SceneBg.meadow, [Sprite('🐝', 0.35, 0.4, size: 0.24, motion: SpriteMotion.drift), Sprite('❤️', 0.6, 0.3, size: 0.14, motion: SpriteMotion.pulse), Sprite('🌻', 0.65, 0.62, size: 0.34, motion: SpriteMotion.sway)])),
    ],
  ),
  Book(
    id: 'rainy_day',
    title: 'Rainy Day Fun',
    titleEs: 'Un día de lluvia',
    color: Color(0xFF6C8EBF),
    kind: BookKind.story,
    maxGrade: Grade.grade1,
    premium: true,
    cover: Scene(SceneBg.rain, [
      Sprite.char(CharacterId.coco, 0.4, 0.58, size: 0.58),
      Sprite('☔', 0.72, 0.35, size: 0.24, motion: SpriteMotion.sway),
    ]),
    pages: [
      BookPage('Pitter-patter. It is raining outside.', 'Plic, plic. Está lloviendo afuera.', Scene(SceneBg.rain, [Sprite('🌧️', 0.35, 0.28, size: 0.28, motion: SpriteMotion.drift), Sprite('☔', 0.7, 0.62, size: 0.3, motion: SpriteMotion.sway)])),
      BookPage('Coco puts on her boots and her raincoat.', 'Coco se pone sus botas y su impermeable.', Scene(SceneBg.indoor, [Sprite.char(CharacterId.coco, 0.35, 0.58, size: 0.58), Sprite('👢', 0.68, 0.78, size: 0.16), Sprite('🧥', 0.72, 0.45, size: 0.2, motion: SpriteMotion.sway)])),
      BookPage('Splash! She jumps in a big puddle.', '¡Chof! Salta en un charco grande.', Scene(SceneBg.rain, [Sprite.char(CharacterId.coco, 0.45, 0.52, size: 0.55), Sprite('💦', 0.45, 0.88, size: 0.18, motion: SpriteMotion.pulse)])),
      BookPage('A little worm wiggles by. Hello, worm!', 'Un gusanito pasa moviéndose. ¡Hola, gusanito!', Scene(SceneBg.meadow, [Sprite('🪱', 0.5, 0.8, size: 0.22, motion: SpriteMotion.sway), Sprite('💧', 0.3, 0.4, size: 0.1, motion: SpriteMotion.bob)])),
      BookPage('The rain stops. Look! A rainbow!', 'Deja de llover. ¡Mira! ¡Un arcoíris!', Scene(SceneBg.sky, [Sprite('🌈', 0.5, 0.4, size: 0.55, motion: SpriteMotion.none), Sprite('☀️', 0.85, 0.2, size: 0.18, motion: SpriteMotion.spin)])),
      BookPage('Coco goes home for warm soup. What a fun rainy day!', 'Coco vuelve a casa a tomar una sopa calentita. ¡Qué día de lluvia tan divertido!', Scene(SceneBg.indoor, [Sprite.char(CharacterId.coco, 0.35, 0.58, size: 0.58), Sprite('🍲', 0.7, 0.66, size: 0.22, motion: SpriteMotion.pulse)])),
    ],
  ),
  Book(
    id: 'luna_moon',
    title: 'Luna and the Moon',
    titleEs: 'Luna y la luna',
    color: Color(0xFF8E6CF1),
    kind: BookKind.nonfiction,
    minGrade: Grade.grade1,
    premium: true,
    cover: Scene(SceneBg.night, [
      Sprite.char(CharacterId.luna, 0.36, 0.6, size: 0.58),
      Sprite('🌕', 0.75, 0.3, size: 0.28, motion: SpriteMotion.pulse),
    ]),
    pages: [
      BookPage('Luna the Owl loves to look at the moon every night.', 'A Luna la Lechuza le encanta mirar la luna cada noche.', Scene(SceneBg.night, [Sprite.char(CharacterId.luna, 0.36, 0.6, size: 0.58), Sprite('🌕', 0.75, 0.28, size: 0.26, motion: SpriteMotion.pulse)])),
      BookPage('The moon does not make its own light. It shines because the Sun lights it up.', 'La luna no tiene luz propia. Brilla porque el Sol la ilumina.', Scene(SceneBg.space, [Sprite('☀️', 0.2, 0.5, size: 0.36, motion: SpriteMotion.spin), Sprite('🌕', 0.72, 0.5, size: 0.26, motion: SpriteMotion.bob)])),
      BookPage('Some nights the moon looks like a round ball. That is a full moon.', 'Algunas noches la luna parece una pelota redonda. Es la luna llena.', Scene(SceneBg.night, [Sprite('🌕', 0.5, 0.45, size: 0.46, motion: SpriteMotion.pulse)])),
      BookPage('Other nights we see only a thin slice. That is a crescent moon.', 'Otras noches solo vemos una rebanada delgada. Es la luna creciente.', Scene(SceneBg.night, [Sprite('🌙', 0.5, 0.45, size: 0.46, motion: SpriteMotion.pulse)])),
      BookPage('The changing shapes are called phases. They repeat about every month.', 'Las formas que cambian se llaman fases. Se repiten más o menos cada mes.', Scene(SceneBg.night, [
        Sprite('🌑', 0.14, 0.5, size: 0.14, motion: SpriteMotion.none),
        Sprite('🌒', 0.32, 0.5, size: 0.14, motion: SpriteMotion.none),
        Sprite('🌓', 0.5, 0.5, size: 0.14, motion: SpriteMotion.none),
        Sprite('🌔', 0.68, 0.5, size: 0.14, motion: SpriteMotion.none),
        Sprite('🌕', 0.86, 0.5, size: 0.14, motion: SpriteMotion.none),
      ])),
      BookPage('In 1969, astronauts walked on the moon for the very first time!', '¡En 1969, unos astronautas caminaron en la luna por primera vez!', Scene(SceneBg.space, [Sprite('🌕', 0.3, 0.62, size: 0.46, motion: SpriteMotion.none), Sprite('🧑‍🚀', 0.62, 0.4, size: 0.3, motion: SpriteMotion.drift), Sprite('🚀', 0.85, 0.25, size: 0.18, motion: SpriteMotion.drift)])),
      BookPage('Goodnight, moon. Goodnight, Luna!', 'Buenas noches, luna. ¡Buenas noches, Luna!', Scene(SceneBg.night, [Sprite.char(CharacterId.luna, 0.4, 0.6, size: 0.56), Sprite('🌙', 0.75, 0.25, size: 0.2, motion: SpriteMotion.pulse), Sprite('✨', 0.2, 0.25, size: 0.12, motion: SpriteMotion.pulse)])),
    ],
  ),
];

Book? bookById(String id) {
  for (final b in books) {
    if (b.id == id) return b;
  }
  return null;
}
