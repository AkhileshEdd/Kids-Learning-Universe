/// Words, pictures and passages used by the learning activities.
library;

class PicWord {
  const PicWord(this.word, this.emoji);
  final String word;
  final String emoji;
}

class LetterInfo {
  const LetterInfo(this.letter, this.words, {this.note});
  final String letter;
  final List<PicWord> words;

  /// Optional custom narration (used for X, which is rarely a first sound).
  final String? note;

  String get upper => letter.toUpperCase();
  String get lower => letter.toLowerCase();
  PicWord get main => words.first;
}

const alphabet = <LetterInfo>[
  LetterInfo('a', [PicWord('apple', '🍎'), PicWord('ant', '🐜'), PicWord('astronaut', '🧑‍🚀')]),
  LetterInfo('b', [PicWord('bear', '🐻'), PicWord('ball', '⚽'), PicWord('banana', '🍌'), PicWord('bee', '🐝'), PicWord('bus', '🚌'), PicWord('butterfly', '🦋')]),
  LetterInfo('c', [PicWord('cat', '🐱'), PicWord('car', '🚗'), PicWord('cake', '🎂'), PicWord('cow', '🐄'), PicWord('carrot', '🥕'), PicWord('cookie', '🍪')]),
  LetterInfo('d', [PicWord('dog', '🐶'), PicWord('duck', '🦆'), PicWord('drum', '🥁'), PicWord('door', '🚪'), PicWord('dolphin', '🐬')]),
  LetterInfo('e', [PicWord('egg', '🥚'), PicWord('elephant', '🐘'), PicWord('envelope', '✉️')]),
  LetterInfo('f', [PicWord('fish', '🐟'), PicWord('frog', '🐸'), PicWord('fox', '🦊'), PicWord('flower', '🌸'), PicWord('fire', '🔥')]),
  LetterInfo('g', [PicWord('goat', '🐐'), PicWord('gift', '🎁'), PicWord('guitar', '🎸'), PicWord('grapes', '🍇'), PicWord('ghost', '👻')]),
  LetterInfo('h', [PicWord('hat', '🎩'), PicWord('horse', '🐴'), PicWord('house', '🏠'), PicWord('heart', '❤️'), PicWord('hen', '🐔'), PicWord('hand', '✋')]),
  LetterInfo('i', [PicWord('ice cream', '🍦'), PicWord('island', '🏝️'), PicWord('iguana', '🦎')]),
  LetterInfo('j', [PicWord('juice', '🧃'), PicWord('jellyfish', '🪼'), PicWord('jeans', '👖'), PicWord('jar', '🫙')]),
  LetterInfo('k', [PicWord('kite', '🪁'), PicWord('key', '🔑'), PicWord('koala', '🐨'), PicWord('kangaroo', '🦘'), PicWord('king', '🤴')]),
  LetterInfo('l', [PicWord('lion', '🦁'), PicWord('leaf', '🍃'), PicWord('lemon', '🍋'), PicWord('ladybug', '🐞'), PicWord('lollipop', '🍭')]),
  LetterInfo('m', [PicWord('moon', '🌙'), PicWord('monkey', '🐵'), PicWord('mouse', '🐭'), PicWord('milk', '🥛'), PicWord('mango', '🥭'), PicWord('mushroom', '🍄')]),
  LetterInfo('n', [PicWord('nest', '🪺'), PicWord('nose', '👃'), PicWord('nut', '🥜'), PicWord('noodles', '🍜'), PicWord('nine', '9️⃣')]),
  LetterInfo('o', [PicWord('octopus', '🐙'), PicWord('orange', '🍊'), PicWord('owl', '🦉'), PicWord('ox', '🐂')]),
  LetterInfo('p', [PicWord('pig', '🐷'), PicWord('pizza', '🍕'), PicWord('panda', '🐼'), PicWord('penguin', '🐧'), PicWord('pear', '🍐'), PicWord('pencil', '✏️')]),
  LetterInfo('q', [PicWord('queen', '👸'), PicWord('question', '❓')]),
  LetterInfo('r', [PicWord('rabbit', '🐰'), PicWord('rainbow', '🌈'), PicWord('rocket', '🚀'), PicWord('robot', '🤖'), PicWord('ring', '💍'), PicWord('rose', '🌹')]),
  LetterInfo('s', [PicWord('sun', '☀️'), PicWord('snake', '🐍'), PicWord('star', '⭐'), PicWord('sock', '🧦'), PicWord('snail', '🐌'), PicWord('strawberry', '🍓')]),
  LetterInfo('t', [PicWord('tiger', '🐯'), PicWord('tree', '🌳'), PicWord('train', '🚂'), PicWord('turtle', '🐢'), PicWord('tomato', '🍅'), PicWord('teddy', '🧸')]),
  LetterInfo('u', [PicWord('umbrella', '☂️'), PicWord('unicorn', '🦄'), PicWord('up', '⬆️')]),
  LetterInfo('v', [PicWord('van', '🚐'), PicWord('violin', '🎻'), PicWord('volcano', '🌋')]),
  LetterInfo('w', [PicWord('whale', '🐳'), PicWord('watermelon', '🍉'), PicWord('worm', '🪱'), PicWord('watch', '⌚'), PicWord('wolf', '🐺')]),
  LetterInfo('x', [PicWord('box', '📦'), PicWord('fox', '🦊')], note: 'X. You can hear X at the end of box and fox.'),
  LetterInfo('y', [PicWord('yo-yo', '🪀'), PicWord('yarn', '🧶'), PicWord('yak', '🐃')]),
  LetterInfo('z', [PicWord('zebra', '🦓'), PicWord('zero', '0️⃣')]),
];

LetterInfo letterInfo(String letter) => alphabet.firstWhere((l) => l.letter == letter.toLowerCase());

/// Short-vowel words for early phonics (3 letters).
const cvcWords = <PicWord>[
  PicWord('cat', '🐱'), PicWord('dog', '🐶'), PicWord('pig', '🐷'), PicWord('sun', '☀️'),
  PicWord('hat', '🎩'), PicWord('bus', '🚌'), PicWord('bed', '🛏️'), PicWord('fox', '🦊'),
  PicWord('box', '📦'), PicWord('bug', '🐛'), PicWord('hen', '🐔'), PicWord('map', '🗺️'),
  PicWord('pen', '🖊️'), PicWord('web', '🕸️'), PicWord('van', '🚐'), PicWord('bat', '🦇'),
  PicWord('rat', '🐀'), PicWord('ant', '🐜'), PicWord('egg', '🥚'), PicWord('cup', '🥤'),
  PicWord('log', '🪵'), PicWord('leg', '🦵'), PicWord('six', '6️⃣'), PicWord('ten', '🔟'),
  PicWord('nut', '🥜'), PicWord('pan', '🍳'), PicWord('cap', '🧢'), PicWord('bag', '👜'),
  PicWord('pin', '📌'), PicWord('tub', '🛁'), PicWord('mug', '☕'), PicWord('jet', '✈️'),
  PicWord('net', '🥅'), PicWord('fan', '🪭'),
];

/// Four-letter words with blends and long vowels.
const shortWords = <PicWord>[
  PicWord('frog', '🐸'), PicWord('fish', '🐟'), PicWord('duck', '🦆'), PicWord('crab', '🦀'),
  PicWord('star', '⭐'), PicWord('drum', '🥁'), PicWord('milk', '🥛'), PicWord('ship', '🚢'),
  PicWord('bell', '🔔'), PicWord('sock', '🧦'), PicWord('hand', '✋'), PicWord('nest', '🪺'),
  PicWord('flag', '🚩'), PicWord('tent', '⛺'), PicWord('gift', '🎁'), PicWord('king', '🤴'),
  PicWord('ring', '💍'), PicWord('moon', '🌙'), PicWord('tree', '🌳'), PicWord('book', '📖'),
  PicWord('cake', '🎂'), PicWord('kite', '🪁'), PicWord('bear', '🐻'), PicWord('lion', '🦁'),
  PicWord('boat', '⛵'), PicWord('corn', '🌽'), PicWord('bird', '🐦'), PicWord('fork', '🍴'),
  PicWord('shoe', '👟'), PicWord('coat', '🧥'), PicWord('goat', '🐐'), PicWord('rose', '🌹'),
  PicWord('nose', '👃'), PicWord('bone', '🦴'), PicWord('leaf', '🍃'), PicWord('worm', '🪱'),
];

/// Longer words for confident readers.
const longWords = <PicWord>[
  PicWord('snake', '🐍'), PicWord('snail', '🐌'), PicWord('whale', '🐳'), PicWord('shell', '🐚'),
  PicWord('plant', '🌱'), PicWord('horse', '🐴'), PicWord('sheep', '🐑'), PicWord('clock', '🕐'),
  PicWord('train', '🚂'), PicWord('truck', '🚚'), PicWord('apple', '🍎'), PicWord('grapes', '🍇'),
  PicWord('bread', '🍞'), PicWord('cheese', '🧀'), PicWord('pizza', '🍕'), PicWord('house', '🏠'),
  PicWord('chair', '🪑'), PicWord('crown', '👑'), PicWord('heart', '❤️'), PicWord('tiger', '🐯'),
  PicWord('zebra', '🦓'), PicWord('mouse', '🐭'), PicWord('robot', '🤖'), PicWord('rocket', '🚀'),
  PicWord('turtle', '🐢'), PicWord('flower', '🌸'), PicWord('carrot', '🥕'), PicWord('banana', '🍌'),
  PicWord('pencil', '✏️'), PicWord('rabbit', '🐰'), PicWord('monkey', '🐵'), PicWord('spider', '🕷️'),
  PicWord('candle', '🕯️'), PicWord('orange', '🍊'), PicWord('panda', '🐼'), PicWord('lemon', '🍋'),
  PicWord('cloud', '☁️'), PicWord('ghost', '👻'), PicWord('brush', '🖌️'), PicWord('queen', '👸'),
];

/// Dolch sight words by level.
const sightWordsPreK = [
  'a', 'and', 'big', 'blue', 'can', 'come', 'down', 'go', 'help', 'here', 'I', 'in', 'is', 'it',
  'jump', 'little', 'look', 'me', 'my', 'not', 'one', 'play', 'red', 'run', 'see', 'the', 'to',
  'two', 'up', 'we', 'you', 'yellow',
];

const sightWordsK = [
  'all', 'am', 'are', 'at', 'ate', 'be', 'black', 'brown', 'but', 'came', 'did', 'do', 'eat',
  'four', 'get', 'good', 'have', 'he', 'into', 'like', 'must', 'new', 'no', 'now', 'on', 'our',
  'out', 'please', 'pretty', 'ran', 'ride', 'saw', 'say', 'she', 'so', 'soon', 'that', 'there',
  'they', 'this', 'too', 'under', 'want', 'was', 'well', 'went', 'what', 'white', 'who', 'will',
  'with', 'yes',
];

const sightWords1 = [
  'after', 'again', 'an', 'any', 'as', 'ask', 'by', 'could', 'every', 'fly', 'from', 'give',
  'going', 'had', 'has', 'her', 'him', 'his', 'how', 'just', 'know', 'let', 'live', 'may', 'of',
  'old', 'once', 'open', 'over', 'put', 'round', 'some', 'stop', 'take', 'thank', 'them', 'then',
  'think', 'walk', 'were', 'when',
];

const sightWords2 = [
  'always', 'around', 'because', 'been', 'before', 'best', 'both', 'buy', 'call', 'cold', 'does',
  "don't", 'fast', 'first', 'five', 'found', 'gave', 'goes', 'green', 'its', 'made', 'many',
  'off', 'or', 'pull', 'read', 'right', 'sing', 'sit', 'sleep', 'tell', 'their', 'these', 'those',
  'upon', 'us', 'use', 'very', 'wash', 'which', 'why', 'wish', 'work', 'would', 'write', 'your',
];

/// Groups of picture words that rhyme with each other.
const rhymeGroups = <List<PicWord>>[
  [PicWord('cat', '🐱'), PicWord('hat', '🎩'), PicWord('bat', '🦇'), PicWord('rat', '🐀')],
  [PicWord('dog', '🐶'), PicWord('frog', '🐸'), PicWord('log', '🪵')],
  [PicWord('bee', '🐝'), PicWord('tree', '🌳'), PicWord('key', '🔑'), PicWord('three', '3️⃣')],
  [PicWord('car', '🚗'), PicWord('star', '⭐'), PicWord('jar', '🫙')],
  [PicWord('boat', '⛵'), PicWord('goat', '🐐'), PicWord('coat', '🧥')],
  [PicWord('house', '🏠'), PicWord('mouse', '🐭')],
  [PicWord('clock', '🕐'), PicWord('sock', '🧦'), PicWord('rock', '🪨')],
  [PicWord('fox', '🦊'), PicWord('box', '📦')],
  [PicWord('fish', '🐟'), PicWord('dish', '🍽️')],
  [PicWord('bug', '🐛'), PicWord('mug', '☕')],
  [PicWord('bed', '🛏️'), PicWord('sled', '🛷')],
  [PicWord('hen', '🐔'), PicWord('ten', '🔟'), PicWord('pen', '🖊️')],
  [PicWord('bell', '🔔'), PicWord('shell', '🐚')],
  [PicWord('bear', '🐻'), PicWord('pear', '🍐'), PicWord('chair', '🪑')],
  [PicWord('moon', '🌙'), PicWord('spoon', '🥄'), PicWord('balloon', '🎈')],
  [PicWord('cake', '🎂'), PicWord('snake', '🐍')],
  [PicWord('king', '🤴'), PicWord('ring', '💍')],
  [PicWord('train', '🚂'), PicWord('rain', '🌧️'), PicWord('plane', '✈️')],
  [PicWord('kite', '🪁'), PicWord('light', '💡')],
  [PicWord('snail', '🐌'), PicWord('whale', '🐳'), PicWord('mail', '📬')],
  [PicWord('pie', '🥧'), PicWord('tie', '👔')],
];

class OppositePair {
  const OppositePair(this.a, this.b);
  final PicWord a;
  final PicWord b;
}

const opposites = <OppositePair>[
  OppositePair(PicWord('hot', '🔥'), PicWord('cold', '🧊')),
  OppositePair(PicWord('big', '🐘'), PicWord('small', '🐭')),
  OppositePair(PicWord('happy', '😀'), PicWord('sad', '😢')),
  OppositePair(PicWord('day', '🌞'), PicWord('night', '🌙')),
  OppositePair(PicWord('up', '⬆️'), PicWord('down', '⬇️')),
  OppositePair(PicWord('fast', '🐆'), PicWord('slow', '🐢')),
  OppositePair(PicWord('awake', '😃'), PicWord('asleep', '😴')),
  OppositePair(PicWord('loud', '📢'), PicWord('quiet', '🤫')),
  OppositePair(PicWord('old', '👴'), PicWord('young', '👶')),
  OppositePair(PicWord('wet', '💦'), PicWord('dry', '🌵')),
  OppositePair(PicWord('left', '⬅️'), PicWord('right', '➡️')),
  OppositePair(PicWord('open', '🔓'), PicWord('closed', '🔒')),
  OppositePair(PicWord('stop', '🛑'), PicWord('go', '🟢')),
  OppositePair(PicWord('sweet', '🍭'), PicWord('sour', '🍋')),
];

/// Named groups of pictures, for sorting and odd-one-out games.
class Category {
  const Category(this.name, this.items);
  final String name;
  final List<PicWord> items;
}

const categories = <Category>[
  Category('fruits', [
    PicWord('apple', '🍎'), PicWord('banana', '🍌'), PicWord('grapes', '🍇'), PicWord('strawberry', '🍓'),
    PicWord('orange', '🍊'), PicWord('watermelon', '🍉'), PicWord('pear', '🍐'), PicWord('cherries', '🍒'),
    PicWord('mango', '🥭'), PicWord('pineapple', '🍍'),
  ]),
  Category('vegetables', [
    PicWord('carrot', '🥕'), PicWord('broccoli', '🥦'), PicWord('corn', '🌽'), PicWord('potato', '🥔'),
    PicWord('onion', '🧅'), PicWord('cucumber', '🥒'), PicWord('eggplant', '🍆'), PicWord('pepper', '🫑'),
  ]),
  Category('animals', [
    PicWord('dog', '🐶'), PicWord('cat', '🐱'), PicWord('mouse', '🐭'), PicWord('rabbit', '🐰'),
    PicWord('fox', '🦊'), PicWord('bear', '🐻'), PicWord('panda', '🐼'), PicWord('tiger', '🐯'),
    PicWord('lion', '🦁'), PicWord('cow', '🐮'), PicWord('pig', '🐷'), PicWord('monkey', '🐵'),
  ]),
  Category('vehicles', [
    PicWord('car', '🚗'), PicWord('taxi', '🚕'), PicWord('bus', '🚌'), PicWord('police car', '🚓'),
    PicWord('ambulance', '🚑'), PicWord('fire truck', '🚒'), PicWord('tractor', '🚜'), PicWord('bike', '🚲'),
    PicWord('plane', '✈️'), PicWord('train', '🚂'), PicWord('helicopter', '🚁'), PicWord('boat', '⛵'),
  ]),
  Category('clothes', [
    PicWord('shirt', '👕'), PicWord('jeans', '👖'), PicWord('socks', '🧦'), PicWord('cap', '🧢'),
    PicWord('dress', '👗'), PicWord('coat', '🧥'), PicWord('shoe', '👟'), PicWord('gloves', '🧤'),
    PicWord('scarf', '🧣'),
  ]),
  Category('sea animals', [
    PicWord('whale', '🐳'), PicWord('dolphin', '🐬'), PicWord('octopus', '🐙'), PicWord('crab', '🦀'),
    PicWord('fish', '🐠'), PicWord('shark', '🦈'), PicWord('squid', '🦑'), PicWord('seal', '🦭'),
  ]),
  Category('birds', [
    PicWord('bird', '🐦'), PicWord('duck', '🦆'), PicWord('owl', '🦉'), PicWord('penguin', '🐧'),
    PicWord('parrot', '🦜'), PicWord('eagle', '🦅'), PicWord('chicken', '🐔'), PicWord('peacock', '🦚'),
  ]),
  Category('music makers', [
    PicWord('guitar', '🎸'), PicWord('drum', '🥁'), PicWord('trumpet', '🎺'), PicWord('violin', '🎻'),
    PicWord('piano', '🎹'), PicWord('saxophone', '🎷'),
  ]),
  Category('weather', [
    PicWord('sun', '☀️'), PicWord('rain', '🌧️'), PicWord('snow', '❄️'), PicWord('rainbow', '🌈'),
    PicWord('cloud', '☁️'), PicWord('lightning', '⚡'), PicWord('wind', '🌬️'),
  ]),
  Category('bugs', [
    PicWord('bee', '🐝'), PicWord('ladybug', '🐞'), PicWord('butterfly', '🦋'), PicWord('caterpillar', '🐛'),
    PicWord('ant', '🐜'), PicWord('beetle', '🪲'), PicWord('cricket', '🦗'),
  ]),
  Category('school things', [
    PicWord('pencil', '✏️'), PicWord('books', '📚'), PicWord('backpack', '🎒'), PicWord('crayon', '🖍️'),
    PicWord('ruler', '📏'), PicWord('scissors', '✂️'),
  ]),
  Category('sweet treats', [
    PicWord('lollipop', '🍭'), PicWord('candy', '🍬'), PicWord('chocolate', '🍫'), PicWord('donut', '🍩'),
    PicWord('cookie', '🍪'), PicWord('cupcake', '🧁'), PicWord('ice cream', '🍦'),
  ]),
];

/// "Which one ...?" thinking questions.
class ThinkQuestion {
  const ThinkQuestion(this.question, this.yes, this.no);
  final String question;
  final List<PicWord> yes;
  final List<PicWord> no;
}

const thinkQuestions = <ThinkQuestion>[
  ThinkQuestion('Which one can fly?', [
    PicWord('bird', '🐦'), PicWord('plane', '✈️'), PicWord('butterfly', '🦋'), PicWord('bee', '🐝'),
    PicWord('helicopter', '🚁'), PicWord('owl', '🦉'), PicWord('balloon', '🎈'),
  ], [
    PicWord('dog', '🐶'), PicWord('turtle', '🐢'), PicWord('car', '🚗'), PicWord('fish', '🐟'),
    PicWord('elephant', '🐘'), PicWord('snail', '🐌'), PicWord('tree', '🌳'),
  ]),
  ThinkQuestion('Which one lives in water?', [
    PicWord('fish', '🐟'), PicWord('whale', '🐳'), PicWord('octopus', '🐙'), PicWord('crab', '🦀'),
    PicWord('dolphin', '🐬'), PicWord('shark', '🦈'),
  ], [
    PicWord('dog', '🐶'), PicWord('cat', '🐱'), PicWord('lion', '🦁'), PicWord('chicken', '🐔'),
    PicWord('horse', '🐴'), PicWord('monkey', '🐒'),
  ]),
  ThinkQuestion('Which one can we wear?', [
    PicWord('shirt', '👕'), PicWord('jeans', '👖'), PicWord('socks', '🧦'), PicWord('cap', '🧢'),
    PicWord('dress', '👗'), PicWord('coat', '🧥'), PicWord('shoe', '👟'),
  ], [
    PicWord('apple', '🍎'), PicWord('car', '🚗'), PicWord('ball', '⚽'), PicWord('dog', '🐶'),
    PicWord('chair', '🪑'), PicWord('book', '📖'),
  ]),
  ThinkQuestion('Which one can we eat?', [
    PicWord('apple', '🍎'), PicWord('banana', '🍌'), PicWord('carrot', '🥕'), PicWord('pizza', '🍕'),
    PicWord('bread', '🍞'), PicWord('cheese', '🧀'), PicWord('grapes', '🍇'),
  ], [
    PicWord('socks', '🧦'), PicWord('car', '🚗'), PicWord('book', '📖'), PicWord('ball', '⚽'),
    PicWord('pencil', '✏️'), PicWord('chair', '🪑'),
  ]),
  ThinkQuestion('Which one is cold?', [
    PicWord('ice', '🧊'), PicWord('snowman', '⛄'), PicWord('snowflake', '❄️'), PicWord('ice cream', '🍦'),
  ], [
    PicWord('fire', '🔥'), PicWord('sun', '☀️'), PicWord('hot drink', '☕'), PicWord('volcano', '🌋'),
  ]),
  ThinkQuestion('Which one is hot?', [
    PicWord('fire', '🔥'), PicWord('sun', '☀️'), PicWord('hot drink', '☕'), PicWord('volcano', '🌋'),
  ], [
    PicWord('ice', '🧊'), PicWord('snowman', '⛄'), PicWord('snowflake', '❄️'), PicWord('ice cream', '🍦'),
  ]),
  ThinkQuestion('Which one has wheels?', [
    PicWord('car', '🚗'), PicWord('bike', '🚲'), PicWord('bus', '🚌'), PicWord('tractor', '🚜'),
    PicWord('scooter', '🛴'), PicWord('skateboard', '🛹'),
  ], [
    PicWord('horse', '🐴'), PicWord('boat', '⛵'), PicWord('fish', '🐟'), PicWord('tree', '🌳'),
    PicWord('apple', '🍎'),
  ]),
  ThinkQuestion('Which one makes music?', [
    PicWord('guitar', '🎸'), PicWord('drum', '🥁'), PicWord('trumpet', '🎺'), PicWord('violin', '🎻'),
    PicWord('piano', '🎹'),
  ], [
    PicWord('apple', '🍎'), PicWord('socks', '🧦'), PicWord('chair', '🪑'), PicWord('tree', '🌳'),
    PicWord('spoon', '🥄'),
  ]),
  ThinkQuestion('Which one do we see at night?', [
    PicWord('moon', '🌙'), PicWord('stars', '✨'), PicWord('owl', '🦉'),
  ], [
    PicWord('sun', '☀️'), PicWord('rainbow', '🌈'), PicWord('sunglasses', '🕶️'),
  ]),
  ThinkQuestion('Which one lays eggs?', [
    PicWord('chicken', '🐔'), PicWord('turtle', '🐢'), PicWord('duck', '🦆'), PicWord('snake', '🐍'),
    PicWord('penguin', '🐧'),
  ], [
    PicWord('dog', '🐶'), PicWord('cat', '🐱'), PicWord('cow', '🐄'), PicWord('horse', '🐴'),
    PicWord('monkey', '🐒'),
  ]),
  ThinkQuestion('Which one helps us stay dry in the rain?', [
    PicWord('umbrella', '☂️'),
  ], [
    PicWord('sunglasses', '🕶️'), PicWord('ball', '⚽'), PicWord('ice cream', '🍦'), PicWord('kite', '🪁'),
  ]),
  ThinkQuestion('Which one grows in a garden?', [
    PicWord('flower', '🌻'), PicWord('carrot', '🥕'), PicWord('tomato', '🍅'), PicWord('plant', '🌱'),
  ], [
    PicWord('car', '🚗'), PicWord('robot', '🤖'), PicWord('phone', '📱'), PicWord('shoe', '👟'),
  ]),
];

class Feeling {
  const Feeling(this.name, this.emoji);
  final String name;
  final String emoji;
}

const feelings = <Feeling>[
  Feeling('happy', '😀'),
  Feeling('sad', '😢'),
  Feeling('angry', '😠'),
  Feeling('surprised', '😮'),
  Feeling('sleepy', '😴'),
  Feeling('scared', '😨'),
  Feeling('silly', '🤪'),
  Feeling('loved', '🥰'),
];

class FeelingStory {
  const FeelingStory(this.text, this.feeling, this.emoji);
  final String text;
  final String feeling;
  final String emoji;
}

const feelingStories = <FeelingStory>[
  FeelingStory('Mia gets a new puppy!', 'happy', '🐶'),
  FeelingStory("Leo's ice cream falls on the ground.", 'sad', '🍦'),
  FeelingStory('Surprise! It is a birthday party!', 'surprised', '🎉'),
  FeelingStory('It is very late and Sam yawns.', 'sleepy', '🌙'),
  FeelingStory('There is a big, loud thunder storm.', 'scared', '⛈️'),
  FeelingStory("Someone knocks over Ava's tall block tower on purpose.", 'angry', '🧱'),
  FeelingStory('Grandma gives Zoe a big warm hug.', 'loved', '🤗'),
  FeelingStory('Ben wears a funny hat and makes silly faces.', 'silly', '🎩'),
  FeelingStory('Kai wins the race at school!', 'happy', '🏆'),
  FeelingStory('Nora cannot find her favorite teddy.', 'sad', '🧸'),
];

/// Reading comprehension passages.
class Passage {
  const Passage(this.minGrade, this.emoji, this.text, this.questions);

  /// 1 = 1st grade, 2 = 2nd grade.
  final int minGrade;
  final String emoji;
  final String text;
  final List<PassageQuestion> questions;
}

class PassageQuestion {
  const PassageQuestion(this.question, this.answer, this.wrong);
  final String question;
  final String answer;
  final List<String> wrong;
}

const passages = <Passage>[
  Passage(1, '🪁', 'Sam has a red kite. He runs to the park with it. The wind blows, and the kite flies up high!', [
    PassageQuestion('Where does Sam go?', 'to the park', ['to the beach', 'to the store']),
    PassageQuestion('What color is the kite?', 'red', ['blue', 'green']),
  ]),
  Passage(1, '🌱', 'Mia plants a small seed in a pot. She gives it water every day. Soon a green sprout pops up!', [
    PassageQuestion('What does Mia plant?', 'a seed', ['a rock', 'a toy']),
    PassageQuestion('What does Mia give the seed every day?', 'water', ['milk', 'juice']),
  ]),
  Passage(1, '🐱', 'The cat naps in the warm sun. A butterfly lands on her nose. The cat sneezes, and the butterfly flies away.', [
    PassageQuestion('Where does the cat nap?', 'in the sun', ['in the bath', 'in a box']),
    PassageQuestion("What lands on the cat's nose?", 'a butterfly', ['a bee', 'a bird']),
  ]),
  Passage(1, '🍪', 'Ben and his dad bake cookies. They add chocolate chips. The kitchen smells yummy!', [
    PassageQuestion('Who bakes with Ben?', 'his dad', ['his mom', 'his sister']),
    PassageQuestion('What do they add to the cookies?', 'chocolate chips', ['carrots', 'cheese']),
  ]),
  Passage(1, '🌧️', 'It is raining. Ava puts on her yellow boots. She jumps in every puddle she sees. Splash!', [
    PassageQuestion('What is the weather like?', 'rainy', ['sunny', 'snowy']),
    PassageQuestion("What color are Ava's boots?", 'yellow', ['pink', 'black']),
  ]),
  Passage(1, '🐕', "Leo's dog is named Max. Max loves to fetch sticks. Every morning, Leo throws a stick and Max runs to get it.", [
    PassageQuestion("What is the dog's name?", 'Max', ['Leo', 'Sam']),
    PassageQuestion('What does Max love to fetch?', 'sticks', ['balls', 'shoes']),
  ]),
  Passage(1, '🪺', 'A little bird builds a nest in a tree. She uses twigs and grass. Soon there are three eggs in the nest.', [
    PassageQuestion('Where is the nest?', 'in a tree', ['on a roof', 'in a car']),
    PassageQuestion('How many eggs are in the nest?', 'three', ['two', 'five']),
  ]),
  Passage(1, '🚀', 'Zoe wants to go to the moon. She builds a rocket out of a big box. She paints it silver and adds a star on top.', [
    PassageQuestion('What does Zoe build?', 'a rocket', ['a boat', 'a house']),
    PassageQuestion('What does she use to build it?', 'a big box', ['some rocks', 'blocks of ice']),
  ]),
  Passage(1, '🍎', 'Tom has four red apples. He gives one to his teacher. Now Tom has three apples left.', [
    PassageQuestion('How many apples did Tom have at first?', 'four', ['three', 'one']),
    PassageQuestion('Who does Tom give an apple to?', 'his teacher', ['his dog', 'his mom']),
  ]),
  Passage(1, '🎣', "Grandpa and Lily go fishing at the lake. They sit very quietly. Lily catches a big fish and shouts, 'Hooray!'", [
    PassageQuestion('Where do they go fishing?', 'at the lake', ['at the zoo', 'at the park']),
    PassageQuestion('Who catches a fish?', 'Lily', ['Grandpa', 'Mom']),
  ]),
  Passage(1, '🚲', "Kai has a blue bike. He rides it to his grandma's house. Grandma gives him a cold glass of lemonade.", [
    PassageQuestion("What color is Kai's bike?", 'blue', ['red', 'yellow']),
    PassageQuestion('What does Grandma give Kai?', 'lemonade', ['milk', 'soup']),
  ]),
  Passage(2, '🐝', 'Bees are busy insects. They fly from flower to flower to collect nectar. Bees use the nectar to make honey, which they store in their hive.', [
    PassageQuestion('What do bees collect from flowers?', 'nectar', ['leaves', 'water']),
    PassageQuestion('Where do bees store honey?', 'in their hive', ['in a nest', 'in a cave']),
  ]),
  Passage(2, '🐧', 'Penguins are birds, but they cannot fly. Instead, they are great swimmers. Their wings work like flippers to help them zoom through cold ocean water.', [
    PassageQuestion("What can't penguins do?", 'fly', ['swim', 'walk']),
    PassageQuestion('How do penguins use their wings?', 'like flippers', ['to dig holes', 'to climb trees']),
  ]),
  Passage(2, '☀️', 'The sun is a star. It looks small because it is very far away. The sun gives Earth light and heat, which plants and animals need to live.', [
    PassageQuestion('What is the sun?', 'a star', ['a planet', 'a moon']),
    PassageQuestion('Why does the sun look small?', 'it is far away', ['it is tiny', 'it is behind a cloud']),
  ]),
  Passage(2, '🥪', 'Maya forgot her lunch at home. At school, her friend Raj shared his sandwich with her. Maya said thank you and gave Raj a big smile.', [
    PassageQuestion('What did Maya forget?', 'her lunch', ['her bag', 'her coat']),
    PassageQuestion('How was Raj a good friend?', 'he shared his sandwich', ['he sang a song', 'he gave her a book']),
  ]),
  Passage(2, '🦋', 'A caterpillar eats and eats leaves. Then it makes a cozy case called a chrysalis. After many days, it comes out as a beautiful butterfly!', [
    PassageQuestion('What does a caterpillar eat?', 'leaves', ['rocks', 'bread']),
    PassageQuestion('What does the caterpillar become?', 'a butterfly', ['a bee', 'a bird']),
  ]),
  Passage(2, '🐸', 'Frogs start life as tiny eggs in the water. The eggs hatch into tadpoles, which have tails and swim like fish. Slowly, the tadpoles grow legs and become frogs.', [
    PassageQuestion('What hatches from frog eggs?', 'tadpoles', ['chicks', 'snakes']),
    PassageQuestion('What do tadpoles grow as they change?', 'legs', ['feathers', 'wings']),
  ]),
  Passage(2, '🐻', 'In winter, some animals sleep for a long time. This is called hibernation. Bears eat lots of food in the fall so they have energy to sleep all winter.', [
    PassageQuestion('What is the long winter sleep called?', 'hibernation', ['migration', 'vacation']),
    PassageQuestion('When do bears eat lots of food?', 'in the fall', ['in the winter', 'at night']),
  ]),
  Passage(2, '🌋', 'A volcano is a mountain with an opening at the top. Deep inside the Earth, rock is so hot that it melts. When a volcano erupts, the hot melted rock, called lava, flows out.', [
    PassageQuestion('What is the hot melted rock called?', 'lava', ['sand', 'snow']),
    PassageQuestion('Where is the opening of a volcano?', 'at the top', ['at the bottom', 'in a tree']),
  ]),
];
