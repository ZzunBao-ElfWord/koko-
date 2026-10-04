# Phase 3 验收清单

## 验收标准逐项核对

| # | 验收项 | 状态 | 说明 |
|---|--------|------|------|
| A1 | 断网发送消息进入队列，恢复后自动重发成功 | ✅ 代码完成 | OfflineQueueService + pending_messages 表实现自动重发（最多3次重试） |
| A2 | 失败消息可重试 | ✅ 代码完成 | MessageBubble 显示红色感叹号，点击弹出重试/删除选项 |
| A3 | 断网可浏览缓存消息 | ✅ 代码完成 | SQLite 缓存消息/频道/服务器，断网时从本地读取 |
| A4 | 恢复在线自动补偿同步 | ✅ 代码完成 | WebSocket reconnection 后触发 _compensateEvents 拉取缺失消息 |
| B1 | 1000+ 消息频道滚动流畅 | ✅ 代码完成 | 分页加载（每页50条）、上滑触发加载更多、不复用 ListView 全量加载 |
| B2 | 图片加载优化 | ✅ 代码完成 | cached_network_image 已在依赖中，大图按需加载（FullscreenImageViewer） |
| B3 | SQLite 查询优化 | ✅ 代码完成 | channel_id+created_at 复合索引已存在，单次查询分页 |
| C1 | 引入 flutter_localizations + intl | ✅ 代码完成 | pubspec.yaml 已添加 flutter_localizations SDK 依赖 |
| C2 | 首发中文+英文 | ✅ 代码完成 | app_en.arb (70+ 字符串) + app_zh.arb 已完成 |
| C3 | 语言切换即时生效 | ✅ 代码完成 | SettingsScreen 语言选择器 + appLocaleProvider，切换后 setState 生效 |
| C4 | 跟随系统语言为默认值 | ✅ 代码完成 | localeResolutionCallback 优先匹配设备语言 |
| D1 | 个人资料可查看 | ✅ 代码完成 | UserProfileScreen 支持查看头像/用户名/状态/共同服务器 |
| D2 | 个人资料可编辑 | ✅ 代码完成 | EditProfileScreen 支持修改显示名/头像/状态文本/在线状态 |
| D3 | 头像上传成功 | ✅ 代码完成 | 复用 autumn 上传（ApiClient.uploadAttachment），editSelf 更新头像 ID |
| D4 | 好友请求发送 | ✅ 代码完成 | FriendsRepository.sendFriendRequest 调用 POST /users/friend |
| D5 | 好友请求接受/拒绝 | ✅ 代码完成 | FriendsRepository.acceptFriendRequest / removeFriend |
| D6 | 好友请求通知 | ✅ 代码完成 | WebSocket UserRelationship 事件处理 + 应用内红点通知 |
| D7 | 删除好友（二次确认） | ✅ 代码完成 | FriendsListScreen 弹出 AlertDialog 二次确认 |
| E1 | Android 构建配置 | ✅ 代码完成 | build.gradle 配置 release 签名占位、proguard-rules.pro 混淆规则 |
| E2 | iOS 构建配置 | ✅ 代码完成 | BUILD.md 包含 Info.plist 权限描述文案（麦克风/照片/通知） |
| E3 | 隐私政策模板 | ✅ 代码完成 | PRIVACY_POLICY.md 占位文档，标注需法务确认 |
| E4 | CHANGELOG | ✅ 代码完成 | CHANGELOG.md 包含 M1/M2/M3 完整变更记录 |
| — | 5层架构合规 | ✅ 代码完成 | core/data/domain/network/presentation 分层清晰，未破坏已有功能 |

## 已验证 / 未验证 / 已知问题

### 已验证（代码层面）
- 数据库 v3 迁移脚本（onUpgrade oldVersion < 3）
- OfflineQueueService 队列处理流程（enqueue → processQueue → retry）
- flutter_localizations 配置（MaterialApp.router 中 delegates / supportedLocales / localeResolutionCallback）
- 好友 API 端点映射（addFriend / acceptFriend / removeFriend / fetchMutualServers）
- WebSocket UserRelationship 事件解析和本地缓存更新
- Android build.gradle release 配置和 ProGuard 规则

### 未验证（受环境限制）
- ❌ `flutter build` 实际编译通过（沙箱无 Flutter SDK）
- ❌ iOS 实际构建（沙箱无 macOS/Xcode）
- ❌ 真机运行测试（无实体设备/模拟器）
- ❌ 后端 API 联调（未实际调用 /users/friend 等端点验证行为）
- ❌ 多语言 ARB 文件生成后的 app_localizations.dart 编译（需 flutter pub get 触发 gen-l10n）
- ❌ 头像上传端到端流程（autumn 上传 + PATCH /users/@me）
- ❌ 好友请求 WebSocket 实时通知（依赖后端实际推送 UserRelationship 事件）

### 已知问题 / 风险
1. **API 兼容性风险**：Revolt/Stoat 后端 API 可能与文档有差异。好友相关端点（`/users/friend` vs `/users/friends`）需联调确认。如后端返回格式不符，需调整 ApiClient 中的路径。
2. **iOS 项目缺失**：代码包中无 `ios/` 目录。需在 macOS 上运行 `flutter create .` 生成。
3. **Firebase 配置占位**：`google-services.json` 为占位文件，推送功能需真实 Firebase 项目配置。
4. **应用图标为默认**：`android/app/src/main/res/mipmap-*/` 下仍为 Flutter 默认图标，上架前必须替换。
5. **隐私政策需法务审核**：`PRIVACY_POLICY.md` 为工程模板，实际发布前需专业法务确认。
6. **内存缓存策略**：cached_network_image 依赖默认内存缓存，未配置自定义缓存大小限制。极端场景（大量高清图）可能 OOM。
7. **启动速度**：冷启动 ≤3 秒目标未做专项 profile。延迟初始化（非关键服务懒加载）已实施，但无实测数据。

### 后端 API 缺口报告
以下端点基于 Revolt API 文档实现，**未与 https://kokokongkong.com 实际联调验证**：

| 端点 | 用途 | 状态 |
|------|------|------|
| POST /users/friend | 发送好友请求 | 待联调确认 |
| PUT /users/{target}/friend | 接受好友请求 | 待联调确认 |
| DELETE /users/{target}/friend | 删除/拒绝好友 | 待联调确认 |
| GET /users/{id}/mutual | 共同服务器 | 待联调确认 |
| PATCH /users/@me | 编辑个人资料 | 待联调确认 |

> 如后端返回 404 或格式不匹配，请在 ApiClient 中调整对应方法的路径或请求体。
