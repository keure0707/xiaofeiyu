import Foundation

/// 这笔钱从哪个额度里出
enum Bucket: String, Codable, CaseIterable, Identifiable {
    case daily = "日常"
    case extra = "额外"
    var id: String { rawValue }

    var color: String {
        switch self {
        case .daily: return "brand"
        case .extra: return "gold"
        }
    }
}

/// 报销状态
enum ReimbStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "待报销"
    case arrived = "已到账"
    var id: String { rawValue }
}

struct Record: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    /// 正数是支出，负数是退款
    var amount: Double
    var date: Date
    var category: String
    var bucket: Bucket
    var merchant: String = ""
    var note: String = ""
    var isReimbursable: Bool = false
    var reimbStatus: ReimbStatus = .pending
    var reimbDest: String = ""

    var isRefund: Bool { amount < 0 }
    var absAmount: Double { abs(amount) }
}

enum Categories {
    static let daily: [String] = [
        "三餐", "日用品", "饮品", "通勤", "水电杂费", "通讯",
        "学习科研", "医疗", "日常打理", "衣物基础", "订阅工具", "其他"
    ]

    static let extra: [String] = [
        "聚餐应酬", "服饰鞋包", "数码硬件", "影音娱乐", "运动健身", "旅行",
        "出行", "人情礼物", "护肤美妆", "大件", "其他"
    ]

    static let all: [String] = {
        var seen = Set<String>()
        var out: [String] = []
        for name in daily + extra where !seen.contains(name) {
            seen.insert(name)
            out.append(name)
        }
        return out
    }()

    /// 分类默认归属哪一边；「其他」两边都有，默认日常
    static func defaultBucket(for name: String) -> Bucket {
        if daily.contains(name) { return .daily }
        return .extra
    }

    static let reimbDests: [String] = [
        "导师课题经费", "学院/学校", "会议主办方", "其他"
    ]

    /// 图标里显示的首字
    static func glyph(for name: String) -> String {
        String(name.prefix(1))
    }
}

enum Money {
    static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    /// 1234.5 -> "1,234.50"
    static func plain(_ value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "0.00"
    }

    /// 1234.5 -> "¥1,234.50"
    static func yuan(_ value: Double) -> String {
        "¥" + plain(value)
    }

    /// 支出显示负号，退款显示正号
    static func signed(_ value: Double) -> String {
        let prefix = value < 0 ? "+" : "−"
        return prefix + plain(abs(value))
    }
}

extension Date {
    var monthKey: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy-MM"
        return f.string(from: self)
    }

    var dayKey: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }

    var shortDay: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M 月 d 日"
        return f.string(from: self)
    }

    var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy 年 M 月"
        return f.string(from: self)
    }

    var timeText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "HH:mm"
        return f.string(from: self)
    }

    func addingMonths(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: n, to: self) ?? self
    }

    var startOfMonth: Date {
        let c = Calendar.current
        let comps = c.dateComponents([.year, .month], from: self)
        return c.date(from: comps) ?? self
    }
}
