import Foundation
import Combine

struct SettlePreview {
    var monthTitle: String = ""
    var dailySpent: Double = 0
    var extraSpent: Double = 0
    var dailyQuota: Double = 0
    var extraQuota: Double = 0
    var carryIn: Double = 0
    var dailyBalance: Double = 0
    var extraBalance: Double = 0
    var overspend: Double = 0
    var depositFromDaily: Double = 0
    var depositFromExtra: Double = 0
    var carryOut: Double = 0
    var savingsBefore: Double = 0
    var savingsAfter: Double = 0
    var penaltyToNextMonth: Double = 0

    var totalBalance: Double { dailyBalance + extraBalance }
    var hasOverspend: Bool { overspend > 0 }
}

final class AppStore: ObservableObject {

    @Published private(set) var records: [Record] = []
    @Published var dailyQuota: Double = 1800 { didSet { persist() } }
    @Published var extraQuota: Double = 500 { didSet { persist() } }

    @Published private(set) var carryExtra: Double = 0
    @Published private(set) var savings: Double = 0
    @Published private(set) var lastSettledMonth: String = ""
    @Published private(set) var penaltyMonth: String = ""
    @Published private(set) var penaltyAmount: Double = 0

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("xiaofeiyu.json")
    }

    private struct Snapshot: Codable {
        var records: [Record]
        var dailyQuota: Double
        var extraQuota: Double
        var carryExtra: Double
        var savings: Double
        var lastSettledMonth: String
        var penaltyMonth: String
        var penaltyAmount: Double
    }

    private var isLoading = true

    init() {
        load()
        isLoading = false
    }

    // MARK: - 持久化

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        guard let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        records = snap.records
        dailyQuota = snap.dailyQuota
        extraQuota = snap.extraQuota
        carryExtra = snap.carryExtra
        savings = snap.savings
        lastSettledMonth = snap.lastSettledMonth
        penaltyMonth = snap.penaltyMonth
        penaltyAmount = snap.penaltyAmount
    }

    func persist() {
        guard !isLoading else { return }
        let snap = Snapshot(
            records: records,
            dailyQuota: dailyQuota,
            extraQuota: extraQuota,
            carryExtra: carryExtra,
            savings: savings,
            lastSettledMonth: lastSettledMonth,
            penaltyMonth: penaltyMonth,
            penaltyAmount: penaltyAmount
        )
        guard let data = try? JSONEncoder().encode(snap) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - 记账

    func add(_ record: Record) {
        records.append(record)
        records.sort { $0.date > $1.date }
        persist()
    }

    func update(_ record: Record) {
        guard let idx = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[idx] = record
        records.sort { $0.date > $1.date }
        persist()
    }

    func delete(_ record: Record) {
        records.removeAll { $0.id == record.id }
        persist()
    }

    func records(in month: Date) -> [Record] {
        records
            .filter { $0.date.monthKey == month.monthKey }
            .sorted { $0.date > $1.date }
    }

    // MARK: - 额度

    func effectiveDailyQuota(_ month: Date) -> Double {
        month.monthKey == penaltyMonth ? max(0, dailyQuota - penaltyAmount) : dailyQuota
    }

    func spent(_ bucket: Bucket, in month: Date) -> Double {
        records
            .filter { $0.bucket == bucket && !$0.isReimbursable && $0.date.monthKey == month.monthKey }
            .reduce(0) { $0 + $1.amount }
    }

    func quotaBalance(_ bucket: Bucket, in month: Date) -> Double {
        switch bucket {
        case .daily:
            return effectiveDailyQuota(month) - spent(.daily, in: month)
        case .extra:
            let carry = month.monthKey == Date().monthKey ? carryExtra : 0
            return extraQuota + carry - spent(.extra, in: month)
        }
    }

    func availableExtra(_ month: Date) -> Double {
        let carry = month.monthKey == Date().monthKey ? carryExtra : 0
        return extraQuota + carry
    }

    // MARK: - 本月（界面用）

    var today: Date { Date() }

    var dailySpentThisMonth: Double { spent(.daily, in: today) }
    var extraSpentThisMonth: Double { spent(.extra, in: today) }
    var dailyRemaining: Double { quotaBalance(.daily, in: today) }
    var extraRemaining: Double { quotaBalance(.extra, in: today) }
    var totalRemaining: Double { dailyRemaining + extraRemaining }

    var daysLeftInMonth: Int {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: today) else { return 0 }
        let day = cal.component(.day, from: today)
        return max(0, range.count - day)
    }

    // MARK: - 报销

    var pendingReimburse: [Record] {
        records
            .filter { $0.isReimbursable && $0.reimbStatus == .pending }
            .sorted { $0.date > $1.date }
    }

    var arrivedReimburse: [Record] {
        records
            .filter { $0.isReimbursable && $0.reimbStatus == .arrived }
            .sorted { $0.date > $1.date }
    }

    var pendingReimburseTotal: Double {
        pendingReimburse.reduce(0) { $0 + $1.absAmount }
    }

    var arrivedReimburseTotal: Double {
        arrivedReimburse.reduce(0) { $0 + $1.absAmount }
    }

    func newReimburseThisMonth() -> Double {
        pendingReimburse
            .filter { $0.date.monthKey == today.monthKey }
            .reduce(0) { $0 + $1.absAmount }
    }

    func toggleReimburse(_ record: Record) {
        guard var r = records.first(where: { $0.id == record.id }) else { return }
        r.reimbStatus = (r.reimbStatus == .arrived) ? .pending : .arrived
        update(r)
    }

    // MARK: - 结算

    func previewSettle(month: Date, saveX: Double) -> SettlePreview {
        var p = SettlePreview()
        p.monthTitle = month.monthTitle
        p.dailyQuota = effectiveDailyQuota(month)
        p.extraQuota = extraQuota
        let isCurrent = month.monthKey == Date().monthKey
        p.carryIn = isCurrent ? carryExtra : 0

        p.dailySpent = spent(.daily, in: month)
        p.extraSpent = spent(.extra, in: month)
        p.dailyBalance = p.dailyQuota - p.dailySpent
        p.extraBalance = p.extraQuota + p.carryIn - p.extraSpent

        p.overspend = max(-p.dailyBalance, 0) + max(-p.extraBalance, 0)
        p.depositFromDaily = max(p.dailyBalance, 0)
        let usable = max(p.extraBalance, 0)
        let x = min(max(saveX, 0), usable)
        p.depositFromExtra = x
        p.carryOut = usable - x

        p.savingsBefore = savings
        let after = savings + p.depositFromDaily + p.depositFromExtra - p.overspend
        if after >= 0 {
            p.savingsAfter = after
            p.penaltyToNextMonth = 0
        } else {
            p.savingsAfter = 0
            p.penaltyToNextMonth = -after
        }
        return p
    }

    func settle(month: Date, saveX: Double) {
        let p = previewSettle(month: month, saveX: saveX)
        guard lastSettledMonth != month.monthKey else { return }

        carryExtra = p.carryOut
        savings = p.savingsAfter
        lastSettledMonth = month.monthKey

        if p.penaltyToNextMonth > 0 {
            penaltyMonth = month.addingMonths(1).monthKey
            penaltyAmount = p.penaltyToNextMonth
        } else if penaltyMonth == month.monthKey {
            penaltyMonth = ""
            penaltyAmount = 0
        }
        persist()
    }

    func isSettled(_ month: Date) -> Bool {
        lastSettledMonth == month.monthKey
    }

    /// 月底需要结算但还没结算的月份
    func unsettledMonth() -> Date? {
        let now = Date()
        let current = now.startOfMonth
        let previous = current.addingMonths(-1)
        if records.isEmpty { return nil }
        guard lastSettledMonth < previous.monthKey else { return nil }
        guard !records(in: previous).isEmpty else { return nil }
        return previous
    }

    // MARK: - 备份

    func exportText() -> String {
        var lines = ["日期,金额,分类,大类,商家,备注,可报销,报销状态,报销去向"]
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        for r in records.sorted(by: { $0.date < $1.date }) {
            let fields = [
                f.string(from: r.date),
                String(format: "%.2f", r.amount),
                r.category,
                r.bucket.rawValue,
                r.merchant,
                r.note,
                r.isReimbursable ? "是" : "否",
                r.isReimbursable ? r.reimbStatus.rawValue : "",
                r.reimbDest
            ]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    func deposit(_ amount: Double) {
        guard amount > 0 else { return }
        savings += amount
        persist()
    }

    func resetAll() {
        records = []
        carryExtra = 0
        savings = 0
        lastSettledMonth = ""
        penaltyMonth = ""
        penaltyAmount = 0
        persist()
    }
}
