import AuthenticationServices
import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    #if DEBUG
    @MainActor static var debugOpened = false
    #endif
    @Environment(AppModel.self) private var model
    @Environment(Store.self) private var store
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var shareURL: URL?
    @State private var importing = false
    @State private var message: String?
    @State private var confirmReset = false
    @State private var confirmSignOut = false
    @State private var openVoices = false

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(WPFont.labelText("Настройки")).font(WPFont.label(26)).foregroundStyle(Palette.muted)
                    ScreenTitle(text: "Как вам удобно")
                }
                .padding(.top, 10)
                section("Озвучка")
                PaperBox(variant: 0) {
                    NavigationLink { VoicePicker(language: .english) } label: {
                        SettingsRow(title: "Английский", subtitle: "выражения и примеры", value: model.englishVoiceName)
                    }
                    DashedDivider()
                    NavigationLink {
                        ChoiceScreen(title: "Медленное воспроизведение",
                                     note: "Скорость, с которой звучит выражение по кнопке медленного воспроизведения.",
                                     options: [0.5, 0.6, 0.7, 0.8].map { ChoiceOption(value: $0, title: String(format: "%.1f×", $0)) },
                                     selected: model.prefs.slowRate,
                                     onSelect: { r in model.updatePrefs { $0.slowRate = r } },
                                     onPreview: { r in Speech.shared.speak(VoiceLanguage.english.sample, voiceId: model.prefs.englishVoiceId, language: model.prefs.accent.locale, slow: true, slowRate: r) })
                    } label: {
                        SettingsRow(title: "Медленное воспроизведение", value: String(format: "%.1f×", model.prefs.slowRate))
                    }
                }
                note("Используются только голоса, встроенные в iOS. Новые голоса скачиваются в Настройках iPhone: Универсальный доступ → Чтение вслух (в более ранних версиях iOS — «Устный контент») → Голоса.")

                section("Обучение")
                PaperBox(variant: 1) {
                    NavigationLink {
                        ChoiceScreen(title: "Уровень",
                                     note: "С этого уровня начинаются новые выражения. Выражения других уровней остаются в каталоге.",
                                     options: Level.allCases.map { ChoiceOption(value: $0, title: "\($0.rawValue) · \($0.name)", subtitle: $0.blurb) },
                                     selected: model.prefs.level,
                                     onSelect: { l in model.updatePrefs { $0.level = l } })
                    } label: {
                        SettingsRow(title: "Уровень", value: model.prefs.level.rawValue)
                    }
                    DashedDivider()
                    NavigationLink { TopicsSettings() } label: {
                        SettingsRow(title: "Темы", value: model.prefs.topics.isEmpty ? "все" : "\(model.prefs.topics.count)")
                    }
                    DashedDivider()
                    NavigationLink {
                        ChoiceScreen(title: "Новых в день",
                                     note: "Сколько новых выражений Kumi предлагает за день. Повторения сюда не входят.",
                                     options: [5, 10, 15, 20].map { ChoiceOption(value: $0, title: "\($0)") },
                                     selected: model.prefs.newPerDay,
                                     onSelect: { n in model.updatePrefs { $0.newPerDay = n } })
                    } label: {
                        SettingsRow(title: "Новых в день", value: "не больше \(model.prefs.newPerDay)")
                    }
                    DashedDivider()
                    Toggle(isOn: Binding(get: { model.prefs.showTranslation }, set: { v in model.updatePrefs { $0.showTranslation = v } })) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Показывать перевод").font(WPFont.nunito(16, .heavy)).foregroundStyle(Palette.text)
                            Text("в заданиях на воспроизведение — после ответа").font(WPFont.nunito(14)).foregroundStyle(Palette.muted)
                        }
                    }
                    .toggleStyle(WPToggleStyle())
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    DashedDivider()
                    NavigationLink {
                        ChoiceScreen(title: "Частота повторений",
                                     note: "Какую долю выражений вы хотите помнить к моменту повторения. Чем выше процент, тем чаще повторения.",
                                     options: [0.85, 0.88, 0.9, 0.92, 0.95].map {
                                         ChoiceOption(value: $0, title: "\(Int(($0 * 100).rounded()))%", subtitle: $0 == 0.9 ? "по умолчанию" : nil)
                                     },
                                     selected: model.prefs.desiredRetention,
                                     onSelect: { r in model.updatePrefs { $0.desiredRetention = r } })
                    } label: {
                        SettingsRow(title: "Частота повторений", subtitle: "Выше % — чаще повторения", value: "\(Int(model.prefs.desiredRetention * 100))%")
                    }
                }

                section("Напоминание")
                PaperBox(variant: 2) {
                    Toggle(isOn: Binding(get: { model.prefs.reminderEnabled }, set: setReminder)) {
                        Text("Раз в день").font(WPFont.nunito(16, .heavy)).foregroundStyle(Palette.text)
                    }
                    .toggleStyle(WPToggleStyle())
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    if model.prefs.reminderEnabled {
                        DashedDivider()
                        DatePicker("Время", selection: reminderTime, displayedComponents: .hourAndMinute)
                            .font(WPFont.nunito(16, .heavy))
                            .foregroundStyle(Palette.text)
                            .padding(.horizontal, 14).padding(.vertical, 6)
                    }
                }

                section("Оформление")
                PaperBox(variant: 3) {
                    NavigationLink {
                        ChoiceScreen(title: "Тема",
                                     options: AppTheme.allCases.map { ChoiceOption(value: $0, title: $0.title) },
                                     selected: model.prefs.theme,
                                     onSelect: { t in model.updatePrefs { $0.theme = t } })
                    } label: {
                        SettingsRow(title: "Тема", value: model.prefs.theme.title)
                    }
                }

                section("Полный доступ")
                PaperBox(variant: 2) {
                    if model.isUnlocked {
                        SettingsRow(title: "Все 326 выражений открыты", subtitle: "разовая покупка", chevron: false)
                    } else {
                        Button { model.showPaywall = true } label: {
                            SettingsRow(title: "Открыть все выражения", subtitle: "бесплатно открыто \(AppModel.freeNewLimit), начато \(min(model.startedCount, AppModel.freeNewLimit))", value: store.price)
                        }
                        .buttonStyle(.plain)
                        DashedDivider()
                        Button { Task { await store.restore() } } label: {
                            SettingsRow(title: "Восстановить покупку", chevron: false)
                        }
                        .buttonStyle(.plain)
                    }
                }

                section("Аккаунт")
                PaperBox(variant: 4) {
                    if let acc = model.file.account {
                        SettingsRow(title: acc.name ?? acc.email ?? "Apple ID", subtitle: "вход через Apple", chevron: false)
                        DashedDivider()
                        Button { confirmSignOut = true } label: {
                            SettingsRow(title: "Выйти и удалить аккаунт", chevron: false)
                        }
                    } else {
                        SignInWithAppleButton(.signIn) { req in
                            req.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleSignIn(result)
                        }
                        .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
                        .id(scheme)
                        .frame(height: 50)
                        .padding(12)
                    }
                }
                note(model.file.account == nil
                     ? "Без аккаунта прогресс хранится только на этом iPhone. Если удалить приложение или перейти на новый iPhone без восстановления из резервной копии iCloud, прогресс пропадёт."
                     : "Синхронизация с сервером Kumi включится, когда подключим сервер. Сейчас прогресс хранится на этом iPhone и попадает в его резервную копию iCloud.")

                section("Данные")
                Button { confirmReset = true } label: {
                    Text("Сбросить прогресс")
                        .font(WPFont.nunito(16, .heavy))
                        .foregroundStyle(Palette.danger)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                        .padding(.horizontal, 14)
                        .background(Palette.paper, in: Radii.shape(5))
                        .overlay(Radii.shape(5).stroke(Palette.danger, lineWidth: 2.5))
                        .contentShape(Rectangle())
                }
                note("Контент \(model.library.version) · \(model.library.items.count) выражений")
                    .id("bottom")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        #if DEBUG
        .onAppear { if ProcessInfo.processInfo.arguments.contains("-wpBottom") { proxy.scrollTo("bottom") } }
        #endif
        }
        .navigationDestination(isPresented: $openVoices) { VoicePicker(language: .english) }
        #if DEBUG
        .onAppear { if ProcessInfo.processInfo.arguments.contains("-wpVoices") && !Self.debugOpened { Self.debugOpened = true; DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { openVoices = true } }
        }
        #endif
        .screenBackground()
        .statusBarBackdrop()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $shareURL) { url in ShareSheet(items: [url]) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result {
                do {
                    let n = try model.importProgress(from: url)
                    message = "Добавлено ответов: \(n)."
                } catch {
                    message = "Не получилось прочитать файл: \(error.localizedDescription)"
                }
            }
        }
        .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("Ок", role: .cancel) {}
        }
        .confirmationDialog("Удалить весь прогресс на этом iPhone?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Сбросить", role: .destructive) { model.resetProgress() }
        } message: {
            Text("Журнал ответов на этом iPhone будет удалён.")
        }
        .confirmationDialog("Выйти и удалить аккаунт?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Удалить аккаунт", role: .destructive) { model.setAccount(nil) }
        } message: {
            Text("Прогресс на этом iPhone останется.")
        }
    }

    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(from: DateComponents(hour: model.prefs.reminderHour, minute: model.prefs.reminderMinute)) ?? Date()
        } set: { d in
            let c = Calendar.current.dateComponents([.hour, .minute], from: d)
            model.updatePrefs { $0.reminderHour = c.hour ?? 19; $0.reminderMinute = c.minute ?? 0 }
            Reminders.schedule(hour: c.hour ?? 19, minute: c.minute ?? 0)
        }
    }

    private func setReminder(_ on: Bool) {
        if on {
            Task {
                let ok = await Reminders.requestAndSchedule(hour: model.prefs.reminderHour, minute: model.prefs.reminderMinute)
                model.updatePrefs { $0.reminderEnabled = ok }
                if !ok { message = "Уведомления выключены в Настройках iPhone для Kumi." }
            }
        } else {
            Reminders.cancel()
            model.updatePrefs { $0.reminderEnabled = false }
        }
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            let name = [cred.fullName?.givenName, cred.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
            model.setAccount(Account(userId: cred.user, name: name.isEmpty ? nil : name, email: cred.email, signedInAt: Date()))
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                message = "Не получилось войти: \(error.localizedDescription)"
            }
        }
    }

    private func share(_ make: () throws -> URL) {
        do { shareURL = try make() } catch { message = "Не получилось создать файл: \(error.localizedDescription)" }
    }

    private func section(_ title: String) -> some View {
        Text(title).font(WPFont.rubik(18, false)).foregroundStyle(Palette.text).padding(.top, 26).padding(.bottom, 12)
    }

    private func note(_ text: String) -> some View {
        Text(text).font(WPFont.nunito(13)).foregroundStyle(Palette.muted).padding(.horizontal, 4).padding(.top, 8)
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

enum VoiceLanguage {
    case english, russian
    var prefix: String { self == .english ? "en" : "ru" }
    var title: String { self == .english ? "Голос для английского" : "Голос для русского" }
    var settingsName: String { self == .english ? "Английский" : "Русский" }
    var sample: String { self == .english ? "Take your time, there's no rush." : "Не торопитесь, время есть." }
}

struct VoicePicker: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    let language: VoiceLanguage
    var onboarding = false
    @State private var showLegacy = false
    @State private var personalStatus = AVSpeechSynthesizer.personalVoiceAuthorizationStatus

    private var catalog: VoiceCatalog { VoiceCatalog.shared }
    private var voices: [VoiceInfo] { catalog.voices(language: language.prefix) }
    private var modern: [VoiceInfo] { voices.filter(\.isModern).sorted { modernOrder($0) < modernOrder($1) } }
    private var plain: [VoiceInfo] { voices.filter { !$0.isModern && !$0.isLegacy } }
    private var legacy: [VoiceInfo] { voices.filter { !$0.isModern && $0.isLegacy } }

    private var chosenId: String? { language == .english ? model.prefs.englishVoiceId : model.prefs.russianVoiceId }
    private var systemLocale: String { language == .english ? model.prefs.accent.locale : "ru-RU" }
    private var systemVoice: VoiceInfo? { catalog.system(locale: systemLocale) }
    /// A saved voice that was deleted from the iPhone falls back to the iPhone's own voice.
    private var usesSystem: Bool { chosenId == nil || catalog.info(id: chosenId) == nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { dismiss() } label: {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .bold))
                    Text("Назад").font(WPFont.nunito(16, .heavy))
                }
                .foregroundStyle(Palette.text).frame(minHeight: 44)
            }
            .padding(.leading, -6)
            ScreenTitle(text: language.title).padding(.top, 18)
            Text("Нажмите на динамик, чтобы послушать.")
                .font(WPFont.nunito(15)).foregroundStyle(Palette.muted).padding(.top, 6)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PaperBox(variant: 0) {
                        systemRow
                        if language == .english {
                            divider
                            accentMenu
                        }
                    }
                    .padding(.top, 14)
                    note("Голос, который выбран для этого языка в Настройках iPhone. Если поменять его там, Kumi тоже заговорит новым голосом.")

                    if !catalog.loaded {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 30)
                    } else {
                        header("Естественные голоса")
                        if modern.isEmpty {
                            PaperBox(variant: 1) {
                                Text("На этом iPhone пока нет улучшенных и премиум-голосов. Как их скачать, написано внизу.")
                                    .font(WPFont.nunito(15)).foregroundStyle(Palette.text).padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            list(modern, variant: 1)
                        }
                        if language == .english && personalStatus == .notDetermined {
                            Button(action: askPersonalVoice) {
                                SettingsRow(title: "Мой личный голос", subtitle: "если вы записали его в Настройках iPhone", value: "разрешить", chevron: false)
                            }
                            .buttonStyle(.plain)
                            .background(Palette.paper, in: Radii.shape(2))
                            .overlay(Radii.shape(2).stroke(Palette.outline, lineWidth: 2.5))
                            .padding(.top, 10)
                        }
                        if !plain.isEmpty {
                            header("Обычные голоса")
                            list(plain, variant: 2)
                        }
                        if !legacy.isEmpty {
                            Button { withAnimation { showLegacy.toggle() } } label: {
                                HStack(spacing: 6) {
                                    Text("Старые голоса · \(legacy.count)").font(WPFont.nunito(15, .heavy)).underline()
                                    Image(systemName: showLegacy ? "chevron.up" : "chevron.down").font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Palette.chevron)
                                }
                                .foregroundStyle(Palette.text).frame(minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 14)
                            if showLegacy { list(legacy, variant: 3) }
                        }
                    }
                    header("Как скачать новые голоса")
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(downloadSteps.enumerated()), id: \.offset) { i, step in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("\(i + 1).").font(WPFont.nunito(14, .heavy))
                                Text(step).font(WPFont.nunito(14)).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .foregroundStyle(Palette.muted)
                    .padding(.horizontal, 4)
                }
                .padding(.bottom, 30)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .screenBackground()
        .statusBarBackdrop()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { catalog.load() }
        // Voices downloaded in the iPhone settings appear when the person comes back.
        .onChange(of: scenePhase) { _, phase in if phase == .active { catalog.load(force: true) } }
    }

    private var downloadSteps: [String] {
        [
            "Откройте Настройки iPhone → Универсальный доступ → Чтение вслух (в iOS до 17 — «Устный контент»).",
            "Нажмите «Голоса» → \(language.settingsName).",
            "Выберите голос с пометкой «Улучшенный» или «Премиум» и нажмите на значок загрузки.",
            "Вернитесь в Kumi: новый голос появится в этом списке.",
        ]
    }

    private var systemRow: some View {
        let on = usesSystem
        return HStack(spacing: 8) {
            Button {
                model.updatePrefs { if language == .english { $0.englishVoiceId = nil } else { $0.russianVoiceId = nil } }
            } label: {
                HStack(spacing: 12) {
                    RadioDot(on: on)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Как в iPhone").font(WPFont.nunito(16, .heavy))
                        Text(systemVoice.map { "\($0.name) · \($0.regionTitle)" } ?? (catalog.loaded ? "голос iOS по умолчанию" : " "))
                            .font(WPFont.nunito(13)).foregroundStyle(on ? Palette.inkSoft : Palette.muted)
                    }
                    Spacer()
                }
                .foregroundStyle(on ? Palette.ink : Palette.text)
                .padding(.leading, 14)
                .frame(minHeight: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(on ? .isSelected : [])
            ListenButton(label: "Послушать голос iPhone") {
                Speech.shared.speak(language.sample, voiceId: nil, language: systemLocale)
            }
            .padding(.trailing, 6)
        }
        .background(on ? Palette.teal : .clear)
    }

    private var accentMenu: some View {
        NavigationLink {
            ChoiceScreen(title: "Акцент",
                         note: "Kumi возьмёт голос iPhone с этим акцентом.",
                         options: Accent.allCases.filter { catalog.systemIds[$0.locale] != nil }.map { a in
                             ChoiceOption(value: a, title: a.title, subtitle: catalog.system(locale: a.locale)?.name)
                         },
                         selected: model.prefs.accent,
                         onSelect: { a in model.updatePrefs { $0.accent = a; $0.englishVoiceId = nil } },
                         onPreview: { a in Speech.shared.speak(VoiceLanguage.english.sample, voiceId: nil, language: a.locale) })
        } label: {
            SettingsRow(title: "Акцент", subtitle: "для голоса iPhone", value: model.prefs.accent.title)
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        DashedDivider.Line().stroke(Palette.divider, style: StrokeStyle(lineWidth: 2, dash: [6, 5])).frame(height: 2)
    }

    private func header(_ title: String) -> some View {
        Text(title).font(WPFont.rubik(18, false)).foregroundStyle(Palette.text).padding(.top, 26).padding(.bottom, 10)
    }

    private func note(_ text: String) -> some View {
        Text(text).font(WPFont.nunito(13)).foregroundStyle(Palette.muted).padding(.horizontal, 4).padding(.top, 8)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func list(_ items: [VoiceInfo], variant: Int) -> some View {
        PaperBox(variant: variant) {
            ForEach(Array(items.enumerated()), id: \.element.id) { i, v in
                if i > 0 { divider }
                row(v)
            }
        }
    }

    /// Personal Voice first, then premium before enhanced, then the person's accent before the others.
    private func modernOrder(_ v: VoiceInfo) -> (Int, Int, Int, String, String) {
        (v.isPersonal ? 0 : 1, -v.quality.rawValue, v.language == systemLocale ? 0 : 1, v.language, v.name)
    }

    private func askPersonalVoice() {
        AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
            Task { @MainActor in
                personalStatus = status
                VoiceCatalog.shared.load(force: true)
            }
        }
    }

    private func row(_ v: VoiceInfo) -> some View {
        let on = !usesSystem && v.id == chosenId
        return HStack(spacing: 8) {
            Button {
                model.updatePrefs {
                    if language == .english {
                        $0.englishVoiceId = v.id
                        if let a = Accent(locale: v.language) { $0.accent = a }
                    } else {
                        $0.russianVoiceId = v.id
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    RadioDot(on: on)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(v.name).font(WPFont.nunito(16, .heavy))
                        Text(v.regionTitle).font(WPFont.nunito(13)).foregroundStyle(on ? Palette.inkSoft : Palette.muted)
                    }
                    Spacer()
                }
                .foregroundStyle(on ? Palette.ink : Palette.text)
                .padding(.leading, 14)
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(on ? .isSelected : [])
            ListenButton(label: "Послушать голос \(v.name)") {
                Speech.shared.speak(language.sample, voiceId: v.id, language: v.language)
            }
            .padding(.trailing, 6)
        }
        .background(on ? Palette.teal : .clear)
    }
}

struct TopicsSettings: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left").font(.system(size: 17, weight: .bold))
                        Text("Настройки").font(WPFont.nunito(16, .heavy))
                    }
                    .foregroundStyle(Palette.text).frame(minHeight: 44)
                }
                .padding(.leading, -6)
                ScreenTitle(text: "Темы").padding(.top, 18)
                Text("С выбранных тем начинаются новые выражения. Остальные темы не закрываются.")
                    .font(WPFont.nunito(15)).foregroundStyle(Palette.muted).padding(.top, 6)
                TopicGrid(selected: Binding(get: { Set(model.prefs.topics) }, set: { s in
                    model.updatePrefs { p in p.topics = model.library.topics.filter { s.contains($0) } }
                }))
                .padding(.top, 18)
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 30)
        }
        .screenBackground()
        .statusBarBackdrop()
        .toolbar(.hidden, for: .navigationBar)
    }
}


struct ChoiceOption<Value: Hashable>: Identifiable {
    let value: Value
    let title: String
    var subtitle: String?
    var id: Value { value }
}

/// A setting with a few fixed values, opened as its own screen with a checkmark list,
/// the way iOS Settings shows Calendar → Default Calendar or the temperature unit.
struct ChoiceScreen<Value: Hashable>: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    var note: String?
    let options: [ChoiceOption<Value>]
    let selected: Value
    let onSelect: (Value) -> Void
    /// Optional speaker button on each row, for speeds and accents.
    var onPreview: ((Value) -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left").font(.system(size: 17, weight: .bold))
                        Text("Настройки").font(WPFont.nunito(16, .heavy))
                    }
                    .foregroundStyle(Palette.text).frame(minHeight: 44)
                }
                .padding(.leading, -6)
                ScreenTitle(text: title).padding(.top, 18)
                PaperBox(variant: 0) {
                    ForEach(Array(options.enumerated()), id: \.element.id) { i, o in
                        if i > 0 { DashedDivider() }
                        row(o)
                    }
                }
                .padding(.top, 18)
                if let note {
                    Text(note).font(WPFont.nunito(13)).foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4).padding(.top, 8)
                }
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 30)
        }
        .screenBackground()
        .statusBarBackdrop()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func row(_ o: ChoiceOption<Value>) -> some View {
        let on = o.value == selected
        return HStack(spacing: 8) {
            Button { onSelect(o.value) } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(o.title).font(WPFont.nunito(16, .heavy)).foregroundStyle(Palette.text)
                        if let s = o.subtitle { Text(s).font(WPFont.nunito(14)).foregroundStyle(Palette.muted) }
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Palette.blue)
                        .opacity(on ? 1 : 0)
                }
                .padding(.leading, 14)
                .padding(.trailing, onPreview == nil ? 14 : 0)
                .padding(.vertical, 6)
                .frame(minHeight: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(on ? .isSelected : [])
            if let onPreview {
                ListenButton(label: "Послушать: \(o.title)", size: 40) { onPreview(o.value) }
                    .padding(.trailing, 8)
            }
        }
    }
}
