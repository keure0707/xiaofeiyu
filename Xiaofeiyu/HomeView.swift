import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AppStore

    @State private var showAdd = false
    @State private var showReimburse = false
    @State private var showSettings = false
    @State private var showSettle = false
    @State private var editing: Record?
    @State private var showDeposit = false
    @State private var depositText = ""

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    header
                    settleBanner
                    heroCard
                    depositCard
                    reimburseCard
                    recentSection
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0x7FAEE5), Color.brand],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.brand.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .padding(.trailing, 22)
            .padding(.bottom, 18)
        }
        .sheet(isPresented: $showAdd) {
            AddRecordView(editing: nil)
                .environmentObject(store)
        }
        .sheet(item: $editing) { rec in
            AddRecordView(editing: rec)
                .environmentObject(store)
        }
        .sheet(isPresented: $showReimburse) {
            ReimburseView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showSettle) {
            SettleView(month: store.unsettledMonth() ?? Date().addingMonths(-1).startOfMonth)
                .environmentObject(store)
        }
    }

    // MARK: - 头部

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("小肥鱼")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.ink)
                Text("攒钱变胖")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.muted)
            }
            Spacer()
            HStack(spacing: 12) {
                Text(Date().shortDay)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.muted)
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.muted)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 2)
    }

    // MARK: - 概览

    @ViewBuilder
    private var settleBanner: some View {
        if let m = store.unsettledMonth() {
            Button {
                showSettle = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.gold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(m.monthTitle)还没结算")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.ink)
                        Text("点这里把结余存进存款")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.faint)
                    }
                    Spacer()
                    Text("去结算")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.brand)
                }
                .padding(14)
                .card(padding: 0)
            }
            .buttonStyle(.plain)
        }
    }

    private var dailyQuotaNow: Double { store.effectiveDailyQuota(Date()) }

    private var dailyProgress: Double {
        guard dailyQuotaNow > 0 else { return 0 }
        return store.dailySpentThisMonth / dailyQuotaNow
    }

    private var extraProgress: Double {
        let total = store.availableExtra(Date())
        guard total > 0 else { return 0 }
        return store.extraSpentThisMonth / total
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("本月合计还能花")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.muted)
                Spacer()
                Text("还剩 \(store.daysLeftInMonth) 天")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.brand)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xE7F0FC))
                    .clipShape(Capsule())
            }

            Text(Money.yuan(store.totalRemaining))
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Color.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.top, 4)

            HStack(alignment: .top, spacing: 16) {
                bucketColumn(
                    title: "日常剩余",
                    value: store.dailyRemaining,
                    progress: dailyProgress,
                    tint: Color.brand,
                    foot: "已花 \(Money.plain(store.dailySpentThisMonth)) / \(Money.plain(dailyQuotaNow))"
                )
                bucketColumn(
                    title: "额外剩余",
                    value: store.extraRemaining,
                    progress: extraProgress,
                    tint: Color.gold,
                    foot: "已花 \(Money.plain(store.extraSpentThisMonth)) / \(Money.plain(store.availableExtra(Date())))"
                )
            }
            .padding(.top, 16)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: 0xEDF4FE)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color(hex: 0x4A6EA8).opacity(0.07), radius: 10, x: 0, y: 5)
    }

    private func bucketColumn(title: String, value: Double, progress: Double, tint: Color, foot: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color(hex: 0x6E7A8C))
                Spacer()
                Text(Money.yuan(value))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            ThinBar(progress: progress, tint: tint)
            Text(foot)
                .font(.system(size: 10.5))
                .foregroundStyle(Color.faint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    // MARK: - 存款

    private var depositCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("存款")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.muted)
                Text(Money.yuan(store.savings))
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(Color.ink)
            }
            Spacer()
            Button {
                depositText = ""
                showDeposit = true
            } label: {
                Text("+ 存入")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color.brand)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color(hex: 0xF4F9FF))
                    .overlay(
                        Capsule().stroke(Color(hex: 0xC9DCF5), lineWidth: 1.2)
                    )
                    .clipShape(Capsule())
            }
        }
        .card()
        .alert("存入存款", isPresented: $showDeposit) {
            TextField("金额", text: $depositText)
                .keyboardType(.decimalPad)
            Button("取消", role: .cancel) { depositText = "" }
            Button("存入") {
                if let value = Double(depositText), value > 0 {
                    store.deposit(value)
                }
                depositText = ""
            }
        } message: {
            Text("助研费、奖学金这类，记进来当缓冲")
        }
    }

    // MARK: - 报销

    private var reimburseCard: some View {
        Button {
            showReimburse = true
        } label: {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("待报销")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.muted)
                    Text(Money.yuan(store.pendingReimburseTotal))
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(Color.gold)
                    Text("\(store.pendingReimburse.count) 笔待办 · 点击查看")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.brandLight)
                }
                Spacer()
                HStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("本月新增")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.faint)
                        Text(Money.yuan(store.newReimburseThisMonth()))
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x4A5666))
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("已到账")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.faint)
                        Text(Money.yuan(store.arrivedReimburseTotal))
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x4A5666))
                    }
                }
            }
            .card()
        }
        .buttonStyle(.plain)
    }

    // MARK: - 最近

    private var recent: [Record] {
        Array(store.records(in: Date()).prefix(3))
    }

    private var recentSection: some View {
        let items = recent
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("最近")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("全部 ›")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.brandLight)
            }
            .padding(.horizontal, 8)

            VStack(spacing: 0) {
                if items.isEmpty {
                    Text("还没有记录，点右下角 + 记一笔")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.faint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                } else {
                    ForEach(items.indices, id: \.self) { idx in
                        Button {
                            editing = items[idx]
                        } label: {
                            RecordRow(record: items[idx])
                        }
                        .buttonStyle(.plain)

                        if idx < items.count - 1 {
                            Divider()
                                .background(Color.line)
                                .padding(.leading, 66)
                        }
                    }
                }
            }
            .card(padding: 0)
        }
    }
}

struct RecordRow: View {
    var record: Record

    private var tint: Color { record.bucket == .extra ? Color.gold : Color.brand }
    private var pale: Color { record.bucket == .extra ? Color.goldPale : Color.brandPale }

    var body: some View {
        HStack(spacing: 12) {
            GlyphBadge(text: Categories.glyph(for: record.category), tint: tint, pale: pale)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(record.merchant.isEmpty ? record.category : record.merchant)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                    if record.isReimbursable {
                        Text("可报销")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.gold)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.goldPale)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                Text("\(record.category) · \(record.bucket.rawValue) · \(subtitleTime)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.faint)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(Money.signed(record.amount))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(record.isRefund ? Color.ok : tint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var subtitleTime: String {
        if Calendar.current.isDateInToday(record.date) {
            return "今天 \(record.date.timeText)"
        } else if Calendar.current.isDateInYesterday(record.date) {
            return "昨天 \(record.date.timeText)"
        } else {
            return record.date.shortDay
        }
    }
}
