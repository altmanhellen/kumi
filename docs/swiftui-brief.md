# Kumi: English Collocations — задание на экраны SwiftUI

Это задание для ИИ, который будет рисовать экраны приложения Kumi: English Collocations (под иконкой — просто Kumi, внутреннее имя проекта WordPartners). Нужен только интерфейс. Логику (интервальные повторения, проверку ответов, хранение, озвучку) уже написали, она остаётся как есть. Твои экраны подключат к ней без переделки, если ты соблюдёшь контракт ниже.

## Что за приложение

iPhone-приложение для изучения английских коллокаций (устойчивых сочетаний вроде *make a decision*), уровни A2–C1, всего 326 выражений. Интерфейс на русском, выражения и примеры на английском. Каждый день пользователь видит план: сначала повторения, у которых подошёл срок, потом новые выражения. Занятие идёт по шагам: знакомство с выражением → выбор правильного из трёх → вписывание целиком по памяти. После занятия показывается итог.

## Техника

- iOS 18 и новее, только iPhone, только портретная ориентация.
- Swift 5 (language mode 5), SwiftUI. UIKit только если без него никак.
- Никаких сторонних библиотек и пакетов.
- Шрифты, которые уже лежат в приложении: Rubik (Bold, ExtraBold), Nunito (Regular, SemiBold, Bold, ExtraBold, Italic). Другие шрифты не добавляй. Можно системный шрифт (SF Pro). Иконки только SF Symbols.
- Картинок и ассетов в приложении нет, кроме иконки. Украшения рисуй кодом: `Shape`, `Canvas`, градиенты.

## Правила для экранов

1. **Экраны только отображают данные.** Каждый экран — `struct …: View`. Он получает готовые данные (структуры ниже) и функции-обратные вызовы (closures). Никаких своих моделей данных, `@Observable`/`ObservableObject`, хранения (`UserDefaults`, файлы, SwiftData), сети и таймеров.
2. Можно `@State` для чисто визуального: что выбрано в списке до нажатия «Проверить», текст в поле ввода, открыт ли лист. Всё, что должно сохраниться, отдавай наружу через closure.
3. **Светлая и тёмная темы обязательно.** Цвета задай в одном месте, например `enum Palette` с цветами для обеих тем. Не используй `Color.white`/`Color.black` для текста напрямую.
4. **Dynamic Type.** Размеры шрифтов через `.custom(name, size:, relativeTo:)` или системные стили, чтобы при увеличенном тексте ничего не обрезалось. Длинные русские слова должны переноситься.
5. **Доступность.** Кнопки не меньше 44×44 pt. У кнопок-иконок `accessibilityLabel` на русском. Не передавай смысл одним цветом: у верного/неверного ответа нужна ещё иконка или текст.
6. Учитывай Safe Area, маленькие экраны (iPhone SE, 375 pt ширины) и большие (Pro Max).
7. Уважай `accessibilityReduceMotion`: без него анимации короткие, с ним их нет.
8. Нижняя панель вкладок своя (не системная `TabBar`): «Сегодня», «Каталог», «Прогресс», «Настройки». Учебное занятие открывается на весь экран без панели вкладок.
9. Озвучка — только кнопка. Сам экран звук не включает, он вызывает closure `onListen`.
10. Клавиатуру в задании на вписывание не открывать автоматически, только по нажатию на поле.
11. **У каждого экрана `#Preview`** с примерными данными, в светлой и тёмной теме. Примерные данные вынеси в `enum PreviewData` (одним файлом).

## Общие типы данных

Эти типы уже есть в приложении. Скопируй их в свой проект как есть, чтобы экраны компилировались. Не меняй их. Если какого-то поля не хватает, напиши об этом в ответе, не добавляй сам.

```swift
enum Level: String, CaseIterable, Identifiable, Comparable {
    case a2 = "A2", b1 = "B1", b2 = "B2", c1 = "C1"
    var id: String { rawValue }
    var name: String { ... }   // "Elementary", "Intermediate", "Upper-intermediate", "Advanced"
    var blurb: String { ... }  // короткое описание по-русски
}

/// Состояние выражения в изучении.
enum LearningState: String, CaseIterable {
    case new        // ещё не начинали  («Осталось выучить» / «Новое»)
    case learning   // начали учить      («Начали учить» / «Изучается»)
    case reviewing  // повторяем         («Повторяем» / «Повторяется»)
    case mastered   // освоили           («Освоили» / «Освоено»)
}

struct Example { let en: String; let ru: String }

/// Одно выражение из словаря.
struct Collocation: Identifiable {
    let id: String              // "b1.make-a-decision"
    let level: Level
    let structureSet: String    // группа: "Make", "Do", "Прилагательное + существительное"…
    let phrase: String          // "make a decision"
    let meaningEn: String       // значение по-английски
    let translationRu: String   // перевод
    let topics: [String]        // темы: "Работа и карьера", "Путешествия"…
    let example: Example?       // пример для знакомства
}
```

## Экраны и их данные

Для каждого экрана: какие данные он получает и какие действия отдаёт наружу. Названия полей сохрани.

### 1. Онбординг

```swift
struct WelcomeScreen: View {
    let onStart: () -> Void
}

struct LevelScreen: View {
    let selected: Level
    let onSelect: (Level) -> Void
    let onTakeTest: () -> Void      // «Не уверены? Короткий тест»
    let onNext: () -> Void
    let onBack: () -> Void
}

struct LevelTestQuestion { let prompt: String; let options: [String]; let level: Level }
struct LevelTestScreen: View {
    let question: LevelTestQuestion?   // nil — тест закончен
    let index: Int, total: Int
    let result: Level?                 // предложенный уровень после теста
    let onAnswer: (String?) -> Void    // nil — «Не знаю»
    let onAcceptResult: () -> Void
    let onClose: () -> Void
}

struct TopicsScreen: View {
    let topics: [(name: String, example: String)]   // 11 тем, пример выражения для каждой
    let selected: Set<String>
    let onToggle: (String) -> Void
    let onNext: () -> Void          // если ничего не выбрано, кнопка «Пропустить»
    let onBack: () -> Void
}

struct VoiceOption: Identifiable { let id: String; let name: String; let region: String; let isSystem: Bool }
struct PrefsScreen: View {
    let showTranslation: Bool
    let voices: [VoiceOption]       // обычно два: британский и американский
    let selectedVoiceId: String?
    let allVoicesCount: Int
    let onToggleTranslation: (Bool) -> Void
    let onSelectVoice: (String) -> Void
    let onListenVoice: (String) -> Void
    let onOpenAllVoices: () -> Void
    let onStartFirstLesson: () -> Void   // «Первое занятие · 3 карточки»
    let onSkip: () -> Void
    let onBack: () -> Void
}
```

### 2. Сегодня

Два состояния: план не выполнен и план выполнен.

```swift
struct TodayPlan {
    let reviews: Int            // повторений сегодня
    let news: Int               // новых сегодня
    let topicsLine: String      // "Работа и карьера, Путешествия · B1"
    let canResume: Bool         // есть начатое и не законченное занятие
    let resumeStep: Int, resumeTotal: Int
}
struct TodayDone {
    let mastered: Int, reviewed: Int, started: Int, minutes: Int   // показывать только строки > 0
    let continueTopic: (title: String, level: Level, newCount: Int,
                        counts: [LearningState: Int], total: Int)?   // nil — блок не показывать
    let newToday: [Collocation]  // показать до 3, ссылка «все N»
    let levelFinished: Level?    // если на уровне кончились новые: предложить следующий
}
struct TodayScreen: View {
    let dateLine: String                // "Сегодня · Чт, 5 ноября"
    let plan: TodayPlan?                // nil — план выполнен, тогда done не nil
    let done: TodayDone?
    let expressionOfDay: Collocation
    let showTranslation: Bool
    let onStart: () -> Void
    let onResume: () -> Void
    let onOpenCatalog: () -> Void
    let onOpenTopic: (String) -> Void
    let onShowAllNew: () -> Void
    let onSwitchLevel: (Level) -> Void
    let onListen: (String) -> Void      // текст для озвучки по-английски
}
```

Подсказка под планом: «Рекомендуется не больше 10 новых фраз в день.» Заголовок при выполненном плане: «Вы молодец!». Единицы в итогах: «1 фразу / 2 фразы / 5 фраз», «N мин».

### 3. Каталог

```swift
struct GroupSummary: Identifiable {
    let id: String              // название группы
    let title: String           // "Make"
    let examples: String        // "make a decision, make progress…"
    let counts: [LearningState: Int]
    let total: Int
}
struct CatalogScreen: View {
    let query: String
    let level: Level?                   // nil — «Все»
    let userLevel: Level
    let topics: [String]                // чипы тем, первый чип «Избранное»
    let groups: [GroupSummary]
    let searchResults: [(Collocation, LearningState, isFavorite: Bool)]
    let showTranslation: Bool
    let onQuery: (String) -> Void
    let onLevel: (Level?) -> Void
    let onOpenFavorites: () -> Void
    let onOpenTopic: (String) -> Void
    let onOpenGroup: (String) -> Void
    let onOpenItem: (String) -> Void    // id выражения
    let onListen: (String) -> Void
}

/// Экран темы, группы или избранного.
struct GroupDetailScreen: View {
    let title: String
    let level: Level?                    // nil для избранного (переключателя уровня нет)
    let levelsWithItems: Set<Level>      // уровни без выражений бледные и не нажимаются
    let items: [(Collocation, LearningState, isFavorite: Bool)]
    let counts: [LearningState: Int]
    let newCount: Int, startedCount: Int
    let showTranslation: Bool
    let onLevel: (Level) -> Void
    let onLearn: () -> Void              // «Учить эту тему · N новых»
    let onPractice: () -> Void           // «Потренироваться · N начатых»
    let onOpenItem: (String) -> Void
    let onListen: (String) -> Void
    let onBack: () -> Void
}

/// Нижний лист, когда новые на сегодня уже набраны.
struct LimitSheet: View {
    let started: Int
    let onLater: () -> Void      // «Продолжить завтра»
    let onAnyway: () -> Void     // «Всё равно учить»
}

/// Карточка выражения из каталога.
struct ExpressionDetailScreen: View {
    let item: Collocation
    let gapFullSentence: String, gapTranslation: String   // второй пример
    let state: LearningState
    let nextReview: String?      // "через 6 дней"
    let isFavorite: Bool, isHidden: Bool
    let showTranslation: Bool
    let slowRate: Double         // 0.7
    let onListen: (String) -> Void
    let onListenSlow: (String) -> Void
    let onToggleFavorite: () -> Void
    let onToggleHidden: () -> Void
}
```

### 4. Учебное занятие (на весь экран)

Общая шапка: крестик «Закрыть занятие», полоска прогресса, «3 / 30». Шагов три вида.

```swift
struct SessionHeader { let index: Int; let total: Int }   // index с 0

/// Знакомство с новым выражением.
struct IntroStepScreen: View {
    let header: SessionHeader
    let item: Collocation
    let isFavorite: Bool
    let showTranslation: Bool
    let slowRate: Double
    let onListen: (String) -> Void
    let onListenSlow: (String) -> Void
    let onToggleFavorite: () -> Void
    let onNext: () -> Void           // «Понятно, дальше»
    let onAlreadyKnow: () -> Void    // «Уже знаю — сразу проверить»
    let onClose: () -> Void
}

/// Выбор правильного выражения из трёх.
struct RecognizeStepScreen: View {
    let header: SessionHeader
    let question: String             // "Какое выражение означает «поднять вопрос»?"
    let options: [String]            // 3 варианта, порядок уже перемешан
    let isRetry: Bool                // повтор после ошибки
    /// Возвращает, верен ли ответ. Вызвать один раз по кнопке «Проверить».
    let onCheck: (String) -> Bool
    /// После проверки показать перевод каждого варианта и объяснение.
    let meaningOf: (String) -> String
    let explanationFor: (String) -> String?   // почему выбранный вариант не подходит
    let correctPhrase: String
    let correctMeaning: String
    let example: Example?
    let onListen: (String) -> Void
    let onNext: () -> Void
    let onClose: () -> Void
}

struct WordMark { let word: String; let ok: Bool }
enum Verdict {
    case correct          // «Верно!»
    case typoAccepted     // засчитано, но с опечаткой (A2–B1)
    case spelling         // выражение верное, написание нет (B2–C1), ошибка
    case distractor(explanationRu: String)   // другое настоящее выражение
    case wrong            // неверно или «Не помню»
}
struct CheckResult { let verdict: Verdict; let target: String; let marks: [WordMark] }

/// Вписать выражение целиком.
struct ProduceStepScreen: View {
    let header: SessionHeader
    let isReview: Bool               // «Повторение · подошёл срок»
    let isRetry: Bool
    let sentenceBefore: String       // текст до пропуска
    let sentenceAfter: String        // после пропуска
    let wordCount: Int               // сколько слов в ответе
    let meaningEn: String
    let hintRu: String               // перевод, скрыт до нажатия «Показать»
    let firstLettersHint: String     // "g____ c_______"
    let showTranslation: Bool
    let draft: String                // восстановленный черновик
    let fullSentence: String, fullTranslation: String, answer: String   // для разбора
    let onDraftChange: (String) -> Void
    let onShowHint: () -> Void
    let onShowTranslation: () -> Void
    let onCheck: (String) -> CheckResult
    let onGiveUp: () -> CheckResult  // «Не помню — показать ответ»
    let onListen: (String) -> Void
    let onNext: () -> Void
    let onClose: () -> Void
}

/// Итог занятия.
struct SummaryRow: Identifiable { let id: String; let phrase: String; let note: String; let next: String }
struct SummaryScreen: View {
    let isFirstLesson: Bool
    let reviews: Int, newStarted: Int, fixedMistakes: Int
    let rows: [SummaryRow]
    let onDone: () -> Void
}
```

### 5. Прогресс

```swift
struct ProgressScreen: View {
    let level: Level?                         // nil — «Все»
    let counts: [LearningState: Int]          // уже по выбранному уровню
    let total: Int                            // число выражений уровня (326 для «Все»)
    let days: [(date: Date, studied: Bool, isToday: Bool, isFuture: Bool)]  // 28 дней, неделя с понедельника
    let onLevel: (Level?) -> Void
}
```

Подписи состояний здесь: «Освоили», «Повторяем», «Начали учить», «Осталось выучить».

### 6. Настройки

```swift
struct SettingsScreen: View {
    let englishVoiceName: String, russianVoiceName: String
    let slowRate: Double                      // 0.5…0.8
    let level: Level
    let topicsCount: Int
    let newPerDay: Int                        // 5, 10, 15, 20
    let showTranslation: Bool
    let retention: Double                     // 0.85…0.95, подпись «Частота повторений»
    let reminderOn: Bool, reminderTime: Date
    let theme: String                         // "Как в системе" / "Светлая" / "Тёмная"
    let accountName: String?                  // nil — показать кнопку «Вход с Apple»
    let contentVersion: String
    let onOpenEnglishVoices: () -> Void
    let onOpenRussianVoices: () -> Void
    let onSlowRate: (Double) -> Void
    let onLevel: (Level) -> Void
    let onOpenTopics: () -> Void
    let onNewPerDay: (Int) -> Void
    let onShowTranslation: (Bool) -> Void
    let onRetention: (Double) -> Void
    let onReminder: (Bool) -> Void
    let onReminderTime: (Date) -> Void
    let onTheme: (String) -> Void
    let onSignInWithApple: () -> Void         // саму кнопку Apple вставлю я, оставь под неё место 50 pt
    let onSignOut: () -> Void
    let onResetProgress: () -> Void           // с подтверждением
}

struct VoicesScreen: View {
    let title: String                         // "Голос для английского"
    let voices: [VoiceOption]                 // у системного голоса пометка «(системный)»
    let selectedId: String?
    let downloadHint: String                  // текст про скачивание голосов
    let onSelect: (String) -> Void
    let onListen: (String) -> Void
    let onBack: () -> Void
}
```

## Что прислать в ответ

1. Набор файлов `.swift`, каждый файл целиком, без сокращений вроде `// ...`:
   - `Theme.swift`: цвета для обеих тем, шрифты, отступы;
   - `Components.swift`: общие кнопки, карточки, полоски;
   - по одному файлу на экран: `TodayScreen.swift`, `CatalogScreen.swift`, `GroupDetailScreen.swift`, `ExpressionDetailScreen.swift`, `IntroStepScreen.swift`, `RecognizeStepScreen.swift`, `ProduceStepScreen.swift`, `SummaryScreen.swift`, `ProgressScreen.swift`, `SettingsScreen.swift`, `VoicesScreen.swift`, `OnboardingScreens.swift`, `TabBar.swift`;
   - `PreviewData.swift`: примерные данные для превью.
2. Код должен собираться в Xcode 26+ без ошибок и предупреждений вместе с типами из раздела «Общие типы данных».
3. В начале ответа коротко опиши, какие решения ты принял по дизайну и что, по-твоему, нужно добавить в данные.
