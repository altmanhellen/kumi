// Public pages for the App Store: the privacy policy and the support page, in English and Russian.
// /privacy and /support pick the language from ?lang= or the browser.

const EMAIL = "kumi.english.app@gmail.com";
const UPDATED = { en: "6 November 2026", ru: "6 ноября 2026 г." };
const LANGS = ["en", "ru"];

const PRIVACY = {
  en: {
    title: "Kumi — Privacy Policy",
    intro: "Kumi helps you learn English collocations: phrases like “make a decision” or “heavy rain”. It works fully offline, and your learning stays on your iPhone.",
    sections: [
      ["What we collect", "Nothing. Kumi has no servers, no ads, no analytics and no tracking. We don't know who uses the app."],
      ["Your progress", "Your answers, review schedule and settings are stored only on your iPhone and are included in its iCloud backup, if you have backups turned on."],
      ["Sign in with Apple", "Signing in is optional. If you sign in, the name and email Apple shares are saved only on your iPhone to label your account in Settings. They are never sent to us."],
      ["Pronunciation and reminders", "Phrases are read aloud with the iPhone's built-in voices. Daily reminders, if you turn them on, are scheduled on your iPhone."],
      ["Purchases", "Purchases in Kumi are handled by Apple through the App Store. We never receive your payment details."],
      ["Deleting your data", "Reset progress in Kumi's Settings, or delete the app, and everything Kumi kept is gone."],
      ["Children", "Kumi is not directed at children under 13 and collects no information from anyone."],
      ["Changes and contact", `If this policy changes, the new version will appear on this page with a new date. Questions and suggestions: ${EMAIL}.`],
    ],
    updated: "Last updated",
  },
  ru: {
    title: "Kumi — политика конфиденциальности",
    intro: "Kumi помогает учить английские сочетания слов, например «make a decision» или «heavy rain». Приложение работает без интернета, а ваши занятия остаются на вашем iPhone.",
    sections: [
      ["Что мы собираем", "Ничего. У Kumi нет серверов, рекламы, аналитики и слежения. Мы не знаем, кто пользуется приложением."],
      ["Ваш прогресс", "Ответы, расписание повторений и настройки хранятся только на вашем iPhone и попадают в его резервную копию iCloud, если она включена."],
      ["Вход через Apple", "Входить не обязательно. Если вы вошли, имя и почта, которые передаёт Apple, сохраняются только на iPhone, чтобы подписать вашу учётную запись в настройках. Нам они не отправляются."],
      ["Произношение и напоминания", "Фразы читаются встроенными голосами iPhone. Ежедневные напоминания, если вы их включили, планируются на самом iPhone."],
      ["Покупки", "Покупками в Kumi занимается Apple через App Store. Мы не получаем ваши платёжные данные."],
      ["Удаление данных", "Сбросьте прогресс в настройках Kumi или удалите приложение, и всё, что хранил Kumi, исчезнет."],
      ["Дети", "Kumi не предназначен для детей младше 13 лет и ни у кого не собирает данные."],
      ["Изменения и связь", `Если политика изменится, новая версия появится на этой странице с новой датой. Вопросы и предложения: ${EMAIL}.`],
    ],
    updated: "Обновлено",
  },
};

const SUPPORT = {
  en: {
    title: "Kumi — Support",
    intro: "Kumi teaches 326 English collocations from A2 to C1 in short daily sessions with spaced repetition.",
    sections: [
      ["How are reviews scheduled?", "Kumi brings each phrase back just before you are likely to forget it. Reviews that are due come first in every session; new phrases follow, up to the daily limit you set."],
      ["No sound", "Check that the iPhone isn't muted and the volume is up. You can choose another English voice in Kumi's Settings; more voices can be downloaded in the iPhone's Settings → Accessibility → Spoken Content → Voices."],
      ["Move progress to a new iPhone", "Progress is kept in the iPhone's iCloud backup. Set up the new iPhone from that backup and Kumi will continue where you left off."],
      ["Restore a purchase", "On a new iPhone or after reinstalling, open Kumi's Settings and tap Restore Purchase, signed in with the same Apple Account."],
      ["Contact", `Write to ${EMAIL}. We read every message.`],
    ],
    privacy: "Privacy Policy",
  },
  ru: {
    title: "Kumi — поддержка",
    intro: "Kumi учит 326 английских сочетаний слов от A2 до C1 короткими ежедневными занятиями с интервальными повторениями.",
    sections: [
      ["Как устроены повторения?", "Kumi возвращает фразу как раз перед тем, как вы её забыли бы. В каждом занятии сначала идут повторения, у которых подошёл срок, потом новые фразы, не больше дневного лимита."],
      ["Нет звука", "Проверьте, что iPhone не в беззвучном режиме и громкость включена. Другой английский голос можно выбрать в настройках Kumi, новые голоса загружаются в Настройках iPhone → Универсальный доступ → Устный контент → Голоса."],
      ["Перенести прогресс на новый iPhone", "Прогресс попадает в резервную копию iCloud. Восстановите новый iPhone из этой копии, и Kumi продолжит с того же места."],
      ["Восстановить покупку", "На новом iPhone или после переустановки откройте настройки Kumi и нажмите «Восстановить покупку», под той же учётной записью Apple."],
      ["Связаться с нами", `Пишите на ${EMAIL}. Мы читаем каждое письмо.`],
    ],
    privacy: "Политика конфиденциальности",
  },
};

function pickLanguage(request) {
  const url = new URL(request.url);
  const asked = url.searchParams.get("lang");
  if (LANGS.includes(asked)) return asked;
  const header = (request.headers.get("accept-language") ?? "").toLowerCase();
  for (const part of header.split(",")) {
    const code = part.trim().slice(0, 2);
    if (LANGS.includes(code)) return code;
  }
  return "en";
}

const escape = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

function page(lang, path, title, intro, sections, footer) {
  const dir = "ltr";
  const switcher = LANGS.map((l) => (l === lang ? `<b>${l.toUpperCase()}</b>` : `<a href="${path}?lang=${l}">${l.toUpperCase()}</a>`)).join(" · ");
  const body = sections.map(([h, p]) => `<h2>${escape(h)}</h2><p>${escape(p).replace(EMAIL, `<a href="mailto:${EMAIL}">${EMAIL}</a>`)}</p>`).join("\n");
  return `<!doctype html><html lang="${lang}" dir="${dir}"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>${escape(title)}</title>
<style>
:root{--wash:#F9F9F7;--ink:#2E2C27;--soft:#6B6A63;--clay:#C6613F;--hair:#E4E3DC}
@media (prefers-color-scheme: dark){:root{--wash:#1D1C19;--ink:#ECEAE3;--soft:#A9A79E;--clay:#D9774F;--hair:#36352F}}
body{margin:0;background:var(--wash);color:var(--ink);font:17px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
main{max-width:680px;margin:0 auto;padding:32px 16px 64px}
h1{font:600 32px/1.2 ui-serif,Georgia,serif;margin:8px 0 12px}
h2{font-size:18px;margin:28px 0 6px}
p{margin:0;color:var(--ink)} .intro{color:var(--soft);font-size:18px}
a{color:var(--clay)} nav{font-size:14px;color:var(--soft)} footer{margin-top:40px;padding-top:16px;border-top:1px solid var(--hair);font-size:14px;color:var(--soft)}
</style></head><body><main><nav>${switcher}</nav><h1>${escape(title)}</h1><p class="intro">${escape(intro)}</p>
${body}
<footer>${footer}</footer></main></body></html>`;
}

export function privacyPage(request) {
  const lang = pickLanguage(request);
  const t = PRIVACY[lang];
  return page(lang, "/privacy", t.title, t.intro, t.sections, `${escape(t.updated)}: ${UPDATED[lang]}`);
}

export function supportPage(request) {
  const lang = pickLanguage(request);
  const t = SUPPORT[lang];
  return page(lang, "/support", t.title, t.intro, t.sections, `<a href="/privacy?lang=${lang}">${escape(t.privacy)}</a>`);
}
