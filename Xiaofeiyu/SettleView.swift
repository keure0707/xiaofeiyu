import SwiftUI

struct SettleView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let month: Date

    @State private var saveX: Double = 0
    @State private var didLoadDefault = false

    private var preview: SettlePreview {
        store.previewSettle(month: month, saveX: saveX)
    }

    private var maxExtraDeposit: Double {
        max(preview.extraBalance, 0)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        hero
                        breakdown
                        savingsPreview
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                confirmBar
            }
            .background(Color.appBg.ignoresSafeArea())
            .navigationTitle("\(month.monthTitle)结算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("稍后再说") { dismiss() }
                }
            }
            .onAppear {
                if !didLoadDefault {
                    saveX = 0
                    didLoadDefault = true
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("结余")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.muted)
                Spacer()
                if preview.hasOverspend {
                    Text("本月超支 \(Money.yuan(preview.overspend))")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.warn)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: 0xFDEBEA))
                        .clipShape(Capsule())
                } else {
                    Text("本月无超支")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.ok)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.okPale)
                        .clipShape(Capsule())
                }
            }
            Text(Money.yuan(preview.totalBalance))
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(Color.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
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
    }

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("日常")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("额度 \(Money.plain(preview.dailyQuota)) · 每月重置")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.faint)
            }
            line("本月已花", Money.yuan(preview.dailySpent))
            line("结余，全部存入存款", Money.yuan(max(preview.dailyBalance, 0)), highlight: preview.dailyBalance >= 0)

            Divider().background(Color.line)

            HStack {
                Text("额外")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("本期可用 \(Money.plain(preview.extraQuota + preview.carryIn))")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.faint)
            }
            line("本月已花", Money.yuan(preview.extraSpent))
            line("结余，你来分配", Money.yuan(max(preview.extraBalance, 0)), highlight: preview.extraBalance >= 0)

            if maxExtraDeposit > 0 {
                allocBar
                stepper
            }
        }
        .card()
    }

    private var allocBar: some View {
        GeometryReader { geo in
            let ratio = maxExtraDeposit > 0 ? min(1, max(0, saveX / maxExtraDeposit)) : 0
            HStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x8FB6E8), Color.brand],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * ratio)
                Rectangle()
                    .fill(Color(hex: 0xF6E3C2))
            }
        }
        .frame(height: 34)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.top, 4)
    }

    private var stepper: some View {
        HStack(spacing: 10) {
            Text("存入存款")
                .font(.system(size: 11.5))
                .foregroundStyle(Color.faint)

            Button {
                saveX = max(0, saveX - 10)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.brand)
                    .frame(width: 28, height: 28)
                    .background(Color(hex: 0xF4F9FF))
                    .overlay(Circle().stroke(Color(hex: 0xC9DCF5), lineWidth: 1.2))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Text(Money.plain(saveX))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.ink)
                .frame(minWidth: 62)

            Button {
                saveX = min(maxExtraDeposit, saveX + 10)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.brand)
                    .frame(width: 28, height: 28)
                    .background(Color(hex: 0xF4F9FF))
                    .overlay(Circle().stroke(Color(hex: 0xC9DCF5), lineWidth: 1.2))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("结转下月 \(Money.yuan(preview.carryOut))")
                .font(.system(size: 11.5))
                .foregroundStyle(Color(hex: 0xC08A2A))
        }
    }

    private func line(_ title: String, _ value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12.5))
                .foregroundStyle(Color(hex: 0x6E7A8C))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(highlight ? Color.ok : Color.ink)
        }
    }

    private var savingsPreview: some View {
        VStack(spacing: 8) {
            line("原存款", Money.yuan(preview.savingsBefore))
            line("＋ 日常结余", Money.yuan(preview.depositFromDaily))
            line("＋ 额外存入", Money.yuan(preview.depositFromExtra))
            if preview.overspend > 0 {
                line("− 超支扣除", Money.yuan(preview.overspend), highlight: false)
            }
            Divider().background(Color.line)
            HStack {
                Text("结算后存款")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text(Money.yuan(preview.savingsAfter))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.ink)
            }
            if preview.penaltyToNextMonth > 0 {
                Text("存款不足，下月日常额度将减少 \(Money.yuan(preview.penaltyToNextMonth))")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.warn)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .card()
    }

    private var confirmBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color(hex: 0xEAF0F9))
            Button {
                store.settle(month: month, saveX: saveX)
                dismiss()
            } label: {
                Text("确认结算")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0x7FAEE5), Color.brand],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 18)
        }
        .background(Color.appBg)
    }
}
