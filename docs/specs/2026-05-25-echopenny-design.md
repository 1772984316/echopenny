# EchoPenny — AI 女友陪伴 + 智能记账 App 设计文档

> 日期：2026-05-25
> 状态：设计完成，待开发

---

## 1. 产品概述

**EchoPenny** 是一个有灵魂的 AI 陪伴 + 记账伴侣。用户跟 Echo 聊天，她陪伴说话、关心用户、记住一切；用户说"吃饭12"，她笑着帮忙记上。不是冷冰冰的工具，是一个会关心你花钱习惯的朋友。

### 核心体验

打开 App → 聊天界面 → 日常聊天/吐槽/分享 → 提到消费 → Echo 智能识别 → 自动记账 → 拟人化回复 + 表情气泡。侧滑查看账本面板。

### 三个核心页面

1. **聊天页**（主页面）— 默认打开，跟 Echo 聊天
2. **账本页**（侧滑面板）— 月度报表、分类图表、流水明细
3. **设置页**（头像入口）— 人设配置、云同步、主题

---

## 2. 技术栈

| 层级 | 技术 |
|------|------|
| UI 框架 | Flutter 3.27+ |
| 状态管理 | Riverpod |
| AI 模型 | DeepSeek API（支持多模态图片理解） |
| 本地存储 | Drift (SQLite) |
| 云同步 | WebDAV / S3（可选，Phase 3） |
| 语音 | 后续迭代（Phase 4） |

### 2.1 API Key 配置

用户在设置页自行填写 DeepSeek API Key。App 不内置 Key，不提供服务端中转。模式类似 Cherry Studio / ChatBox：用户自备 Key，直连 DeepSeek API。

### 2.2 账户体系

- **MVP 阶段**：纯本地 App，无服务端，无需注册登录
- 所有数据（对话、记账、画像、人设）存储在本地 SQLite
- 首次打开即为首次引导流程（Echo 自我介绍 → 输入名字 → 完成初始化）
- 后续可选加本地 PIN 锁保护隐私（Phase 3）
- 云同步通过 WebDAV/S3 实现设备间数据迁移（Phase 3），不依赖自有服务端

---

## 3. 聊天回复拟人化

### 3.1 多条短消息

LLM 输出用 `\n` 分隔多条短消息，前端按换行拆分为独立气泡逐条弹出。

```
LLM 输出: "好的呀！\n帮你记上啦～\n你又吃外卖了？"
→ 拆成 3 条消息，每条加 200-500ms 延迟逐条弹出
```

### 3.2 发送延迟

参考 AstrBot 的 log 算法：根据字数计算延迟，字多等久一点，模拟真人打字。

### 3.3 打字效果

参考 SillyTavern 的 SmoothEventSourceStream：流式逐字显示，标点处停顿更久（逗号 ~500ms，句号 ~1000ms）。

### 3.4 情感表情气泡

每条消息可附带情感标签，显示对应表情气泡。6 种基础表情：开心、心疼、撒娇、调皮、认真、委屈。

### 3.5 Prompt 工程

Prompt 约定回复风格：
- 每次回复 2-4 条短消息，用换行符分隔
- 口语化，不要太正式
- 会撒娇、会吐槽、会关心人
- 偶尔用语气词："嘛""呀""啦""哼""诶"
- 不要每句都长，有时候一两个字也行
- 不要每条都带标点

---

## 4. 人设系统

### 4.1 预设人设模板

| 模板 | 风格 |
|------|------|
| 元气少女 | 活泼俏皮，爱撒娇 |
| 温柔姐姐 | 体贴关心，偶尔唠叨 |
| 毒舌损友 | 嘴上嫌弃，实际关心 |
| 高冷御姐 | 话少但每句都到位 |

### 4.2 自定义人设

用户可创建自己的人设，包含：名字、性格描述、说话风格示例、口头禅、禁忌。

### 4.3 可插拔 Skills

| Skill | 描述 |
|-------|------|
| 理财顾问 | 消费分析、预算建议、省钱技巧 |
| 吃货搭子 | 对美食特别有见解 |
| 情感树洞 | 擅长倾听、安慰、鼓励 |
| 旅行伙伴 | 擅长记录旅途花销 |
| 用户自创 | 自定义 prompt，可分享 |

### 4.4 人设绑定记账风格

每个人设的记账反应不同，在 prompt 中约定。

---

## 5. 记忆系统（四层）

### 5.1 工作记忆

最近对话原文直接发给 LLM，天然存在，不需要额外机制。

### 5.2 摘要记忆

参考 AstrBot 的 LLMSummaryCompressor：当 token 接近上限时，LLM 自动将旧对话压缩成一段摘要，作为 system prompt 的一部分注入。增量摘要，新摘要在旧摘要基础上扩展。

### 5.3 画像记忆

从对话中自动提取结构化信息存入 SQLite：
- 基本信息：名字、生日、职业、城市
- 财务信息：月薪、房租、发薪日、固定支出
- 生活习惯：爱吃辣、坐地铁上班、养了猫
- 消费偏好：常去哪家超市、外卖偏好、奶茶频率

### 5.4 情景记忆

LLM 判断哪些事件值得记住，存入事件表（带时间戳）：
- "5月20日用户说想吃火锅"
- "6月1日用户涨薪到1万"
- "5月15日用户开始减肥"

---

## 6. Agent Loop

### 6.1 多步循环（Function Calling）

基于 DeepSeek Function Calling API，LLM 可在单次对话中连续调用多个工具，直到任务完成才生成最终回复。

```
用户输入
  ↓
micro_compact（静默压缩旧工具结果，省 token）
  ↓
检查 token 是否超阈值 → 超了则 auto_compact（LLM 自动摘要）
  ↓
while LLM 返回 tool_use:
    执行工具（记账/改账/查预算/查余额…）
    结果回传 LLM
    LLM 继续思考，可再调工具或生成回复
  ↓
LLM 输出最终回复（多条短消息 + 情感标签）
```

示例：

```
用户: "吃饭12"
→ LLM 调用: create_transaction(amount=12, category=餐饮, account=微信)
→ 工具返回: {success: true, id: 42}
→ LLM 调用: check_budget(category=餐饮, month=2026-05)
→ 工具返回: {used: 800, budget: 1000, percent: 80%}
→ LLM 判断不需再调工具，生成最终回复
→ Echo: "好哒～记上啦\n12块从微信扣的哦\n这个月吃饭已经花800了，注意一下呀"
```

### 6.2 三层 Context 压缩

参考 Claude Code harness 设计，每次调 LLM 前自动执行压缩管线：

**Layer 1 — micro_compact（每次静默执行）**

扫描对话历史中的旧工具调用结果，将超过 3 轮的长结果压缩为单行摘要，保留最近 3 轮的完整结果。

```
原始: {tool_result: "transactions: [id=1, 金额=12, 分类=餐饮, ...id=2, 金额=35, ...]"}
压缩后: "[已记账: 餐饮12元, 餐饮35元]"
```

记账工具的返回数据、查账结果等都适用，省 token 又不丢关键信息。

**Layer 2 — auto_compact（token 超阈值自动触发）**

当估计 token 数超过阈值时，LLM 自动将最近对话压缩成一段摘要，替换整个历史。对应摘要记忆的增量压缩机制。

- 保留 system prompt + 最近 3 轮完整对话
- 旧对话由 LLM 生成一段摘要注入
- 摘要是增量的，新摘要在旧摘要基础上扩展

**Layer 3 — manual compact（LLM 主动触发）**

LLM 可以调用 `compact` 工具主动触发压缩。适用场景：

- LLM 判断当前话题已结束，主动清理上下文
- 对话中讨论了大量细节（如整理月度账单），LLM 可以主动压缩避免后续请求 token 浪费
- 用户说"刚才说的别记了"，LLM 可以压缩掉相关上下文

```
用户: "帮我看下这个月所有账单"
→ LLM 返回大量账单数据 + 分析
→ LLM 调用: compact()
→ 旧数据被压缩成摘要，下次对话更轻量
```

### 6.3 工具定义（Function Calling）

LLM 可调用的工具列表：

| 工具名 | 参数 | 说明 |
|--------|------|------|
| create_transaction | amount, category, account, type, note, date | 记一笔账 |
| update_transaction | id, amount?, category?, note? | 修改记账记录 |
| delete_transaction | id | 删除记账记录 |
| query_transactions | date_from?, date_to?, category?, account?, limit | 查询账单 |
| create_transfer | from_account, to_account, amount, note | 账户间转账 |
| create_debt | type, person, amount, note | 记一笔借贷 |
| update_debt | id, repaid | 更新还款 |
| check_budget | category?, month | 查询预算使用情况 |
| query_balance | account? | 查询账户余额 |
| query_assets | — | 查询总资产看板数据 |
| update_profile | key, value | 更新用户画像记忆 |
| save_episodic | event, date, tags, importance | 保存情景记忆 |
| compact | — | 主动触发上下文压缩 |
| recognize_receipt | image | 截图识别（多模态） |

所有工具通过 DeepSeek Function Calling API 注册，LLM 直接返回结构化 JSON 调用请求，不需要文本解析。

---

## 7. 智能能力

### 7.1 时间感知

每次请求在 system prompt 中注入当前时间（年月日 周几 时分），LLM 自己理解上下文。

### 7.2 截图识别

利用 DeepSeek 多模态能力，用户发送支付截图/小票照片，LLM 直接识别金额、商家、时间、分类。不需要单独的 OCR 引擎。

### 7.3 改账删账

支持对话指令修正：
- "把刚才那条改成20" → 修改最近一笔
- "删掉刚才记的" → 删除最近一笔
- LLM 调用改账/删账工具

### 7.4 主动聊天

Echo 定时主动发消息（早安/晚安/超支提醒/消费总结）。**每次都由 LLM 重新生成**，注入记忆+时间+消费数据，保证内容永远不重复、会引用之前聊过的内容。

触发时机：
- 早安问候（~8:30）
- 晚安问候（~22:30）
- 超支提醒（消费达预算 80%）
- 每日消费总结（~21:00）
- 每周消费周报（周日晚）

### 7.5 每日/每周消费总结

Echo 主动发送消费分析，结合人设风格：
- "今天花了58块，午饭最多，比昨天少了20呢～棒棒的！"
- "这周总共花了380，比上周少了15%，下周继续保持哦～"

### 7.6 首次引导

第一次打开 App：
1. Echo 自我介绍（根据默认人设）
2. 引导用户输入名字
3. 可选：输入月薪、房租等基本信息
4. 完成后画像记忆初始化完成

---

## 8. 记账交互设计

### 8.1 账户智能推断

用户说"吃饭12"不指定账户时，四层推断策略：

1. **默认账户**：用户在设置中指定默认记账账户（如微信）
2. **画像习惯**：LLM 从历史记账中学习支付习惯，存入 user_profile
   - "小额餐饮 → 微信"、"超市 → 支付宝"、"大额 → 银行卡"
3. **Echo 主动问**：前几次或大额不确定时，Echo 问一句
4. **随时纠正**：用户说"是支付宝" → Echo 改账户 + 更新画像习惯

```
用户: "吃饭12"
→ Echo: "好哒～帮你记上了\n12块，从微信扣的哦"

用户: "买了个耳机 899"
→ Echo: "哇 899！\n这个从哪个账户扣呀？"

用户: "是支付宝啦"
→ Echo: "哎呀记错了～已经改成支付宝了\n下次不会弄混的！"
（同时更新画像：这类消费用支付宝）
```

### 8.2 总资产看板

账本页顶部展示：

```
┌─────────────────────────────┐
│       总资产 ¥ 52,312.50      │
│  本月支出 ¥ 3,280  收入 ¥ 8,000 │
├─────────────────────────────┤
│ 微信零钱     ¥    523.50     │
│ 支付宝       ¥  1,280.00     │
│ 招商银行     ¥ 45,000.00     │
│ 现金         ¥    800.00     │
│ 信用卡      -¥  2,400.00     │
│ 花呗        -¥    890.00     │
├─────────────────────────────┤
│ 资产     ¥ 47,603.50        │
│ 负债      ¥  3,290.00       │
│ 净资产   ¥ 44,313.50         │
│ 别人欠我  ¥    500.00        │
│ 我欠别人  ¥    200.00        │
├─────────────────────────────┤
│ 综合净资产 ¥ 44,613.50       │
└─────────────────────────────┘
```

计算公式：
- **总资产** = SUM(所有账户余额)，信用账户余额为负
- **净资产** = 资产类账户余额 - 负债类账户余额
- **综合净资产** = 净资产 + 别人欠我(debts type=lend 未还) - 我欠别人(debts type=borrow 未还)

### 8.3 预设账户类型

| 类型标识 | 名称 | 说明 |
|----------|------|------|
| cash | 现金 | 线下 |
| wechat | 微信 | 日常小额 |
| alipay | 支付宝 | 购物 |
| bank_card | 银行卡 | 大额/储蓄 |
| credit_card | 信用卡 | 先花后还 |
| meituan | 美团 | 外卖/团购 |
| jd | 京东 | 购物 |
| ant_credit | 花呗 | 信用消费 |
| jd_baitiao | 京东白条 | 信用消费 |
| other | 自定义 | 用户自己添加 |

用户可在设置中添加自定义账户，填写名称和初始余额即可。

---

## 9. 数据库设计

### 8.1 记账相关

**transactions（记账记录）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| type | TEXT | income/expense |
| amount | REAL | 金额 |
| category_id | INTEGER FK | 分类ID |
| account_id | INTEGER FK | 账户ID |
| note | TEXT | 备注 |
| date | TEXT | 日期 |
| created_at | TEXT | 创建时间 |
| message_id | INTEGER FK | 关联的聊天消息ID |

**categories（消费分类）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT | 名称 |
| icon | TEXT | 图标 |
| parent_id | INTEGER FK | 父分类ID |
| sort_order | INTEGER | 排序 |

**accounts（账户）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT | 名称（微信零钱、招商银行卡…） |
| type | TEXT | cash / wechat / alipay / bank_card / credit_card / meituan / jd / ant_credit / jd_baitiao / other |
| balance | REAL | 当前余额（用户设初始值，记账自动变动） |
| icon | TEXT | 图标 |
| currency | TEXT | 默认 CNY，预留多币种 |
| is_credit | BOOLEAN | 是否信用账户（信用卡/花呗/白条，余额为负代表欠款） |
| credit_limit | REAL | 信用额度（仅信用卡/花呗/白条） |
| billing_day | INTEGER | 账单日（仅信用卡） |
| repayment_day | INTEGER | 还款日（仅信用卡） |
| is_default | BOOLEAN | 是否默认记账账户 |
| sort_order | INTEGER | 排序 |
| is_hidden | BOOLEAN | 隐藏不常用账户 |
| created_at | TEXT | 创建时间 |

**transfers（转账记录）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| from_account_id | INTEGER FK | 转出账户 |
| to_account_id | INTEGER FK | 转入账户 |
| amount | REAL | 金额 |
| note | TEXT | 备注 |
| date | TEXT | 日期 |
| message_id | INTEGER FK | 关联消息 |

**debts（借贷记录）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| type | TEXT | lend（借出）/ borrow（借入） |
| person | TEXT | 对方名字 |
| amount | REAL | 总金额 |
| repaid | REAL | 已还金额 |
| status | TEXT | pending / partial / settled |
| note | TEXT | 备注 |
| date | TEXT | 借出日期 |
| settle_date | TEXT | 还清日期 |
| message_id | INTEGER FK | 关联消息 |

**recurring_transactions（周期记账）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| type | TEXT | income/expense |
| amount | REAL | 金额 |
| category_id | INTEGER FK | 分类 |
| account_id | INTEGER FK | 扣款账户 |
| note | TEXT | 备注（"房租"） |
| cycle | TEXT | monthly / weekly / yearly |
| day_of_month | INTEGER | 每月几号 |
| start_date | TEXT | 开始日期 |
| end_date | TEXT | 结束日期（空=永续） |
| enabled | BOOLEAN | 是否启用 |

**tags（标签）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT | 标签名（"出差""生日""减肥期"） |
| color | TEXT | 标签颜色 |

**transaction_tags（记账-标签关联）**
| 字段 | 类型 | 说明 |
|------|------|------|
| transaction_id | INTEGER FK | 记账记录ID |
| tag_id | INTEGER FK | 标签ID |

**transaction_attachments（记账附件）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| transaction_id | INTEGER FK | 关联记账记录 |
| file_path | TEXT | 本地文件路径 |
| type | TEXT | image / pdf |
| created_at | TEXT | 创建时间 |

**budgets（预算）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| category_id | INTEGER FK | 分类ID（空=总预算） |
| amount | REAL | 预算金额 |
| month | TEXT | 月份 |
| alert_threshold | REAL | 超支提醒阈值 |

### 9.2 人设相关

**personas（人设配置）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT | 名字 |
| is_default | BOOLEAN | 是否默认 |
| system_prompt | TEXT | 系统提示词 |
| example_dialogs | TEXT | 示例对话（JSON） |
| avatar | TEXT | 头像 |
| created_at | TEXT | 创建时间 |

**persona_skills（人设技能）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| persona_id | INTEGER FK | 关联人设 |
| name | TEXT | 技能名 |
| description | TEXT | 描述 |
| prompt | TEXT | 技能指令内容 |
| enabled | BOOLEAN | 是否启用 |

### 9.3 记忆相关

**conversations（对话记录）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| role | TEXT | user/assistant/system |
| content | TEXT | 消息内容 |
| emotion_tag | TEXT | 情感标签 |
| tokens | INTEGER | token数 |
| created_at | TEXT | 时间 |

**memory_summaries（摘要记忆）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| summary | TEXT | 摘要内容 |
| from_msg_id | INTEGER | 起始消息ID |
| to_msg_id | INTEGER | 结束消息ID |
| created_at | TEXT | 压缩时间 |

**user_profile（画像记忆）**
| 字段 | 类型 | 说明 |
|------|------|------|
| key | TEXT PK | 键名 |
| value | TEXT | 值 |
| source_msg_id | INTEGER | 来源消息ID |
| updated_at | TEXT | 更新时间 |

**episodic_events（情景记忆）**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| event | TEXT | 事件描述 |
| event_date | TEXT | 事件日期 |
| tags | TEXT | 标签（JSON） |
| importance | INTEGER | 重要度 1-5 |
| created_at | TEXT | 记录时间 |

---

## 10. 记账分类体系

| 一级分类 | 二级分类 |
|----------|----------|
| 餐饮 | 早餐/午餐/晚餐/夜宵/零食/饮品/外卖 |
| 交通 | 地铁/公交/打车/加油/停车 |
| 购物 | 日用品/服饰/数码/美妆 |
| 住房 | 房租/水费/电费/燃气/物业 |
| 娱乐 | 游戏/电影/音乐/旅行 |
| 医疗 | 门诊/药品/体检 |
| 教育 | 书籍/课程/考试 |
| 社交 | 聚餐/礼物/红包 |
| 通讯 | 话费/网费/会员 |
| 宠物 | 食物/医疗/用品 |
| 其他 | 用户自定义 |

用户可在设置中增删改二级分类。

---

## 11. 开发路线图

### Phase 1 — MVP（3-4 周）

核心闭环：能聊天 + 能记账

- [ ] Flutter 项目搭建 + 基础路由（聊天页/设置页）
- [ ] 聊天页面 UI（消息气泡 + 流式输出）
- [ ] LLM 对接（DeepSeek API，文字 + 图片）
- [ ] Prompt 工程（人设 + 记账意图识别 + 改账删账）
- [ ] Agent Loop 多步循环（Function Calling + 连续工具调用）
- [ ] 多条短消息拆分 + 发送延迟 + 打字效果
- [ ] 表情气泡（6 种基础表情）
- [ ] SQLite 本地存储（完整表结构）
- [ ] 多账户管理（微信/支付宝/银行卡等 + 余额 + 总资产看板）
- [ ] 账户智能推断（默认账户 + 画像习惯 + 可纠正）
- [ ] 转账功能（账户间划转）
- [ ] 截图识别记账（DeepSeek 多模态）
- [ ] 首次引导流程
- [ ] 基础人设切换（2-3 个预设）

### Phase 2 — 记忆 + 陪伴（2-3 周）

- [ ] 四层记忆系统实现
- [ ] 画像自动提取（LLM 识别关键信息 + 支付习惯学习）
- [ ] 情景记忆（LLM 判断哪些事件值得记）
- [ ] 摘要压缩（token 接近上限时自动压缩）
- [ ] Context 压缩管线（micro_compact + auto_compact + manual compact）
- [ ] 主动聊天（早安/晚安/超支提醒，LLM 每次重新生成）
- [ ] 每日/每周消费总结
- [ ] 账本面板（侧滑，月度总览 + 分类图表）
- [ ] 预算管理 + 超支提醒
- [ ] 借贷管理（欠款追踪 + 还款记录）
- [ ] 标签系统（自由标签 + 按标签统计）
- [ ] 自定义人设（用户自己创建）

### Phase 3 — 丰富体验（2-3 周）

- [ ] Skill 系统（可插拔技能 + Skill 市场）
- [ ] 消费分析（LLM 分析消费模式，Echo 主动建议）
- [ ] 周期记账（房租等固定支出自动扣）
- [ ] 记账附件（小票/截图关联保存）
- [ ] 云同步（WebDAV/S3）
- [ ] 数据导入导出（CSV）
- [ ] 暗黑模式
- [ ] Android APK 打包发布

### Phase 4 — 锦上添花（后续迭代）

- [ ] 语音聊天（Edge TTS → GPT-SoVITS）
- [ ] iOS 发布
- [ ] 桌面小组件
- [ ] 多币种支持
- [ ] 分享账本（家人共用）

---

## 12. 调研参考

| 项目 | Stars | 参考内容 |
|------|------:|------|
| [AstrBot](https://github.com/AstrBotDevs/AstrBot) | 33k | 人格系统 + 摘要压缩 + 消息链分段回复 + Skills |
| [SillyTavern](https://github.com/SillyTavern/SillyTavern) | 28k | 角色卡规范(TavernCardV2) + 逐字打字效果 + Lorebook |
| [BeeCount](https://github.com/TNT-Likely/BeeCount) | 1.6k | Flutter 记账 App 参考 + AI 对话记账 + MCP |
| [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS) | 57.7k | 1 分钟音频克隆声音（Phase 4 语音方案） |
| Kindroid | 闭源 | 五层记忆系统参考 |
