# Kids Learning Universe 🚀

A playful learning app for children from **preschool to 2nd grade** (ages 2–8).
Kids fly around a universe of planets with **Cosmo the Bear** and friends,
playing reading, phonics, math, thinking and art games, and reading
illustrated storybooks aloud in English or Spanish.

Built with **Flutter** for Android (landscape). All content is built into the
app: it works **offline**, has **no ads**, and stores data only on the device.

![Play Store icon](store/play_store_icon_512.png)

## Features

| Area | What's inside |
| --- | --- |
| **Universe home** | Animated night sky with 5 planets (Reading, Math, Thinking, Art, Story Moon), each hosted by a character. |
| **Today's Adventure** | A daily learning path: one reading game, one math game, one thinking game and one book, picked for the child's grade. Finishing all gives a trophy and bonus stars. |
| **Reading & phonics** (Lexi the Fox) | ABC Explorer, Find the Letter, Letter Pop (arcade), Trace ABC / abc, Big & Little letters, First Sounds, Sight Word Stars (Dolch lists by grade), Word Builder, Read & Match, Rhyme Time, Missing Letter, Opposites, Story Questions (reading comprehension). |
| **Math** (Pip the Penguin) | Count It (tap-to-count), Find the Number, Number Pop, Trace 123, More or Less (groups → numbers → `<` `>` `=`), Adding Apples, Take Away, Addition Blast and Subtraction Splash (up to 2-digit with regrouping), What's Missing (sequences and skip counting), Tens & Ones (base-ten blocks), Clock Time, Story Problems. |
| **Thinking** (Dash the Dino) | Color Fun, Shape Safari (2D, sides, 3D solids), Pattern Train, Memory Match (pictures → letters → number words → math facts), Odd One Out, Big & Small, Feelings (social-emotional learning), Think & Sort. |
| **Art** (Coco the Bunny) | Magic Drawing (rainbow brush, stamps, eraser, undo), Coloring Book (tap-to-fill pictures), Trace Shapes. |
| **Story Moon** (Luna the Owl) | 13 original illustrated books (stories and non-fiction: dinosaurs, the solar system, oceans, bees, the moon…). "Read to me" narration with word highlighting, tap any word to hear it, and an English/Español switch on every book. |
| **Adapts to the child** | Four levels (Preschool, Kindergarten, 1st, 2nd grade) plus easy/medium/hard inside each grade. Difficulty goes up after a great round and down after a hard one. Questions are generated, so every session is different. |
| **Rewards** | Stars for every correct first try, a new sticker after every game or book, level-up celebrations and a sticker book with 7 themed packs. |
| **Grown-ups area** (behind a parental gate) | Progress report (time today / this week, skills with accuracy and level, recent activity), up to 5 child profiles, settings (sound effects, music, narrator voice, voice speed and accent, Spanish-by-default for books), daily screen-time limit with a friendly "time for a break" screen, Premium. |
| **Made for pre-readers** | Every instruction is spoken (Android text-to-speech). Big buttons, gentle "try again" feedback, no failure states. |

### Free vs. Premium

Free includes the core games in every subject and grade, 7 books, 3 sticker
packs, 4 coloring pages and 1 child profile. Premium unlocks 9 extra games,
6 extra books, 4 extra sticker packs, all coloring pages and up to 5 profiles.
Premium items show a gold lock; tapping one asks the child to get a grown-up.

## Running the app

Requirements: Flutter 3.47+ with the Android SDK.

```bash
flutter pub get
flutter run            # on a connected Android phone/tablet or emulator
flutter test           # unit + widget tests
flutter analyze
```

### Getting an APK without a local setup

Every push runs the **Android build** GitHub Actions workflow
(`.github/workflows/android.yml`): it analyzes, tests, and builds a release
APK and an App Bundle. Download them from the workflow run's **Artifacts**
section (`kids-learning-universe-apk` / `kids-learning-universe-aab`) and
install the APK on a phone.

### Release signing (before uploading to Google Play)

Release builds are signed with the debug key until you add your own upload key:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` (it is git-ignored):

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

The application ID is `com.kidslearninguniverse.app` (it can't change after
the first upload to Google Play, so change it now if you want a different one:
`android/app/build.gradle.kts` and the `MainActivity.kt` package).

## In-app purchases (next step)

The app is already structured for Premium:

- `lib/premium/premium_service.dart` holds the entitlement for the whole app
  and exposes `products`, `purchase()`, `restore()` and `isPremium`.
- All store access goes through the `PurchaseBackend` interface. Today the app
  uses `TestPurchaseBackend`, which simulates purchases (the paywall shows a
  "Test mode" banner, and Grown-ups → Premium has a switch to turn it off again).
- Product IDs to create in the Google Play Console:
  `klu_premium_monthly`, `klu_premium_yearly` (subscriptions) and
  `klu_premium_lifetime` (one-time product).

To go live, add the `in_app_purchase` plugin, implement a
`GooglePlayPurchaseBackend` against the same interface, and pass it to
`PremiumService` in `lib/main.dart`. The paywall, locks and parental gate
don't need to change.

## Project structure

```
lib/
  main.dart, app.dart          app start-up, providers, lifecycle, screen-time clock
  core/                        theme, text-to-speech, sounds, routes, helpers
  models/                      child profile, progress, settings, grades
  state/app_state.dart         profiles, progress, rewards, daily adventure, limits (saved on device)
  premium/                     premium entitlement + purchase backends
  content/
    activities.dart            the activity catalog (subject, grades, free/premium)
    generators/                question generators for reading, math and thinking
    word_bank.dart             letters, phonics words, sight words, rhymes, passages…
    books.dart                 storybooks (English + Spanish) and their scenes
    tracing_glyphs.dart        stroke-order paths for A–Z, a–z, 0–9 and shapes
    coloring_pages.dart        vector coloring pages
    stickers.dart, characters.dart, subjects.dart
  screens/                     home, planets, quiz player, games, library, reader,
                               sticker book, rewards, grown-ups area, paywall
  widgets/                     painted characters, planets, space sky, buttons, confetti…
  dev/preview.dart             opt-in screen preview (see below)
assets/                        fonts (Fredoka, Andika, Noto Color Emoji), sound effects, music
tool/                          scripts that generate the sounds and launcher icons
test/                          generator, state and widget tests
```

### Adding content

- **A new quiz game**: write a `QuizGenerator` in `lib/content/generators/`
  and add an `ActivityDef` to `lib/content/activities.dart`. The tests
  automatically check it for every grade and level.
- **A new book**: add a `Book` to `lib/content/books.dart` (English and
  Spanish text per page, a background and emoji or character sprites).

### Artwork and audio

Characters, planets, backgrounds and book illustrations are drawn in code, so
there are no image licenses to track. Sound effects and background music are
synthesized by `tool/generate_sounds.py`; launcher icons are rendered by
`tool/icon/`. Fonts are SIL Open Font License (see `assets/fonts/`).

### Screen previews

Build with `--dart-define=PREVIEW=true` to open any screen straight from the
URL on the web build, for design reviews, e.g.
`?screen=activity:count_objects&grade=kindergarten`, `?screen=book:cosmo_trip`,
`?screen=parents`. Store builds never include this flag.
