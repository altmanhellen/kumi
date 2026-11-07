// Kumi site: the privacy policy and support pages the App Store links to, in English and Russian.
// The app needs nothing else from here: it works fully offline.

import { privacyPage, supportPage } from "./pages.js";

export default {
  async fetch(request) {
    const { pathname } = new URL(request.url);
    if (pathname === "/privacy" || pathname === "/support") {
      const html = pathname === "/privacy" ? privacyPage(request) : supportPage(request);
      return new Response(html, { headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=3600" } });
    }
    return new Response("Kumi", { status: 200 });
  },
};
