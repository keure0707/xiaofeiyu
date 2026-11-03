# 小肥鱼

个人的 iPhone 记账 App。截图记账、日常/额外双额度、月底结算、报销待办。
数据全部存在本机，不联网、不上架。

---

## 现在这一版有什么

- 首页：本月合计还能花、日常/额外两条进度、存款、报销待办、最近记录
- 记账：手动记一笔，金额、时间、商家、分类、日常/额外、可报销、退款
- 记录：按月切换、按日期分组、筛选、左滑删除、点开修改
- 报销：勾选即划线，记录保留，可撤销
- 结算：日常结余自动入存款，额外结余用加减按钮分配「存多少 / 结转多少」，存款不足时自动扣下月日常额度
- 统计：近 6 个月趋势、本月分类占比
- 设置：调额度、导出 CSV、清空数据

**还没有的**：截图识别（OCR）、敲背面唤起。这两块需要额外的系统权限和 App Intents，等这一版装到你手机上确认能跑，再接着加。

---

## 目录结构

```
xiaofeiyu/
├─ project.yml                  XcodeGen 工程描述（不手写 .xcodeproj）
├─ Info.plist                   由 XcodeGen 生成
├─ Xiaofeiyu/
│  ├─ XiaofeiyuApp.swift        入口 + 三个标签页
│  ├─ Models.swift              数据模型、分类表、金额格式化
│  ├─ Store.swift               全部业务逻辑：记账、额度、结算、报销
│  ├─ Theme.swift               配色和通用组件
│  ├─ HomeView.swift            首页
│  ├─ AddRecordView.swift       记一笔 / 改一笔
│  ├─ RecordsView.swift         记录列表
│  ├─ ReimburseView.swift       报销待办
│  ├─ SettleView.swift          月度结算
│  ├─ StatsView.swift           统计
│  ├─ SettingsView.swift        设置
│  └─ Assets.xcassets/          图标（浅蓝底那张）
└─ .github/workflows/build.yml  云端编译，产出 .ipa
```

所有账目存在 `Documents/xiaofeiyu.json`，纯本地，删 App 就没了。

---

## 装到手机上：四步

### 第 1 步：把代码放到 GitHub

1. 注册 / 登录 GitHub
2. 新建仓库，名字随意（比如 `xiaofeiyu`），**建议选 Public**——私有仓库跑 macOS 构建会消耗配额，公开仓库免费且不限量
3. 进入仓库，点 **Add file → Upload files**，把 `xiaofeiyu` 文件夹里的**所有内容**拖进去（注意：是文件夹里面的东西，不要多套一层）
4. 提交

### 第 2 步：让 GitHub 编译

1. 仓库顶部点 **Actions**
2. 左边选 **Build IPA**，右边点 **Run workflow**
3. 等大约 3–5 分钟，变成绿色勾
4. 点进这次运行，页面底部 **Artifacts** 下载 `Xiaofeiyu-ipa.zip`，解压得到 `Xiaofeiyu.ipa`

> 如果红了，点开红色那一步，把报错信息发我，我改代码。

### 第 3 步：装到 iPhone（Windows）

1. 装 **iTunes**（必须去苹果官网下，不要用 Microsoft Store 版）
2. 下载 **Sideloadly**（sideloadly.io），装好
3. iPhone 用数据线连电脑，解锁并点「信任此电脑」
4. 打开 Sideloadly：
   - IPA 文件选你解压出来的 `Xiaofeiyu.ipa`
   - Apple ID 填你的（建议单独注册一个小号，别用日常 iCloud 账号）
   - 点 **Start**，中途会要你输入密码
5. 手机上会出现「小肥鱼」图标

### 第 4 步：信任证书

手机 **设置 → 通用 → VPN 与设备管理 → 开发者 App → 你的 Apple ID → 信任**

然后就能打开了。

---

## 每 7 天要续签一次

免费证书只有 7 天有效期。到期后点图标会闪退，这时候：

- 重复第 3 步，用同一个 Apple ID 重新装一次，**数据不会丢**（覆盖安装，同 bundle id）
- 或者装 **AltStore**，电脑开着的时候能在后台自动续签，基本无感

免费账号限制：同时最多 3 个自签 App。

**重要**：重装前先在 App 里「设置 → 导出 CSV」备一份，别赌。

---

## 设计文档

需求全文在 `记账App-需求文档-v1.1.docx`，界面稿在 `ui/` 目录。

---

## 下一步计划

1. **先确认这一版能装能跑**（最重要，构建流程不通后面都是空谈）
2. 接 **Vision 文字识别**：读截图里的金额、时间、商家
3. 接 **快捷指令 + 敲背面**：敲两下背面直接把最新截图送进来
4. 分类智能推荐 + 商家记忆
