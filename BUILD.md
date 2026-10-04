# Stoat Mobile — 构建与运行说明（M3 完整体验版）

## 环境要求

- Flutter SDK >= 3.16.0
- Dart SDK >= 3.0.0
- Android SDK >= 21（推荐 33+）
- Android Studio / VS Code
- 后端实例：https://kokokongkong.com（默认）

## 依赖安装

```bash
cd stoat_mobile
flutter pub get
```

> **注意**：首次运行 `flutter pub get` 时会根据 `l10n.yaml` 自动生成 `lib/l10n/app_localizations.dart` 等本地化文件。

## Android 构建

### 前置配置

1. **Firebase 配置（推送必需）**
   - 在 Firebase Console 创建项目并添加 Android 应用（包名：`com.openelf.stoat`）
   - 下载 `google-services.json` 并替换 `android/app/google-services.json.PLACEHOLDER`
   - 删除 `.PLACEHOLDER` 后缀
   - 如暂不配置推送，应用仍可编译运行，但推送功能不可用

2. **Release 签名（上架必需）**
   - 生成签名密钥：
     ```bash
     keytool -genkey -v -keystore stoat-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias stoat
     ```
   - 在 `android/app/build.gradle` 中配置签名：
     ```gradle
     android {
         signingConfigs {
             release {
                 storeFile file("stoat-release-key.jks")
                 storePassword System.getenv("STOAT_STORE_PASSWORD")
                 keyAlias "stoat"
                 keyPassword System.getenv("STOAT_KEY_PASSWORD")
             }
         }
         buildTypes {
             release {
                 signingConfig signingConfigs.release
                 minifyEnabled true
                 shrinkResources true
                 proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
             }
         }
     }
     ```
   - 混淆规则已配置在 `android/app/proguard-rules.pro`

3. **版本号管理**
   - `pubspec.yaml` 中的 `version: 0.3.0+3` 格式：`versionName+versionCode`
   - 每次发布前递增 `versionCode`（+ 号后的数字）

### 构建 APK

```bash
flutter build apk --release
```

输出路径：`build/app/outputs/flutter-apk/app-release.apk`

### 构建 App Bundle（Play Store 上架）

```bash
flutter build appbundle --release
```

输出路径：`build/app/outputs/bundle/release/app-release.aab`

## iOS 构建（仅代码，需 Apple Developer 账号）

> **环境限制**：沙箱无 macOS/Xcode，iOS 端未实际构建验证。以下为指导步骤。

1. 在 macOS 上执行 `flutter create .` 生成 iOS 项目
2. 在 Xcode 中打开 `ios/Runner.xcworkspace`
3. 配置 Signing & Capabilities：
   - 添加 Push Notifications capability
   - 添加 Background Modes → Voice over IP（如需后台语音）
4. 在 Firebase Console 添加 iOS 应用并下载 `GoogleService-Info.plist`，放入 `ios/Runner/`
5. 在 `ios/Podfile` 确保平台版本 `platform :ios, '13.0'`
6. 在 `ios/Runner/Info.plist` 添加以下权限描述：
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>Stoat 需要麦克风权限以进行语音通话</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>Stoat 需要访问相册以发送图片附件</string>
   <key>NSCameraUsageDescription</key>
   <string>Stoat 需要相机权限以拍摄头像</string>
   <key>NSUserNotificationUsageDescription</key>
   <string>Stoat 需要通知权限以接收消息提醒</string>
   ```
7. 构建：
   ```bash
   flutter build ios --release
   ```

## 应用图标与启动屏

### Android 图标

`android/app/src/main/res/mipmap-*/` 目录结构已配置完整（mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi），当前为占位图标（蓝色底白色 "S" 字母）。

> **上架前必须替换为真实应用图标**：请设计师按以下尺寸提供 `ic_launcher.png`：
> | 目录 | 尺寸（px） | 对应 dp |
> |------|-----------|---------|
> | mipmap-mdpi | 48x48 | 48dp |
> | mipmap-hdpi | 72x72 | 72dp |
> | mipmap-xhdpi | 96x96 | 96dp |
> | mipmap-xxhdpi | 144x144 | 144dp |
> | mipmap-xxxhdpi | 192x192 | 192dp |
>
> 替换后同步检查 `AndroidManifest.xml` 中 `android:icon="@mipmap/ic_launcher"` 指向正确。

### iOS 图标
- 在 Xcode 的 `Assets.xcassets/AppIcon.appiconset` 中替换全部尺寸
- 可使用 [appicon.co](https://appicon.co) 一键生成全尺寸图标包

### 启动屏
- 使用 `flutter_native_splash` 包（可选，需额外配置）

## 运行调试

```bash
# 连接 Android 设备或启动模拟器
flutter devices

# 运行调试版
flutter run

# 指定设备
flutter run -d <device_id>
```

## 已知构建限制

| 限制项 | 说明 |
|--------|------|
| 沙箱无 Flutter SDK | 本代码包未在沙箱内执行 `flutter build`，构建请在本地 Flutter 环境完成 |
| iOS 未验证 | 无 macOS/Xcode 环境，iOS 配置为代码层面指导 |
| FCM 需真实配置 | `google-services.json` 为占位文件，需替换为真实 Firebase 配置 |
| APNs 需 Apple 账号 | iOS 推送需 Apple Developer Program 会员（$99/年） |
| 图标需替换 | 当前为默认 Flutter 图标，上架前需替换 |

## 域名切换

所有服务端域名通过编译期 `--dart-define` 统一注入，配置中心为 `lib/core/config/app_config.dart`。

### 新域名（默认）

无需额外参数，默认指向 `https://kokokongkong.com`：

```bash
flutter build apk --release
```

### 旧域名（过渡期 / 回滚）

一行命令切换回 `openelfai.cn`：

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://openelfai.cn
```

> 说明：`--dart-define=API_BASE_URL` 会同时影响 API、WebSocket、autumn 文件服务和 LiveKit 的域名推导，无需逐个修改。

## 后端依赖检查清单

在首次运行前，请确认后端以下服务状态：

- [ ] delta REST API 可访问（`https://kokokongkong.com/api`）
- [ ] bonfire WebSocket 可连接（`wss://kokokongkong.com/ws`）
- [ ] autumn 文件服务可上传（`https://kokokongkong.com/autumn`）
- [ ] LiveKit SFU 可连接（`wss://kokokongkong.com/livekit`）
- [ ] pushd 推送服务运行中
- [ ] delta API 支持 `/users/friend`（发送好友请求）
- [ ] delta API 支持 `/users/{target}/friend`（接受/删除好友）
- [ ] delta API 支持 `/users/{id}/mutual`（共同服务器）
- [ ] delta API 支持 `/users/@me` PATCH（编辑资料）
- [ ] delta API 支持 `/channels/{id}/join_call`（语音频道）
- [ ] delta API 支持 `/push/register` 和 `/push/unregister`（推送）
