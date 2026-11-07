# Kumi 1.0: что заполнить в App Store Connect

Составлено 07.11.2026. Сборка для отправки: **68**. Тексты страницы (описание, ключевые слова и т. д.) лежат в соседнем файле `AppStoreTexts.md`, скриншоты в папке `screenshots-6.9`.

Как читать: «видно на скриншоте» значит, что пункт меню виден на вашем снимке экрана от 07.11 19:38. Остальные названия по справке Apple и по памяти, на экране они могут называться чуть иначе.

---

## 1. App Information (левая колонка → General → App Information, видно на скриншоте)

| Поле | Что вписать |
|---|---|
| Primary Language | Russian |
| Name (Russian) | Kumi: English Collocations |
| Subtitle (Russian) | Говорите как носитель |
| Category | Primary: Education, Secondary: Reference |
| Content Rights | «No, it does not contain, show, or access third-party content». Тексты курса ваши, шрифты под свободной лицензией OFL |
| Age Rating | см. раздел 6 |

Затем добавьте язык **English (U.S.)**: выпадающий список языков справа вверху на этой странице (по памяти). Для английского:
- Name: Kumi: English Collocations
- Subtitle: Speak like a native

Нажмите **Save**.

## 2. App Privacy (левая колонка → Trust & Safety → App Privacy, видно на скриншоте)

1. **Privacy Policy URL**: рядом с Privacy Policy нажмите Edit и вставьте https://kumi.kumi-english.workers.dev/privacy
2. **Data Collection**: нажмите Get Started (или Edit) и ответьте **«No, we do not collect data from this app»**.
   Почему так: в коде нет сетевых запросов, аналитики и рекламы (проверено поиском по коду 07.11). Имя и почта из «Входа через Apple» хранятся только на телефоне и никуда не отправляются. По правилам Apple «собранными» считаются только данные, которые уходят с устройства.
3. Нажмите **Publish**. Если сработало, на странице появится карточка «Data Not Collected».

## 3. Встроенная покупка (раздел Monetization → In-App Purchases, ниже в левой колонке, на скриншоте не видно)

Если покупку ещё не создавали: кнопка **+** (или Create), тип **Non-Consumable**.

| Поле | Что вписать |
|---|---|
| Reference Name | Full access |
| Product ID | `com.elenaaltman.kumi.full` (ровно так, этот ID зашит в коде) |
| Price | USD 7.99 |
| Availability | те же страны, что у приложения (см. раздел 5) |
| Localization (Russian): Display Name | Все 326 выражений |
| Localization (Russian): Description | Открывает все выражения навсегда, без подписки |
| Localization (English U.S.): Display Name | All 326 expressions |
| Localization (English U.S.): Description | Unlocks every expression for good, no subscription |
| Review Screenshot | `~/Projects/Kumi/docs/iap-review.png` (экран покупки, 1320×2868) |
| Review Notes | текст ниже |

Review Notes для покупки:

```
Non-consumable unlock. The first 30 new expressions are free; this purchase opens the remaining ones. To see the purchase screen right away: open the Settings tab (Настройки, last tab) and tap «Открыть все выражения». «Восстановить покупку» restores it.
```

Лимиты: Display Name до 30 знаков, Description до 45 (по памяти). Все тексты выше в них укладываются.

**Важно:** у первой версии покупку нужно приложить к ней. На странице версии 1.0 есть блок **In-App Purchases and Subscriptions** (по памяти, ниже блока Build). Нажмите там + и выберите Full access. Без этого покупка не уйдёт на проверку вместе с приложением.

## 4. Страница версии (левая колонка → iOS App → 1.0 Prepare for Submission, видно на скриншоте)

Язык переключается вверху страницы. Сначала заполните **Russian**, потом **English (U.S.)**.

| Поле | Russian | English (U.S.) |
|---|---|---|
| iPhone 6.9" Display (скриншоты) | 7 файлов из `screenshots-6.9`, в порядке номеров | можно не загружать: если у языка своих нет, показываются скриншоты основного (по памяти) |
| Promotional Text | из AppStoreTexts.md, раздел «Русский» | из раздела «English» |
| Description | из раздела «Русский» | из раздела «English» |
| Keywords | из раздела «Русский» | из раздела «English» |
| Support URL | https://kumi.kumi-english.workers.dev/support | то же |
| Marketing URL | пусто | пусто |
| What's New | у первой версии этого поля обычно нет; если есть: «Первая версия Kumi.» | «The first version of Kumi.» |

Поля, общие для всех языков:

| Поле | Что вписать |
|---|---|
| Version | 1.0 |
| Copyright | 2026 Elena Altman |
| Build | нажмите + и выберите **1.0 (68)**. Сборка появится здесь после Distribute и обработки (обычно 10–30 минут) |
| In-App Purchases | приложите Full access (см. раздел 3) |

### App Review Information (на этой же странице, видно на скриншоте)

- **Sign-in required**: галочку **не** ставить (аккаунт не нужен).
- **Contact Information**: уже заполнено.
- **Notes**: вставьте текст ниже.
- **Attachment**: не нужно.

```
Kumi is an English collocation trainer for Russian speakers, so the interface is in Russian. No account is needed.

How to try it:
1. Tap «Попробовать», pick any topics, tap «Продолжить», then «К занятиям».
2. On the «Сегодня» (Today) tab tap «Начать занятие» to start a lesson: a new expression card, a multiple-choice task and a typing task.

In-app purchase (com.elenaaltman.kumi.full, non-consumable): the first 30 new expressions are free, after that new expressions need the purchase. To open the purchase screen right away: Settings tab (Настройки, last tab) → «Открыть все выражения». «Восстановить покупку» restores a previous purchase.

Sign in with Apple (Settings → Аккаунт) is optional. The name and email are stored only on the device and are not sent anywhere; «Выйти и удалить аккаунт» deletes them.

The app makes no network requests besides App Store purchases. Progress is stored on the device. Pronunciation uses the built-in iOS voices.
```

### App Store Version Release (ниже на этой же странице)

Советую **Manually release this version**: после одобрения вы сами нажмёте Release, когда будете готовы. Вариант Automatically выпустит приложение сразу после одобрения.

## 5. Цена и страны (раздел Monetization → Pricing and Availability, на скриншоте не видно)

- **Price**: Free (приложение бесплатное, платная только покупка внутри).
- **Availability**: все страны, **кроме стран ЕС**. Решение то же, что для Yomi: без статуса трейдера по DSA в ЕС не распространяем. При желании можно оставить Великобританию, Швейцарию и Норвегию, они не в ЕС.
- Если App Store Connect спросит про **Trader Status** (DSA), выберите, что вы не трейдер. После этого ЕС будет недоступен, это ожидаемо.

## 6. Age Rating (App Information → Age Rating → Edit)

На все вопросы ответ **None / No**: насилия, тем 18+, азартных игр, рекламы, общения между пользователями и пользовательского контента нет. Веб-браузера в приложении нет. Получится **4+**. Если в анкете есть вопрос про контроль родителей или возраст, тоже No.

## 7. App Accessibility (Trust & Safety → App Accessibility, видно на скриншоте)

Пока можно пропустить, для отправки на проверку этот раздел не обязателен (по памяти). Если захотите заполнить: в приложении работает увеличенный шрифт (Larger Text) и тёмная тема (Dark Interface). VoiceOver я не проверяла, его не отмечайте.

## 8. Отправка

1. Xcode → Organizer → **Kumi 1.0 (68)** → Distribute App → App Store Connect → Upload.
2. Подождите, пока сборка 68 появится в TestFlight (обычно 10–30 минут, придёт письмо).
3. Страница версии 1.0 → Build → выберите 68 → Save.
4. Проверьте, что ни в одном разделе нет красных восклицательных знаков.
5. Нажмите **Add for Review** справа вверху, затем **Submit for Review**.
6. Проверка обычно занимает от суток до нескольких дней. Если откажут, пришлите текст отказа.

## Риск, о котором стоит знать

«Вход через Apple» сейчас только запоминает имя на телефоне и ничего не синхронизирует. Проверяющий может спросить, зачем он нужен (правило «функция должна что-то делать»). В Notes это объяснено. Если всё же откажут по этой причине, проще всего убрать вход из версии 1.0 и вернуть его, когда появится синхронизация.
