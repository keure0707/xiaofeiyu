import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: AppStore

    private struct MonthStat: Identifiable {
        var id: String
        var title: String
        var daily: Double
        var extra: Double
        var total: Double { daily + extra }
    }

    private var stats: [MonthStat] {
        let now = Date().startOfMonth
        return (0..<6).reversed().map { offset in
            let m = now.addingMonths(-offset)
            let d = store.spent(.daily, in: m)
            let e = store.spent(.extra, in: m)
            return MonthStat(
                id: m.monthKey,
                title: String(m.monthKey.suffix(2)) + " 月",
                daily: d,
                extra: e
            )
        }
    }

    private var maxTotal: Double {
        max(stats.map { $0.total }.max() ?? 1, 1)
    }

    private var thisMonth: MonthStat {
        stats.last ?? MonthStat(id: "", title: "", daily: 0, extra: 0)
    }

    private struct CatStat: Identifiable {
        var id: String { name }
        var name: String
        var total: Double
    }

    private var byCategory: [CatStat] {
        let recs = store.records(in: Date()).filter { !$0.isReimbursable && $0.amount > 0 }
        var map: [String: Double] = [:]
        for r in recs {
            map[r.category, default: 0] += r.amount
        }
        return map
            .sorted { $0.value > $1.value }
            .map { CatStat(name: $0.key, total: $0.value) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    trendCard
                    categoryCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.appBg.ignoresSafeArea())
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("近 6 个月")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("本月 \(Money.yuan(thisMonth.total))")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.faint)
            }

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(stats) { s in
                    VStack(spacing: 6) {
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.brand)
                                .frame(width: 14, height: max(2, 120 * s.daily / maxTotal))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gold)
                                .frame(width: 14, height: max(2, 120 * s.extra / maxTotal))
                        }
                        .frame(height: 122, alignment: .bottom)

                        Text(s.title)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.faint)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            HStack(spacing: 16) {
                legend(color: Color.brand, text: "日常")
                legend(color: Color.gold, text: "额外")
            }
        }
        .card()
    }

    private func legend(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(Color.faint)
        }
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本月分类")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(Color.ink)

            if byCategory.isEmpty {
                Text("还没有数据")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.faint)
                    .padding(.vertical, 10)
            } else {
                let top = byCategory.first?.total ?? 1
                ForEach(Array(byCategory.prefix(8))) { item in
                    VStack(spacing: 6) {
                        HStack {
                            Text(item.name)
                                .font(.system(size: 12.5))
                                .foregroundStyle(Color.ink)
                            Spacer()
                            Text(Money.yuan(item.total))
                                .font(.system(size: 12))
                                .foregroundStyle(Color.muted)
                        }
                        ThinBar(progress: item.total / max(top, 1), tint: Color.brandLight, track: Color(hex: 0xEFF4FB))
                    }
                }
            }
        }
        .card()
    }
}
