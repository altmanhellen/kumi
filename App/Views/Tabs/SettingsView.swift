import AuthenticationServices
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var shareURL: URL?
    @State private var importing = false
    @State private var message: String?
    @State private var confirmReset = false
    @State private var confirmSignOut = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left").font(.system(size: 17, weight: .bold))
                        Text("Прогресс").font(WPFont.nunito(16, .heavy))
                    }
                    .foregroundStyle(Palette.text)
                    .frame(minHeight: 44)
                }
                .padding(.leading, -6)
                ScreenTitle(text: "Настройки").padding(.top, 18)

                section("Озвучка")
                PaperBox(variant: 0) {
                    NavigationLink { VoicePicker(language: .english) } label: {
                        SettingsRow(title: "Английский", subtitle: "выражения и примеры", value: model.englishVoiceName)
                    }
                    DashedDivider()
                    NavigationLink { VoicePicker(language: .russian) } label: {
                        SettingsRow(title: "Русский", subtitle: "переводы", value: model.russianVoiceName)
                    }
                    DashedDivider()
                    Menu {
                        ForEach([0.5, 0.6, 0.7, 0.8], id: \.self) { r in
                            Button(String(format: "%.1f×", r)) { model.updatePrefs { $0.slowRate = r } }
                        }
                    } label: {
                        SettingsRow(title: "Медленное воспроизведение", value: String(format: "%.1f×", model.prefs.slowRate))
                    }
                }
                note("Используются только голоса, встроенные в iOS. Новые голоса скачиваются в Настройках iPhone: Универсальный доступ → Чтение вслух (в более ранних версиях iOS — «Устный контент») → Голоса.")

                section("Обучение")
                PaperBox(variant: 1) {
                    Menu {
                        ForEach(Level.allCases) { l in
                            Button("\(l.rawValue) · \(l.name)") { model.updatePrefs { $0.level = l } }
                        }
                    } label: {
                        SettingsRow(title: "Уровень", value: model.prefs.level.rawValue)
                    }
                    DashedDivider()
                    NavigationLink { TopicsSettings() } label: {
                        SettingsRow(title: "Темы", value: model.prefs.topics.isEmpty ? "все" : "\(model.prefs.topics.count)")
                    }
                    DashedDivider()
                    Menu {
                        ForEach([5, 10, 15, 20], id: \.self) { n in
                            Button("\(n)") { model.updatePrefs { $0.newPerDay = n } }
                        }
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
                    Menu {
                        ForEach([0.85, 0.88, 0.9, 0.92, 0.95], id: \.self) { r in
                            Button("\(Int(r * 100))%") { model.updatePrefs { $0.desiredRetention = r } }
                        }
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
                    Menu {
                        ForEach(AppTheme.allCases) { t in
                            Button(t.title) { model.updatePrefs { $0.theme = t } }
                        }
                    } label: {
                        SettingsRow(title: "Тема", value: model.prefs.theme.title)
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
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .padding(12)
                    }
                }
                note(model.file.account == nil
                     ? "Аккаунт необязателен: без него всё работает на этом iPhone."
                     : "Синхронизация с сервером Word Partners включится, когда подключим сервер. Сейчас прогресс хранится на этом iPhone и попадает в его резервную копию iCloud.")

                section("Данные")
                PaperBox(variant: 5) {
                    Button { confirmReset = true } label: {
                        Text("Сбросить прогресс")
                            .font(WPFont.nunito(16, .heavy))
                            .foregroundStyle(Color(hex: 0xB23A24))
                            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                            .padding(.horizontal, 14)
                            .contentShape(Rectangle())
                    }
                }
                note("Контент \(model.library.version) · \(model.library.items.count) выражений")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .screenBackground()
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
                if !ok { message = "Уведомления выключены в Настройках iPhone для Word Partners." }
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
        Text(title).font(WPFont.rubik(18, false)).foregroundStyle(Palette.text).padding(.top, 20).padding(.bottom, 8)
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
    let language: VoiceLanguage
    var onboarding = false

    private var voices: [VoiceInfo] { Speech.voices(language: language.prefix) }

    private var selected: String? {
        let id = language == .english ? model.prefs.englishVoiceId : model.prefs.russianVoiceId
        return id ?? Speech.voice(id: nil, fallbackLanguage: language == .english ? model.prefs.accent.locale : "ru-RU")?.identifier
    }

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
            Text("Голоса iOS на этом iPhone. Нажмите на динамик, чтобы послушать.")
                .font(WPFont.nunito(15)).foregroundStyle(Palette.muted).padding(.top, 6)
            ScrollView {
                PaperBox(variant: 0) {
                    ForEach(Array(voices.enumerated()), id: \.element.id) { i, v in
                        if i > 0 {
                            DashedDivider.Line().stroke(Palette.divider, style: StrokeStyle(lineWidth: 2, dash: [6, 5])).frame(height: 2)
                        }
                        row(v)
                    }
                    if voices.isEmpty {
                        Text("На этом устройстве нет голосов для этого языка.").font(WPFont.nunito(15)).padding(16)
                    }
                }
                .padding(.top, 14)
                Text("Другие голоса можно скачать в Настройках iPhone: Универсальный доступ → Чтение вслух (в более ранних версиях iOS — «Устный контент») → Голоса → \(language.settingsName).")
                    .font(WPFont.nunito(13)).foregroundStyle(Palette.muted).padding(.top, 10).padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func row(_ v: VoiceInfo) -> some View {
        let on = v.id == selected
        return HStack(spacing: 8) {
            Button {
                model.updatePrefs {
                    if language == .english {
                        $0.englishVoiceId = v.id
                        $0.accent = v.language == "en-US" ? .american : .british
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
        .toolbar(.hidden, for: .navigationBar)
    }
}
