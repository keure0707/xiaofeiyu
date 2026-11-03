import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var showReset = false
    @State private var dailyText: String = ""
    @State private var extraText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    quotaCard
                    dataCard
                    aboutCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.appBg.ignoresSafeArea())
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        commitQuotas()
                        dismiss()
                    }
                }
            }
            .onAppear {
                dailyText = Money.plain(store.dailyQuota)
                extraText = Money.plain(store.extraQuota)
            }
            .confirmationDialog("确定清空所有数据？", isPresented: $showReset, titleVisibility: .visible) {
                Button("清空并重置", role: .destructive) {
                    store.resetAll()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("账目、存款、结转都会清空，无法撤销")
            }
        }
    }

    private var quotaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每月额度")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(Color.ink)

            HStack {
                Text("日常")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.muted)
                Spacer()
                TextField("1800", text: $dailyText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: 120)
            }

            Divider().background(Color.line)

            HStack {
                Text("额外")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.muted)
                Spacer()
                TextField("500", text: $extraText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: 120)
            }

            Text("改完立即生效，当月可用金额会按新额度重算。日常每月 1 日重置，额外可结转。")
                .font(.system(size: 11))
                .foregroundStyle(Color.faint)
                .padding(.top, 2)

            Button {
                commitQuotas()
            } label: {
                Text("保存额度")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .card()
    }

    private func commitQuotas() {
        if let d = Double(dailyText.replacingOccurrences(of: ",", with: ".")), d >= 0 {
            store.dailyQuota = d
        }
        if let e = Double(extraText.replacingOccurrences(of: ",", with: ".")), e >= 0 {
            store.extraQuota = e
        }
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("数据")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(Color.ink)

            ShareLink(item: store.exportText()) {
                HStack {
                    Text("导出 CSV")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.ink)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.brand)
                }
            }

            Divider().background(Color.line)

            Button {
                showReset = true
            } label: {
                HStack {
                    Text("清空所有数据")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.warn)
                    Spacer()
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.warn)
                }
            }
            .buttonStyle(.plain)
        }
        .card()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("小肥鱼")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("1.0")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.faint)
            }
            Text("数据全部存在本机，不上传任何服务器。")
                .font(.system(size: 11))
                .foregroundStyle(Color.faint)
            Text("侧载版本每 7 天需要续签一次，重装前记得先导出备份。")
                .font(.system(size: 11))
                .foregroundStyle(Color.faint)
        }
        .card()
    }
}
