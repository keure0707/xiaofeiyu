import SwiftUI

struct AddRecordView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let editing: Record?

    @State private var amount: String
    @State private var date: Date
    @State private var category: String
    @State private var bucket: Bucket
    @State private var merchant: String
    @State private var note: String
    @State private var isReimb: Bool
    @State private var dest: String
    @State private var isRefund: Bool

    @FocusState private var amountFocused: Bool

    init(editing: Record?) {
        self.editing = editing
        _amount = State(initialValue: editing.map { String(format: "%.2f", abs($0.amount)) } ?? "")
        _date = State(initialValue: editing?.date ?? Date())
        _category = State(initialValue: editing?.category ?? "三餐")
        _bucket = State(initialValue: editing?.bucket ?? .daily)
        _merchant = State(initialValue: editing?.merchant ?? "")
        _note = State(initialValue: editing?.note ?? "")
        _isReimb = State(initialValue: editing?.isReimbursable ?? false)
        _dest = State(initialValue: editing?.reimbDest ?? Categories.reimbDests[0])
        _isRefund = State(initialValue: (editing?.amount ?? 0) < 0)
    }

    private var parsedAmount: Double {
        Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var canSave: Bool { parsedAmount > 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    amountBlock
                    detailBlock
                    categoryBlock
                    bucketBlock
                    reimbBlock
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.appBg)
            .navigationTitle(editing == nil ? "记一笔" : "改一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if editing == nil { amountFocused = true }
            }
        }
    }

    // MARK: - 金额

    private var amountBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("金额")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.muted)
                Spacer()
                Toggle("退款", isOn: $isRefund)
                    .labelsHidden()
                    .scaleEffect(0.8)
                Text("这是退款")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.faint)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("¥")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x4A5666))
                TextField("0.00", text: $amount)
                    .font(.system(size: 36, weight: .bold))
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
                    .foregroundStyle(isRefund ? Color.ok : Color.ink)
            }
        }
        .card()
    }

    // MARK: - 明细

    private var detailBlock: some View {
        VStack(spacing: 0) {
            HStack {
                Text("时间")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.muted)
                Spacer()
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }
            .padding(.vertical, 10)

            Divider().background(Color.line)

            HStack {
                Text("商家")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.muted)
                Spacer()
                TextField("选填", text: $merchant)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 13))
            }
            .padding(.vertical, 10)

            Divider().background(Color.line)

            HStack {
                Text("备注")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.muted)
                Spacer()
                TextField("选填", text: $note)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 13))
            }
            .padding(.vertical, 10)
        }
        .card()
    }

    // MARK: - 分类

    private var categoryBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("分类")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.muted)
                Spacer()
                Text("本月「\(category)」已花 \(Money.yuan(spentOnCategory))")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Color.faint)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 8)], spacing: 8) {
                ForEach(Categories.all, id: \.self) { name in
                    Button {
                        category = name
                        bucket = Categories.defaultBucket(for: name)
                    } label: {
                        Text(name)
                            .font(.system(size: 13, weight: category == name ? .semibold : .regular))
                            .foregroundStyle(category == name ? Color(hex: 0x2F5FA8) : Color(hex: 0x4A5666))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(category == name ? Color(hex: 0xE3EFFC) : Color(hex: 0xF1F6FD))
                            .overlay(
                                RoundedRectangle(cornerRadius: 11)
                                    .stroke(category == name ? Color.brandLight : Color.clear, lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .card()
    }

    private var spentOnCategory: Double {
        store.records(in: Date())
            .filter { $0.category == category && !$0.isReimbursable }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - 额度

    private var bucketBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("计入哪个额度")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.muted)
                Spacer()
                Text("随分类自动预填")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Color.faint)
            }

            HStack(spacing: 4) {
                ForEach(Bucket.allCases) { b in
                    Button {
                        bucket = b
                    } label: {
                        Text(b.rawValue)
                            .font(.system(size: 13.5, weight: bucket == b ? .semibold : .regular))
                            .foregroundStyle(bucket == b ? Color(hex: 0x2F5FA8) : Color(hex: 0x7C8798))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(bucket == b ? Color.white : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color(hex: 0xEFF4FB))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .card()
    }

    // MARK: - 报销

    private var reimbBlock: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $isReimb) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("可报销")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Text("不计入任何额度，进「报销」待办")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.faint)
                }
            }
            .tint(Color.brand)
            .padding(.vertical, 8)

            if isReimb {
                Divider().background(Color.line)
                HStack {
                    Text("去向")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.muted)
                    Spacer()
                    Picker("去向", selection: $dest) {
                        ForEach(Categories.reimbDests, id: \.self) { d in
                            Text(d).tag(d)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.brand)
                }
                .padding(.vertical, 6)
            }
        }
        .card()
    }

    // MARK: - 保存

    private func save() {
        guard parsedAmount > 0 else { return }
        let value = isRefund ? -parsedAmount : parsedAmount

        if var old = editing {
            old.amount = value
            old.date = date
            old.category = category
            old.bucket = bucket
            old.merchant = merchant
            old.note = note
            old.isReimbursable = isReimb
            old.reimbDest = isReimb ? dest : ""
            store.update(old)
        } else {
            let record = Record(
                amount: value,
                date: date,
                category: category,
                bucket: bucket,
                merchant: merchant,
                note: note,
                isReimbursable: isReimb,
                reimbStatus: .pending,
                reimbDest: isReimb ? dest : ""
            )
            store.add(record)
        }
        dismiss()
    }
}
