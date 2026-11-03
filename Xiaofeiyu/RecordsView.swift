import SwiftUI

struct DayGroup: Identifiable {
    var id: String
    var title: String
    var records: [Record]
}

struct RecordsView: View {
    @EnvironmentObject var store: AppStore

    @State private var month: Date = Date().startOfMonth
    @State private var filter: RecordFilter = .all
    @State private var editing: Record?

    enum RecordFilter: String, CaseIterable, Identifiable {
        case all = "全部"
        case daily = "日常"
        case extra = "额外"
        case reimb = "可报销"
        var id: String { rawValue }
    }

    private var filtered: [Record] {
        let all = store.records(in: month)
        switch filter {
        case .all: return all
        case .daily: return all.filter { $0.bucket == .daily && !$0.isReimbursable }
        case .extra: return all.filter { $0.bucket == .extra && !$0.isReimbursable }
        case .reimb: return all.filter { $0.isReimbursable }
        }
    }

    private var groups: [DayGroup] {
        let sorted = filtered.sorted { $0.date > $1.date }
        var order: [String] = []
        var map: [String: [Record]] = [:]
        for r in sorted {
            let key = r.date.dayKey
            if map[key] == nil {
                map[key] = []
                order.append(key)
            }
            map[key]?.append(r)
        }
        return order.map { key in
            let recs = map[key] ?? []
            let date = recs.first?.date ?? Date()
            return DayGroup(id: key, title: dayTitle(date), records: recs)
        }
    }

    private func dayTitle(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "今天 · " + date.shortDay }
        if Calendar.current.isDateInYesterday(date) { return "昨天 · " + date.shortDay }
        return date.shortDay
    }

    private var monthSpent: Double {
        filtered.filter { !$0.isReimbursable }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthBar
                filterBar
                list
            }
            .background(Color.appBg.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(item: $editing) { rec in
            AddRecordView(editing: rec).environmentObject(store)
        }
    }

    private var monthBar: some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 14) {
                Button {
                    month = month.addingMonths(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.muted)
                }
                Text(month.monthTitle)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color.ink)
                Button {
                    month = month.addingMonths(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.muted)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(filtered.count) 笔")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.faint)
                Text("已花 \(Money.yuan(monthSpent))")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.faint)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RecordFilter.allCases) { f in
                    Button {
                        filter = f
                    } label: {
                        Text(f.rawValue)
                            .font(.system(size: 13, weight: filter == f ? .semibold : .regular))
                            .foregroundStyle(filter == f ? Color(hex: 0x2F5FA8) : Color(hex: 0x4A5666))
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(filter == f ? Color(hex: 0xE3EFFC) : Color(hex: 0xF1F6FD))
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                            .overlay(
                                RoundedRectangle(cornerRadius: 11)
                                    .stroke(filter == f ? Color.brandLight : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private var list: some View {
        List {
            ForEach(groups) { group in
                Section {
                    ForEach(group.records) { rec in
                        HStack(spacing: 0) {
                            RecordRow(record: rec)
                        }
                        .background(Color.white)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.white)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.delete(rec)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            editing = rec
                        }
                    }
                } header: {
                    Text(group.title)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.faint)
                }
            }

            if groups.isEmpty {
                Text("这个月还没有记录")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.faint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
    }
}
