import SwiftUI

enum CatalogFilter: Hashable {
    case group(String)
    case topic(String)
    case favorites

    var title: String {
        switch self {
        case .group(let g): g
        case .topic(let t): t
        case .favorites: "Избранное"
        }
    }
}

struct CatalogView: View {
    @Environment(AppModel.self) private var model
    @State private var query = ""
    @State private var level: Level?
    @State private var path: [CatalogFilter] = []
    @State private var openItem: Collocation?
    @State private var levelInitialized = false

    private var levelItems: [Collocation] {
        model.library.items.filter { level == nil || $0.level == level }
    }

    private var searchResults: [Collocation] {
        let q = AnswerChecker.normalize(query)
        guard !q.isEmpty else { return [] }
        return model.library.items.filter {
            (level == nil || $0.level == level) &&
            ($0.phrase.lowercased().contains(q) || $0.translationRu.lowercased().contains(q) || $0.meaningEn.lowercased().contains(q))
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Eyebrow(text: "Каталог")
                        ScreenTitle(text: "Все выражения")
                    }
                    searchField
                    levelPicker
                    topicChips

                    if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text(searchResults.isEmpty ? "Ничего не нашлось" : "Найдено: \(searchResults.count)")
                            .font(WPFont.nunito(14, .bold)).foregroundStyle(Palette.muted)
                        LazyVStack(spacing: 0) {
                            ForEach(searchResults) { item in
                                ExpressionRow(item: item) { openItem = item }
                            }
                        }
                    } else {
                        HStack(alignment: .firstTextBaseline) {
                            Text("По группе").font(WPFont.rubik(19, false)).foregroundStyle(Palette.text)
                            Spacer()
                            Text(level == nil ? "все уровни" : (level == model.prefs.level ? "\(level!.rawValue) · ваш уровень" : level!.rawValue))
                                .font(WPFont.nunito(13)).foregroundStyle(Palette.muted)
                        }
                        .padding(.top, 2)
                        ForEach(Array(groups.enumerated()), id: \.element) { i, group in
                            NavigationLink(value: CatalogFilter.group(group)) {
                                GroupCard(title: group, items: levelItems.filter { $0.structureSet == group }, index: i)
                            }
                            .buttonStyle(PressStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.immediately)
            .screenBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: CatalogFilter.self) { filter in
                GroupDetailView(filter: filter, level: level)
            }
            .sheet(item: $openItem) { item in
                ExpressionSheet(item: item)
            }
        }
        .onChange(of: model.pendingCatalog) { _, f in openPending(f) }
        .onAppear {
            openPending(model.pendingCatalog)
            if !levelInitialized { level = model.prefs.level; levelInitialized = true }
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-wpGroup") { path = [.group("Make")] }
            #endif
        }
    }

    private func openPending(_ f: CatalogFilter?) {
        guard let f else { return }
        level = model.prefs.level
        levelInitialized = true
        path = [f]
        model.pendingCatalog = nil
    }

    private var groups: [String] {
        model.library.structureSets.filter { g in levelItems.contains { $0.structureSet == g } }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.system(size: 17, weight: .bold)).foregroundStyle(Palette.text)
            TextField("", text: $query, prompt: Text("Поиск: decision, перерыв…").foregroundStyle(Palette.muted))
                .font(WPFont.nunito(16))
                .foregroundStyle(Palette.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.muted) }
                    .accessibilityLabel("Очистить поиск")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Palette.paper, in: Radii.shape(0))
        .boxOutline(Radii.shape(0))
    }

    private var levelPicker: some View {
        HStack(spacing: 0) {
            ForEach(Array(([nil] + Level.allCases.map { Optional($0) }).enumerated()), id: \.offset) { i, l in
                let on = level == l
                Button { level = l } label: {
                    Text(l?.rawValue ?? "Все")
                        .font(WPFont.rubik(16, false))
                        .foregroundStyle(on ? Palette.primaryText : Palette.text)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(on ? Palette.primaryFill : .clear)
                        .overlay(alignment: .leading) {
                            if i > 0 { Rectangle().fill(Palette.outline).frame(width: 2) }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
                .accessibilityLabel(l.map { "Уровень \($0.rawValue)" } ?? "Все уровни")
            }
        }
        .background(Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .boxOutline(RoundedRectangle(cornerRadius: 10))
    }

    private var topicChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                NavigationLink(value: CatalogFilter.favorites) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill").font(.system(size: 13))
                        Text("Избранное")
                    }
                    .chip(fill: Palette.yellow, heavy: true)
                }
                ForEach(model.library.topics, id: \.self) { t in
                    NavigationLink(value: CatalogFilter.topic(t)) {
                        Text(t).chip(fill: Palette.paper, heavy: false)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
        .padding(.horizontal, -20)
        .buttonStyle(.plain)
    }
}

private extension View {
    func chip(fill: Color, heavy: Bool) -> some View {
        self
            .font(WPFont.nunito(14, heavy ? .heavy : .bold))
            .foregroundStyle(fill == Palette.paper ? Palette.text : Palette.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 40)
            .background(fill, in: Capsule())
            .modifier(BoxOutline(shape: Capsule(), color: fill == Palette.paper ? Palette.outline : Palette.ink,
                                 light: 2, dark: fill == Palette.paper ? 1.5 : 0))
    }
}

struct GroupCard: View {
    @Environment(AppModel.self) private var model
    let title: String
    let items: [Collocation]
    let index: Int

    var body: some View {
        let counts = model.counts(for: items.map(\.id))
        PatternCard(style: .of(index), variant: index, blobStart: 0.64) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(WPFont.rubik(title.count > 12 ? 21 : 28))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(items.prefix(2).map(\.phrase).joined(separator: ", ") + "…")
                    .font(WPFont.nunito(14))
                    .foregroundStyle(Color(hex: 0x3D3730))
                    .lineLimit(1)
                HStack(spacing: 10) {
                    Text("\(started(counts)) / \(items.count)").font(WPFont.nunito(13, .heavy)).monospacedDigit()
                    StateBar(counts: counts, total: items.count)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .heavy))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(hex: 0xFFFBF1)))
                        .overlay(Circle().stroke(Palette.ink, lineWidth: 2.5))
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(width: 250, alignment: .leading)
        }
        .frame(minHeight: 124)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibility(counts))
        .accessibilityAddTraits(.isButton)
    }

    private func started(_ c: [LearningState: Int]) -> Int { items.count - (c[.new] ?? 0) }

    private func accessibility(_ c: [LearningState: Int]) -> String {
        "\(title): \(items.count) \(Plural.expressions(items.count)), освоено \(c[.mastered] ?? 0), повторяется \(c[.reviewing] ?? 0), изучается \(c[.learning] ?? 0)"
    }
}

struct ExpressionRow: View {
    @Environment(AppModel.self) private var model
    let item: Collocation
    let open: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button { model.speakEnglish(item.phrase) } label: {
                Image(systemName: "speaker.wave.2").font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.text)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Послушать: \(item.phrase)")
            .padding(.leading, -8)
            Button(action: open) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.phrase).font(WPFont.rubik(17, false)).foregroundStyle(Palette.text)
                        Text(model.prefs.showTranslation ? item.translationRu : item.meaningEn)
                            .font(WPFont.nunito(14)).foregroundStyle(Palette.muted).lineLimit(1)
                    }
                    Spacer(minLength: 6)
                    if model.isFavorite(item.id) {
                        Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(Palette.muted)
                    }
                    StatePill(state: model.state(item.id))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: 58)
        .overlay(alignment: .bottom) {
            DashedDivider.Line().stroke(Palette.divider, style: StrokeStyle(lineWidth: 2, dash: [6, 5])).frame(height: 2)
        }
    }
}

struct GroupDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let filter: CatalogFilter
    /// The level filter the user came from, if any.
    let level: Level?
    @State private var picked: Level?
    @State private var openItem: Collocation?
    @State private var overLimit = false

    private var current: Level { picked ?? level ?? model.prefs.level }

    private var inFilter: [Collocation] {
        model.library.items.filter { item in
            let inFilter: Bool
            switch filter {
            case .group(let g): inFilter = item.structureSet == g
            case .topic(let t): inFilter = item.topics.contains(t)
            case .favorites: inFilter = model.isFavorite(item.id)
            }
            return inFilter
        }
    }

    private var items: [Collocation] {
        filter == .favorites ? inFilter : inFilter.filter { $0.level == current }
    }

    private var style: PatternStyle {
        switch filter {
        case .group(let g): .of(model.library.structureSets.firstIndex(of: g) ?? 0)
        case .topic(let t): .of((model.library.topics.firstIndex(of: t) ?? 0) + 1)
        case .favorites: .dots
        }
    }

    var body: some View {
        let ids = items.map(\.id)
        let counts = model.counts(for: ids)
        let newCount = counts[.new] ?? 0
        let startedCount = ids.count - newCount
        VStack(spacing: 0) {
            header(counts: counts, total: ids.count)
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: 6) {
                ForEach([LearningState.mastered, .reviewing, .learning, .new], id: \.self) { s in
                    LegendDot(state: s, count: counts[s] ?? 0)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .frame(maxWidth: .infinity, alignment: .leading)

            if items.isEmpty {
                Spacer()
                Text(filter == .favorites ? "Отмечайте выражения звёздочкой, и они появятся здесь." : "На этом уровне выражений нет.")
                    .font(WPFont.nunito(16)).foregroundStyle(Palette.muted).multilineTextAlignment(.center).padding(30)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in ExpressionRow(item: item) { openItem = item } }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }

        }
        #if DEBUG
        .onAppear { if ProcessInfo.processInfo.arguments.contains("-wpLimit") { overLimit = true } }
        #endif
        .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 4) {
                    if newCount > 0 {
                        PrimaryButton(title: "Учить эту тему · \(min(newCount, max(model.prefs.newPerDay, 5))) \(Plural.form(newCount, "новое", "новых", "новых"))", height: 56) {
                            if model.remainingNewToday() == 0 { overLimit = true } else { learn() }
                        }
                    }
                    if startedCount > 0 {
                        LinkButton(title: "Потренироваться · \(startedCount) \(Plural.form(startedCount, "начатое", "начатых", "начатых"))") {
                            model.startPractice(title: filter.title, ids: ids)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Palette.background)
        }
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $openItem) { ExpressionSheet(item: $0) }
        .sheet(isPresented: $overLimit) {
            LimitSheet(started: model.startedTodayIds.count) {
                overLimit = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { learn() }
            }
        }
    }

    private func learn() {
        model.startLearning(title: filter.title, ids: items.map(\.id))
    }

    /// A2 / B1 / B2 / C1 inside the topic; levels without phrases here are faded and can't be tapped.
    private var levelSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(Array(Level.allCases.enumerated()), id: \.element) { i, l in
                let on = l == current
                let empty = !inFilter.contains { $0.level == l }
                Button { picked = l } label: {
                    Text(l.rawValue)
                        .font(WPFont.rubik(15, false))
                        .foregroundStyle(on ? Color(hex: 0xF4EDDC) : Palette.ink)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(on ? Palette.ink : .clear)
                        .overlay(alignment: .leading) {
                            if i > 0 { Rectangle().fill(Palette.ink).frame(width: 2) }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(empty)
                .opacity(empty ? 0.35 : 1)
                .accessibilityLabel("Уровень \(l.rawValue)")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .frame(width: 196)
        .background(Color(hex: 0xFFFBF1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.ink, lineWidth: 2.5))
    }

    private func header(counts: [LearningState: Int], total: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { dismiss() } label: {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .bold))
                    Text("Каталог").font(WPFont.nunito(16, .heavy))
                }
                .foregroundStyle(Palette.ink)
                .frame(minHeight: 44)
            }
            .padding(.leading, -6)
            VStack(alignment: .leading, spacing: 4) {
                Text(filter.title).font(WPFont.rubik(filter.title.count > 14 ? 30 : 44)).lineLimit(2).minimumScaleFactor(0.7)
                if filter == .favorites {
                    Text("\(total) \(Plural.expressions(total))")
                        .font(WPFont.nunito(15, .bold)).foregroundStyle(Color(hex: 0x2F2A24))
                } else {
                    levelSwitcher.padding(.top, 6)
                    Text("\(total) \(Plural.expressions(total)) уровня \(current.rawValue)")
                        .font(WPFont.nunito(15, .bold)).foregroundStyle(Color(hex: 0x2F2A24))
                        .padding(.top, 4)
                }
                StateBar(counts: counts, total: total).frame(width: 196).padding(.top, 8)
            }
            .frame(width: 240, alignment: .leading)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 20)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                style.base
                PatternFill(style: style).clipShape(SideBlob(start: 0.7, variant: 1))
            }
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .bottom) { HeaderRule() }
        }
    }
}

struct ExpressionSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let item: Collocation

    var body: some View {
        let c = model.card(item.id)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Tag(text: "\(item.level.rawValue) · \(item.structureSet)", fill: Palette.lilac)
                    Spacer()
                    Button { model.toggleFavorite(item.id) } label: {
                        Image(systemName: model.isFavorite(item.id) ? "star.fill" : "star")
                            .font(.system(size: 20, weight: .semibold)).foregroundStyle(Palette.text).frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(model.isFavorite(item.id) ? "Убрать из избранного" : "Добавить в избранное")
                }
                PatternCard(style: .waves, variant: 1, blobStart: 0.78) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.phrase).font(WPFont.rubik(32)).fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 10) {
                            ListenPill(title: "Слушать") { model.speakEnglish(item.phrase) }
                            SlowPill(rate: model.prefs.slowRate) { model.speakEnglish(item.phrase, slow: true) }
                        }
                    }
                    .padding(20)
                    .frame(width: 270, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(WPFont.handText("Значение")).font(WPFont.hand(21)).foregroundStyle(Palette.muted)
                    Text(item.meaningEn).font(WPFont.nunito(18, .bold)).foregroundStyle(Palette.text)
                    if model.prefs.showTranslation {
                        Text(item.translationRu).font(WPFont.nunito(16)).foregroundStyle(Palette.secondary)
                    }
                }
                if let ex = item.example {
                    ExampleBox(en: ex.en, ru: model.prefs.showTranslation ? ex.ru : nil, highlight: item.phrase) { model.speakEnglish(ex.en) }
                }
                ExampleBox(en: item.gap.fullSentence, ru: model.prefs.showTranslation ? item.gap.translationRu : nil, highlight: item.gap.answer, title: "Ещё пример") {
                    model.speakEnglish(item.gap.fullSentence)
                }
                HStack {
                    StatePill(state: c.state)
                    if let due = c.dueDay {
                        Text("следующая проверка \(StudyDay.relative(due, from: model.today))").font(WPFont.nunito(14)).foregroundStyle(Palette.muted)
                    }
                }
                Button(model.isHidden(item.id) ? "Вернуть в занятия" : "Не показывать в занятиях") { model.toggleHidden(item.id) }
                    .font(WPFont.nunito(15, .bold)).foregroundStyle(Palette.muted).frame(minHeight: 44)
            }
            .padding(20)
        }
        .screenBackground()
        .presentationDragIndicator(.visible)
    }
}

struct ListenPill: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.2.fill").font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: 0xF4EDDC))
                    .frame(width: 30, height: 30).background(Circle().fill(Palette.ink))
                Text(title).font(WPFont.nunito(15, .heavy))
            }
            .foregroundStyle(Palette.ink)
            .padding(.leading, 6).padding(.trailing, 14)
            .frame(minHeight: 44)
            .background(Color(hex: 0xFFFBF1), in: Capsule())
            .overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5))
        }
        .buttonStyle(PressStyle())
    }
}

struct SlowPill: View {
    let rate: Double
    var height: CGFloat = 44
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(String(format: "%.1f×", rate))
                .font(WPFont.nunito(15, .heavy))
                .foregroundStyle(Palette.ink)
                .frame(minWidth: 64, minHeight: height)
                .background(Color(hex: 0xFFFBF1), in: Capsule())
                .overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5))
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel("Слушать медленно")
    }
}

/// English sentence with the expression in bold, optional translation and a listen button.
struct ExampleBox: View {
    let en: String
    let ru: String?
    var highlight: String?
    var title = "Пример"
    let listen: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(WPFont.handText(title)).font(WPFont.hand(21)).foregroundStyle(Palette.muted)
                Text(Self.bolded(en, highlight)).font(WPFont.nunito(17)).foregroundStyle(Palette.text)
                if let ru { Text(ru).font(WPFont.nunito(15)).foregroundStyle(Palette.muted) }
            }
            Spacer(minLength: 0)
            ListenButton(label: "Послушать пример", action: listen)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Palette.paper, in: Radii.shape(1))
        .boxOutline(Radii.shape(1))
    }

    static func bolded(_ text: String, _ part: String?) -> AttributedString {
        var a = AttributedString(text)
        guard let part, let range = a.range(of: part, options: .caseInsensitive) else { return a }
        a[range].font = WPFont.nunito(17, .heavy)
        return a
    }
}

/// Line under the topic header: ink in light mode, none in dark mode.
struct HeaderRule: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Rectangle().fill(Palette.ink).frame(height: scheme == .dark ? 0 : 2.5)
    }
}

/// Bottom sheet shown when today's new phrases are already started. Solid surface in both themes.
struct LimitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    let started: Int
    let learnAnyway: () -> Void
    @State private var height: CGFloat = 360

    var body: some View {
        let dark = scheme == .dark
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(dark ? Color(hex: 0x4A423A) : Color(hex: 0xCFC4AE))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            Eyebrow(text: "Новые на сегодня").padding(.top, 18)
            Text("На сегодня новых достаточно")
                .font(WPFont.rubik(26))
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
            Text("Вы уже начали \(started) \(Plural.form(started, "новую фразу", "новые фразы", "новых фраз")). Рекомендуется не больше 10 в день, чтобы повторения не накапливались.")
                .font(WPFont.nunito(17))
                .lineSpacing(17 * 0.45 - 6)
                .foregroundStyle(dark ? Color(hex: 0xC9BFAE) : Color(hex: 0x4A433B))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
            PrimaryButton(title: "Продолжить завтра") { dismiss() }
                .padding(.top, 22)
            Button(action: learnAnyway) {
                Text("Всё равно учить")
                    .font(WPFont.nunito(16, .bold))
                    .underline()
                    .foregroundStyle(Palette.text)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .fixedSize(horizontal: false, vertical: true)
        .background(GeometryReader { g in Color.clear.onAppear { height = g.size.height } })
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(height)])
        .presentationCornerRadius(28)
        .presentationBackground {
            (dark ? Color(hex: 0x2A2521) : Color(hex: 0xFFFBF1))
                .overlay(alignment: .top) {
                    UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                        .stroke(dark ? Color(hex: 0x3A332D) : Palette.ink, lineWidth: dark ? 1 : 2.5)
                        .frame(height: 60)
                        .mask(Rectangle().frame(height: 30).frame(maxHeight: .infinity, alignment: .top))
                }
        }
    }
}
