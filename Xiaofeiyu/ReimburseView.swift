import SwiftUI

struct ReimburseView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    summary

                    if store.pendingReimburse.isEmpty && store.arrivedReimburse.isEmpty {
                        Text("还没有报销记录。记一笔时打开「可报销」即可。")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.faint)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    }

                    if !store.pendingReimburse.isEmpty {
                        section(title: "待报销", items: store.pendingReimburse)
                    }
                    if !store.arrivedReimburse.isEmpty {
                        section(title: "已到账", items: store.arrivedReimburse)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.appBg.ignoresSafeArea())
            .navigationTitle("报销待办")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private var summary: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("待报销")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.muted)
                Text(Money.yuan(store.pendingReimburseTotal))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(store.pendingReimburse.count) 笔未完成")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.faint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("已到账")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.muted)
                Text(Money.yuan(store.arrivedReimburseTotal))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(store.arrivedReimburse.count) 笔已完成")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.faint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func section(title: String, items: [Record]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(Color.faint)
                .padding(.horizontal, 6)

            VStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { idx in
                    row(items[idx])
                    if idx < items.count - 1 {
                        Divider().background(Color.line).padding(.leading, 52)
                    }
                }
            }
            .card(padding: 0)
        }
    }

    private func row(_ rec: Record) -> some View {
        let arrived = rec.reimbStatus == .arrived
        return HStack(spacing: 12) {
            Button {
                store.toggleReimburse(rec)
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color(hex: 0xC9DCF5), lineWidth: 1.7)
                        .frame(width: 22, height: 22)
                    if arrived {
                        Circle().fill(Color.brand).frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(rec.merchant.isEmpty ? rec.category : rec.merchant)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(arrived ? Color(hex: 0xB4BDCA) : Color.ink)
                    .strikethrough(arrived)
                Text("\(rec.reimbDest.isEmpty ? "未填去向" : rec.reimbDest) · \(rec.date.shortDay) · \(rec.reimbStatus.rawValue)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(arrived ? Color(hex: 0xC7CEDA) : Color.faint)
            }

            Spacer()

            Text(Money.yuan(rec.absAmount))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(arrived ? Color(hex: 0xB4BDCA) : Color.ink)
                .strikethrough(arrived)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
