# App Store texts for Kumi; run to print with character counts.
T = {
 "ru": {
  "subtitle": "Говорите как носитель",
  "promo": "do a mistake или make a mistake? 326 главных английских сочетаний слов: короткие занятия по 10 минут и повторения точно вовремя, чтобы фразы запомнились.",
  "keywords": "коллокации,английский,фразы,выражения,словосочетания,разговорный,лексика,слова,повторение,B1,B2,ESL",
  "description": """Знаете английские слова, но фразы звучат «по-русски»? Do a mistake вместо make a mistake, big rain вместо heavy rain. Носители говорят готовыми сочетаниями слов, и Kumi учит именно их.

326 ГЛАВНЫХ СОЧЕТАНИЙ
Не словарь на тысячи страниц, а отобранный курс: самые частые сочетания от A2 до C1 по темам — работа, деньги, здоровье, путешествия, отношения, новости и другие. Курс конечный, его реально пройти до конца.

КАК ПРОХОДИТ ЗАНЯТИЕ
• Знакомство: значение, перевод и примеры из жизни
• Узнавание: выберите правильное сочетание среди похожих
• Вспоминание: впишите фразу сами, с подсказкой, если нужно
• Озвучка встроенными голосами iPhone, можно медленнее

ПОВТОРЕНИЯ ТОЧНО ВОВРЕМЯ
Kumi возвращает фразу как раз тогда, когда вы начали бы её забывать. Каждый день сначала повторения, потом новые выражения — не больше выбранного вами лимита.

УДОБНО КАЖДЫЙ ДЕНЬ
• 5–10 минут в день
• Ежедневное напоминание
• Каталог с поиском, уровнями и темами
• Прогресс и регулярность занятий
• Светлая и тёмная тема
• Занятия работают без интернета

БЕСПЛАТНО И ОДНОЙ ПОКУПКОЙ
Первые 30 выражений бесплатно. Остальные открываются одной покупкой навсегда — без подписки и рекламы. Повторять начатые выражения можно всегда.

Аккаунт не нужен. Без аналитики и слежения: ваш прогресс хранится только на iPhone.""",
  "whatsnew": "Первая версия Kumi.",
 },
 "en": {
  "subtitle": "Speak like a native",
  "promo": "Do a mistake or make a mistake? Learn the 326 English word combinations native speakers use every day, in 10-minute lessons with reviews timed so they stick.",
  "keywords": "collocations,english,phrases,vocabulary,idioms,speaking,esl,learn english,words,expressions,b1,b2",
  "description": """You know English words, but your phrases don't sound quite right? Do a mistake instead of make a mistake, big rain instead of heavy rain. Native speakers talk in ready-made word combinations, and Kumi teaches exactly those.

326 KEY COLLOCATIONS
Not a dictionary of thousands of pages, but a focused course: the most common combinations from A2 to C1, grouped by topic — work, money, health, travel, relationships, news and more. A course you can actually finish. Explanations and translations are in Russian.

HOW A LESSON WORKS
• Meet: meaning, translation and real-life examples
• Recognise: pick the right combination among similar ones
• Recall: type the phrase yourself, with a hint if you need one
• Listen with the iPhone's built-in voices, slowed down if you like

REVIEWS RIGHT ON TIME
Kumi brings a phrase back just before you would start to forget it. Each day starts with reviews, then new expressions, up to the daily limit you choose.

EASY TO KEEP GOING
• 5–10 minutes a day
• A daily reminder
• Catalog with search, levels and topics
• Progress and streak calendar
• Light and dark theme
• Lessons work offline

FREE TO START, ONE PURCHASE
The first 30 expressions are free. One purchase unlocks the rest for good — no subscription, no ads. Reviews of expressions you've started are always free.

No account needed. No analytics, no tracking: your progress stays on your iPhone.""",
  "whatsnew": "The first version of Kumi.",
 },
}
LIMITS = {"subtitle": 30, "promo": 170, "keywords": 100, "description": 4000}
if __name__ == "__main__":
    for lang, t in T.items():
        for k, v in t.items():
            lim = LIMITS.get(k)
            print(f"{lang} {k}: {len(v)}" + (f"/{lim}" + (" OVER" if len(v) > lim else "") if lim else ""))
