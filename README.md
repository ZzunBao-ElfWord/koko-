# Stoat Mobile

Native mobile client for Stoat (Revolt) — built with Flutter.

## Target Instance

- **Server**: https://kokokongkong.com
- **WebSocket**: wss://kokokongkong.com/ws
- **API**: https://kokokongkong.com/api

> **域名切换**：默认指向新域名 `kokokongkong.com`。如需切换回旧域名 `openelfai.cn`，见下方「域名切换」章节。

## Features

### Phase 3 — 完整体验 (v0.3.0)
- [x] 离线消息队列（断网自动缓存、恢复后重发、失败可重试）
- [x] 离线浏览（断网可查看已缓存消息/频道/服务器）
- [x] 多语言支持（中文/英文，即时切换）
- [x] 个人资料查看与编辑（头像、状态、在线状态）
- [x] 好友系统（列表、添加、接受/拒绝、删除）
- [x] 好友请求通知（WebSocket 实时同步）
- [x] 性能优化（分页加载、SQLite 索引）

### Phase 2 — 核心功能 (v0.2.0)
- [x] 消息回复/反应/编辑/删除
- [x] 消息搜索
- [x] 任意文件收发（图片/视频/文档 + 魔术字节校验）
- [x] 多图画廊浏览
- [x] 私信 DM
- [x] 语音频道（LiveKit + 音量指示 + 弱网提示）
- [x] 推送通知（FCM 代码层）
- [x] WebSocket 断线重连 + ULID 事件补偿

### Phase 1 — MVP (v0.1.0)
- [x] 注册/登录
- [x] 服务器/频道浏览
- [x] 文字消息收发
- [x] SQLite 本地缓存
- [x] Markdown 渲染
- [x] 图片附件预览

## Architecture

```
lib/
├── core/              # Constants, theme
├── l10n/              # ARB localization files (en, zh)
├── data/
│   ├── models/        # Data models
│   ├── repositories/  # Data access abstraction
│   └── local/         # SQLite database
├── domain/
│   ├── services/      # WebSocket, offline queue, voice, push
│   └── states/        # Riverpod state providers
├── network/
│   ├── api_client.dart       # Delta REST API
│   └── websocket_client.dart # Bonfire WebSocket
└── presentation/
    ├── screens/       # UI screens
    ├── widgets/       # Reusable widgets
    └── providers/     # Dependency injection
```

## Getting Started

### Prerequisites

- Flutter SDK >= 3.16.0
- Android SDK (for Android builds)
- Xcode (for iOS builds)

### Install Dependencies

```bash
flutter pub get
```

### Run

```bash
# Android
flutter run

# iOS (requires macOS & Xcode)
flutter run -d ios
```

### iOS 项目目录

> **macOS 用户**：若 `ios/` 目录不存在，请在项目根目录执行以下命令生成 iOS 项目结构：
> ```bash
> flutter create .
> ```
> 生成后按 [BUILD.md](BUILD.md) 中的 iOS 配置章节完成签名和权限配置。

### 域名切换

所有服务端域名通过编译期 `--dart-define` 注入，统一在 `lib/core/config/app_config.dart` 管理。

```bash
# 新域名（默认，无需额外参数）
flutter build apk --release

# 旧域名（过渡期 / 回滚）
flutter build apk --release --dart-define=API_BASE_URL=https://openelfai.cn
```

### Build Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires macOS & Xcode)
flutter build ios --release
```

See [BUILD.md](BUILD.md) for detailed build instructions including signing, ProGuard, and iOS configuration.

## 安全加固项（后续计划）

| 项目 | 现状 | 建议 |
|------|------|------|
| SQLite 加密 | 本地 SQLite 以明文存储缓存数据 | 建议后续接入 `sqlcipher_flutter_libs`，启用数据库级加密，防止设备被 root 后敏感信息泄露 |

## Compliance

This client is built from scratch and only calls Stoat's public REST/WebSocket APIs. No code from the official Revolt/Stoat client repositories is used. Licensed under AGPL-3.0.
