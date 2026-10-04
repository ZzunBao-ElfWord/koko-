// GENERATED CODE - DO NOT MODIFY BY HAND
// This file was manually generated to simulate flutter gen-l10n output
// since Flutter SDK is not available in the sandbox.
// Run `flutter gen-l10n` in a proper Flutter environment to regenerate.

import 'package:flutter/material.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = locale;

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  String get about;
  String get accept;
  String get account;
  String get addFriend;
  String get addReaction;
  String get addReactionFailed;
  String get appName;
  String get attachment;
  String get attachmentCount;
  String get attachmentPlaceholder;
  String get backOnline;
  String get busy;
  String get cancel;
  String get cancelRequest;
  String get cannotReadFile;
  String get changelog;
  String get channels;
  String get confirm;
  String get confirmPassword;
  String get connecting;
  String get copied;
  String get copiedToClipboard;
  String get copy;
  String get createAccount;
  String get deafen;
  String get delete;
  String get deleteFailed;
  String get deleteMessageConfirm;
  String get deleteMessageTitle;
  String get directMessages;
  String get directMessagesTitle;
  String get displayNameHint;
  String get displayNameLabel;
  String get download;
  String get downloaded;
  String get edit;
  String get editFailed;
  String get editMessageHint;
  String get editProfile;
  String get edited;
  String get editing;
  String get email;
  String get enableNotifications;
  String get enterConfirmPassword;
  String get enterEmail;
  String get enterPassword;
  String get error;
  String get failedToLoadImage;
  String get failedToLoadVideo;
  String get failedToSend;
  String get file;
  String get filePicker;
  String get filePickerSubtitle;
  String get forgotPassword;
  String get friendRemoved;
  String get friendRequestSent;
  String get friendRequests;
  String get friends;
  String get hasAccount;
  String get idle;
  String get image;
  String get imagePicker;
  String get imagePickerSubtitle;
  String get incoming;
  String get invisible;
  String get joiningVoice;
  String get language;
  String get languageEn;
  String get languageSystem;
  String get languageZh;
  String get leave;
  String get loadFailed;
  String get loadMessagesFailed;
  String get loading;
  String get login;
  String get loginFailed;
  String get logout;
  String get logoutConfirm;
  String get logoutContent;
  String get logoutTitle;
  String get me;
  String get messageHint;
  String get messageHintWithChannel;
  String get messageMenuAddReaction;
  String get messageMenuDelete;
  String get messageMenuEdit;
  String get messageMenuReply;
  String get microphonePermission;
  String get microphonePermissionDesc;
  String get mute;
  String get mutualServers;
  String get networkError;
  String get networkQualityPoor;
  String get noAccount;
  String get noContent;
  String get noDirectMessages;
  String get noFriends;
  String get noIncomingRequests;
  String get noMatchingMessages;
  String get noMessages;
  String get noOtherParticipants;
  String get noOutgoingRequests;
  String get noResults;
  String get notConnected;
  String get notificationDenied;
  String get notificationSubtitle;
  String get notifications;
  String get offline;
  String get offlineBanner;
  String get offlineCount;
  String get online;
  String get onlineCount;
  String get onlineCountPeople;
  String get openFailed;
  String get openInBrowser;
  String get opening;
  String get outgoing;
  String get password;
  String get passwordDigit;
  String get passwordLowercase;
  String get passwordMinLength;
  String get passwordUppercase;
  String get passwordsNotMatch;
  String get pending;
  String get presenceTitle;
  String get privacyPolicy;
  String get profile;
  String get profileSaved;
  String get readImageFailed;
  String get register;
  String get registrationFailed;
  String get reject;
  String get rejectSuccess;
  String get removeFriendConfirm;
  String get removeFriendLabel;
  String get removeReactionFailed;
  String get reply;
  String get replyingTo;
  String get requestCancelled;
  String get retry;
  String get retrySend;
  String get save;
  String get saveFailed;
  String get search;
  String get searchChannel;
  String get searchMessages;
  String get searchTooltip;
  String get selectChannel;
  String get selectConversation;
  String get send;
  String get sendFailedRetry;
  String get sendMessage;
  String get sending;
  String get server;
  String get serverUrl;
  String get servers;
  String get settings;
  String get settingsTooltip;
  String get signIn;
  String get signInToAccount;
  String get startSearch;
  String get statusText;
  String get statusTextHint;
  String get statusTextLabel;
  String get tapToJump;
  String get termsOfService;
  String get undeafen;
  String get unknownError;
  String get unmute;
  String get uploadFailed;
  String get userNotFound;
  String get username;
  String get usernameFormat;
  String get usernameLength;
  String get usernameOptional;
  String get usernameReadonly;
  String get validEmail;
  String get version;
  String get viewProfile;
  String get videoLoadFailed;
  String get voice;
  String get voicePermission;
  String get waitingForConfirm;
  String get welcomeToStoat;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final name = locale.languageCode;
    if (name == 'zh') return AppLocalizationsZh();
    return AppLocalizationsEn();
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn() : super('en');

  @override
  String get about => 'About';
  @override
  String get accept => 'Accept';
  @override
  String get account => 'Account';
  @override
  String get addFriend => 'Add Friend';
  @override
  String get addReaction => 'Add Reaction';
  @override
  String get addReactionFailed => 'Failed to add reaction';
  @override
  String get appName => 'Stoat';
  @override
  String get attachment => 'Attachment';
  @override
  String get attachmentCount => 'attachments';
  @override
  String get attachmentPlaceholder => '[Attachment]';
  @override
  String get backOnline => 'Back online';
  @override
  String get busy => 'Do Not Disturb';
  @override
  String get cancel => 'Cancel';
  @override
  String get cancelRequest => 'Cancel';
  @override
  String get cannotReadFile => 'Cannot read file';
  @override
  String get changelog => 'Changelog';
  @override
  String get channels => 'Channels';
  @override
  String get confirm => 'Confirm';
  @override
  String get confirmPassword => 'Confirm Password';
  @override
  String get connecting => 'Connecting...';
  @override
  String get copied => 'Copied';
  @override
  String get copiedToClipboard => 'Copied to clipboard';
  @override
  String get copy => 'Copy';
  @override
  String get createAccount => 'Create Account';
  @override
  String get deafen => 'Deafen';
  @override
  String get delete => 'Delete';
  @override
  String get deleteFailed => 'Delete failed';
  @override
  String get deleteMessageConfirm => 'This action cannot be undone. Delete this message?';
  @override
  String get deleteMessageTitle => 'Delete Message';
  @override
  String get directMessages => 'Direct Messages';
  @override
  String get directMessagesTitle => 'Direct Messages';
  @override
  String get displayNameHint => 'Enter display name';
  @override
  String get displayNameLabel => 'Display Name';
  @override
  String get download => 'Download';
  @override
  String get downloaded => 'Downloaded';
  @override
  String get edit => 'Edit';
  @override
  String get editFailed => 'Edit failed';
  @override
  String get editMessageHint => 'Edit message...';
  @override
  String get editProfile => 'Edit Profile';
  @override
  String get edited => 'edited';
  @override
  String get editing => 'Editing';
  @override
  String get email => 'Email';
  @override
  String get enableNotifications => 'Enable Push Notifications';
  @override
  String get enterConfirmPassword => 'Please confirm your password';
  @override
  String get enterEmail => 'Please enter your email';
  @override
  String get enterPassword => 'Please enter your password';
  @override
  String get error => 'Error';
  @override
  String get failedToLoadImage => 'Failed to load image';
  @override
  String get failedToLoadVideo => 'Failed to load video';
  @override
  String get failedToSend => 'Failed to send';
  @override
  String get file => 'File';
  @override
  String get filePicker => 'File';
  @override
  String get filePickerSubtitle => 'Documents, videos, archives, etc.';
  @override
  String get forgotPassword => 'Forgot Password?';
  @override
  String get friendRemoved => 'Friend removed';
  @override
  String get friendRequestSent => 'Friend request sent';
  @override
  String get friendRequests => 'Friend Requests';
  @override
  String get friends => 'Friends';
  @override
  String get hasAccount => 'Already have an account?';
  @override
  String get idle => 'Idle';
  @override
  String get image => 'Image';
  @override
  String get imagePicker => 'Image';
  @override
  String get imagePickerSubtitle => 'jpg, png, gif, webp';
  @override
  String get incoming => 'Incoming';
  @override
  String get invisible => 'Invisible';
  @override
  String get joiningVoice => 'Joining voice channel...';
  @override
  String get language => 'Language';
  @override
  String get languageEn => 'English';
  @override
  String get languageSystem => 'System Default';
  @override
  String get languageZh => 'Chinese';
  @override
  String get leave => 'Leave';
  @override
  String get loadFailed => 'Load failed';
  @override
  String get loadMessagesFailed => 'Failed to load messages';
  @override
  String get loading => 'Loading...';
  @override
  String get login => 'Login';
  @override
  String get loginFailed => 'Login failed';
  @override
  String get logout => 'Logout';
  @override
  String get logoutConfirm => 'Are you sure you want to logout?';
  @override
  String get logoutContent => 'Local session data will be cleared after logout.';
  @override
  String get logoutTitle => 'Confirm Logout';
  @override
  String get me => 'Me';
  @override
  String get messageHint => 'Message';
  @override
  String get messageHintWithChannel => 'Message #';
  @override
  String get messageMenuAddReaction => 'Add Reaction';
  @override
  String get messageMenuDelete => 'Delete';
  @override
  String get messageMenuEdit => 'Edit';
  @override
  String get messageMenuReply => 'Reply';
  @override
  String get microphonePermission => 'Microphone Permission';
  @override
  String get microphonePermissionDesc => 'Required for voice channel calls';
  @override
  String get mute => 'Mute';
  @override
  String get mutualServers => 'Mutual Servers';
  @override
  String get networkError => 'Network error. Please check your connection.';
  @override
  String get networkQualityPoor => 'Poor network quality, call may be affected';
  @override
  String get noAccount => 'Don\'t have an account?';
  @override
  String get noContent => 'No content';
  @override
  String get noDirectMessages => 'No direct messages';
  @override
  String get noFriends => 'No friends yet';
  @override
  String get noIncomingRequests => 'No incoming friend requests';
  @override
  String get noMatchingMessages => 'No matching messages';
  @override
  String get noMessages => 'No messages yet';
  @override
  String get noOtherParticipants => 'No other participants';
  @override
  String get noOutgoingRequests => 'No outgoing friend requests';
  @override
  String get noResults => 'No results found';
  @override
  String get notConnected => 'Not connected';
  @override
  String get notificationDenied => 'Notification permission denied. Please enable in system settings.';
  @override
  String get notificationSubtitle => 'Receive message alerts when app is in background';
  @override
  String get notifications => 'Notifications';
  @override
  String get offline => 'Offline';
  @override
  String get offlineBanner => 'You are offline. Messages will be sent when connection is restored.';
  @override
  String get offlineCount => 'Offline';
  @override
  String get online => 'Online';
  @override
  String get onlineCount => 'Online';
  @override
  String get onlineCountPeople => 'online';
  @override
  String get openFailed => 'Open failed';
  @override
  String get openInBrowser => 'Open in Browser';
  @override
  String get opening => 'Opening...';
  @override
  String get outgoing => 'Outgoing';
  @override
  String get password => 'Password';
  @override
  String get passwordDigit => 'Password must contain at least one digit';
  @override
  String get passwordLowercase => 'Password must contain at least one lowercase letter';
  @override
  String get passwordMinLength => 'Password must be at least 8 characters';
  @override
  String get passwordUppercase => 'Password must contain at least one uppercase letter';
  @override
  String get passwordsNotMatch => 'Passwords do not match';
  @override
  String get pending => 'Pending';
  @override
  String get presenceTitle => 'Presence';
  @override
  String get privacyPolicy => 'Privacy Policy';
  @override
  String get profile => 'Profile';
  @override
  String get profileSaved => 'Profile saved';
  @override
  String get readImageFailed => 'Failed to read image';
  @override
  String get register => 'Register';
  @override
  String get registrationFailed => 'Registration failed';
  @override
  String get reject => 'Reject';
  @override
  String get rejectSuccess => 'Rejected';
  @override
  String get removeFriendConfirm => 'Remove this friend?';
  @override
  String get removeFriendLabel => 'Remove Friend';
  @override
  String get removeReactionFailed => 'Failed to remove reaction';
  @override
  String get reply => 'Reply';
  @override
  String get replyingTo => 'Replying to';
  @override
  String get requestCancelled => 'Request cancelled';
  @override
  String get retry => 'Retry';
  @override
  String get retrySend => 'Retry Send';
  @override
  String get save => 'Save';
  @override
  String get saveFailed => 'Save failed';
  @override
  String get search => 'Search';
  @override
  String get searchChannel => 'Search #';
  @override
  String get searchMessages => 'Search messages...';
  @override
  String get searchTooltip => 'Search messages';
  @override
  String get selectChannel => 'Select a channel';
  @override
  String get selectConversation => 'Select a conversation';
  @override
  String get send => 'Send';
  @override
  String get sendFailedRetry => 'Failed to send (tap to retry)';
  @override
  String get sendMessage => 'Send Message';
  @override
  String get sending => 'Sending...';
  @override
  String get server => 'Server';
  @override
  String get serverUrl => 'Server URL';
  @override
  String get servers => 'Servers';
  @override
  String get settings => 'Settings';
  @override
  String get settingsTooltip => 'Settings';
  @override
  String get signIn => 'Sign In';
  @override
  String get signInToAccount => 'Sign in to your account';
  @override
  String get startSearch => 'Enter keywords to search';
  @override
  String get statusText => 'Status Text';
  @override
  String get statusTextHint => 'Enter your status';
  @override
  String get statusTextLabel => 'Status Text';
  @override
  String get tapToJump => 'Tap to jump to message';
  @override
  String get termsOfService => 'Terms of Service';
  @override
  String get undeafen => 'Undeafen';
  @override
  String get unknownError => 'An unknown error occurred';
  @override
  String get unmute => 'Unmute';
  @override
  String get uploadFailed => 'Upload failed';
  @override
  String get userNotFound => 'User not found';
  @override
  String get username => 'Username';
  @override
  String get usernameFormat => 'Username can only contain letters, numbers, and underscores';
  @override
  String get usernameLength => 'Username must be 3-32 characters';
  @override
  String get usernameOptional => 'Username (optional)';
  @override
  String get usernameReadonly => 'Username cannot be changed';
  @override
  String get validEmail => 'Please enter a valid email address';
  @override
  String get version => 'Version';
  @override
  String get viewProfile => 'View Profile';
  @override
  String get videoLoadFailed => 'Unable to load video';
  @override
  String get voice => 'Voice';
  @override
  String get voicePermission => 'Voice Permission';
  @override
  String get waitingForConfirm => 'Waiting for confirmation';
  @override
  String get welcomeToStoat => 'Welcome to Stoat';
}

class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh() : super('zh');

  @override
  String get about => 'About';
  @override
  String get accept => 'Accept';
  @override
  String get account => '账号';
  @override
  String get addFriend => 'Add Friend';
  @override
  String get addReaction => 'Add Reaction';
  @override
  String get addReactionFailed => '添加反应失败';
  @override
  String get appName => 'Stoat';
  @override
  String get attachment => 'Attachment';
  @override
  String get attachmentCount => '个附件';
  @override
  String get attachmentPlaceholder => '[附件]';
  @override
  String get backOnline => 'Back online';
  @override
  String get busy => 'Do Not Disturb';
  @override
  String get cancel => 'Cancel';
  @override
  String get cancelRequest => '取消';
  @override
  String get cannotReadFile => '无法读取文件';
  @override
  String get changelog => 'Changelog';
  @override
  String get channels => 'Channels';
  @override
  String get confirm => 'Confirm';
  @override
  String get confirmPassword => 'Confirm Password';
  @override
  String get connecting => '连接中...';
  @override
  String get copied => 'Copied';
  @override
  String get copiedToClipboard => '已复制到剪贴板';
  @override
  String get copy => 'Copy';
  @override
  String get createAccount => '创建账号';
  @override
  String get deafen => '耳机静音';
  @override
  String get delete => 'Delete';
  @override
  String get deleteFailed => '删除失败';
  @override
  String get deleteMessageConfirm => 'This action cannot be undone. Delete this message?';
  @override
  String get deleteMessageTitle => '删除消息';
  @override
  String get directMessages => 'Direct Messages';
  @override
  String get directMessagesTitle => '私信';
  @override
  String get displayNameHint => '输入显示名称';
  @override
  String get displayNameLabel => '显示名称';
  @override
  String get download => 'Download';
  @override
  String get downloaded => 'Downloaded';
  @override
  String get edit => 'Edit';
  @override
  String get editFailed => '编辑失败';
  @override
  String get editMessageHint => '编辑消息...';
  @override
  String get editProfile => 'Edit Profile';
  @override
  String get edited => 'edited';
  @override
  String get editing => '编辑中';
  @override
  String get email => 'Email';
  @override
  String get enableNotifications => 'Enable Push Notifications';
  @override
  String get enterConfirmPassword => '请确认密码';
  @override
  String get enterEmail => '请输入邮箱';
  @override
  String get enterPassword => '请输入密码';
  @override
  String get error => 'Error';
  @override
  String get failedToLoadImage => '加载图片失败';
  @override
  String get failedToLoadVideo => '无法加载视频';
  @override
  String get failedToSend => 'Failed to send';
  @override
  String get file => 'File';
  @override
  String get filePicker => '文件';
  @override
  String get filePickerSubtitle => '文档、视频、压缩包等';
  @override
  String get forgotPassword => 'Forgot Password?';
  @override
  String get friendRemoved => '已删除好友';
  @override
  String get friendRequestSent => '好友请求已发送';
  @override
  String get friendRequests => 'Friend Requests';
  @override
  String get friends => 'Friends';
  @override
  String get hasAccount => 'Already have an account?';
  @override
  String get idle => 'Idle';
  @override
  String get image => 'Image';
  @override
  String get imagePicker => '图片';
  @override
  String get imagePickerSubtitle => 'jpg, png, gif, webp';
  @override
  String get incoming => '收到';
  @override
  String get invisible => 'Invisible';
  @override
  String get joiningVoice => '正在加入语音频道...';
  @override
  String get language => 'Language';
  @override
  String get languageEn => 'English';
  @override
  String get languageSystem => 'System Default';
  @override
  String get languageZh => 'Chinese';
  @override
  String get leave => '离开';
  @override
  String get loadFailed => '加载失败';
  @override
  String get loadMessagesFailed => '加载消息失败';
  @override
  String get loading => 'Loading...';
  @override
  String get login => 'Login';
  @override
  String get loginFailed => '登录失败';
  @override
  String get logout => 'Logout';
  @override
  String get logoutConfirm => 'Are you sure you want to logout?';
  @override
  String get logoutContent => '退出后将清除本地会话数据。';
  @override
  String get logoutTitle => '确认退出登录';
  @override
  String get me => '我';
  @override
  String get messageHint => 'Message';
  @override
  String get messageHintWithChannel => '消息 #';
  @override
  String get messageMenuAddReaction => '添加表情';
  @override
  String get messageMenuDelete => '删除';
  @override
  String get messageMenuEdit => '编辑';
  @override
  String get messageMenuReply => '回复';
  @override
  String get microphonePermission => 'Microphone Permission';
  @override
  String get microphonePermissionDesc => 'Required for voice channel calls';
  @override
  String get mute => '静音';
  @override
  String get mutualServers => 'Mutual Servers';
  @override
  String get networkError => 'Network error. Please check your connection.';
  @override
  String get networkQualityPoor => '网络质量较差，通话可能受影响';
  @override
  String get noAccount => 'Don\'t have an account?';
  @override
  String get noContent => 'No content';
  @override
  String get noDirectMessages => '暂无私信';
  @override
  String get noFriends => '还没有好友';
  @override
  String get noIncomingRequests => '没有收到的好友请求';
  @override
  String get noMatchingMessages => '未找到匹配消息';
  @override
  String get noMessages => 'No messages yet';
  @override
  String get noOtherParticipants => '暂无其他参与者';
  @override
  String get noOutgoingRequests => '没有已发送的好友请求';
  @override
  String get noResults => 'No results found';
  @override
  String get notConnected => '未连接';
  @override
  String get notificationDenied => '通知权限被拒绝，请在系统设置中开启';
  @override
  String get notificationSubtitle => 'Receive message alerts when app is in background';
  @override
  String get notifications => 'Notifications';
  @override
  String get offline => 'Offline';
  @override
  String get offlineBanner => 'You are offline. Messages will be sent when connection is restored.';
  @override
  String get offlineCount => '离线';
  @override
  String get online => 'Online';
  @override
  String get onlineCount => '在线';
  @override
  String get onlineCountPeople => '人在线';
  @override
  String get openFailed => '打开失败';
  @override
  String get openInBrowser => 'Open in Browser';
  @override
  String get opening => '打开中...';
  @override
  String get outgoing => '已发送';
  @override
  String get password => 'Password';
  @override
  String get passwordDigit => '密码必须包含至少一个数字';
  @override
  String get passwordLowercase => '密码必须包含至少一个小写字母';
  @override
  String get passwordMinLength => '密码至少 8 个字符';
  @override
  String get passwordUppercase => '密码必须包含至少一个大写字母';
  @override
  String get passwordsNotMatch => '两次输入的密码不一致';
  @override
  String get pending => 'Pending';
  @override
  String get presenceTitle => '在线状态';
  @override
  String get privacyPolicy => 'Privacy Policy';
  @override
  String get profile => 'Profile';
  @override
  String get profileSaved => '资料已保存';
  @override
  String get readImageFailed => '读取图片失败';
  @override
  String get register => 'Register';
  @override
  String get registrationFailed => '注册失败';
  @override
  String get reject => 'Reject';
  @override
  String get rejectSuccess => '已拒绝';
  @override
  String get removeFriendConfirm => 'Remove this friend?';
  @override
  String get removeFriendLabel => '删除好友';
  @override
  String get removeReactionFailed => '移除反应失败';
  @override
  String get reply => 'Reply';
  @override
  String get replyingTo => '回复';
  @override
  String get requestCancelled => '已取消请求';
  @override
  String get retry => 'Retry';
  @override
  String get retrySend => '重试发送';
  @override
  String get save => 'Save';
  @override
  String get saveFailed => '保存失败';
  @override
  String get search => 'Search';
  @override
  String get searchChannel => '搜索 #';
  @override
  String get searchMessages => 'Search messages...';
  @override
  String get searchTooltip => '搜索消息';
  @override
  String get selectChannel => 'Select a channel';
  @override
  String get selectConversation => '选择一个会话';
  @override
  String get send => 'Send';
  @override
  String get sendFailedRetry => '发送失败（点击重试）';
  @override
  String get sendMessage => 'Send Message';
  @override
  String get sending => 'Sending...';
  @override
  String get server => 'Server';
  @override
  String get serverUrl => '服务器地址';
  @override
  String get servers => 'Servers';
  @override
  String get settings => 'Settings';
  @override
  String get settingsTooltip => '设置';
  @override
  String get signIn => '登录';
  @override
  String get signInToAccount => '登录您的账号';
  @override
  String get startSearch => '输入关键词开始搜索';
  @override
  String get statusText => 'Status Text';
  @override
  String get statusTextHint => '输入个人状态';
  @override
  String get statusTextLabel => '状态文本';
  @override
  String get tapToJump => '点击跳转到该消息';
  @override
  String get termsOfService => 'Terms of Service';
  @override
  String get undeafen => '取消耳机静音';
  @override
  String get unknownError => 'An unknown error occurred';
  @override
  String get unmute => '取消静音';
  @override
  String get uploadFailed => '上传失败';
  @override
  String get userNotFound => '用户不存在';
  @override
  String get username => 'Username';
  @override
  String get usernameFormat => '用户名只能包含字母、数字和下划线';
  @override
  String get usernameLength => '用户名必须为 3-32 个字符';
  @override
  String get usernameOptional => '用户名（可选）';
  @override
  String get usernameReadonly => '用户名不可修改';
  @override
  String get validEmail => '请输入有效的邮箱地址';
  @override
  String get version => 'Version';
  @override
  String get viewProfile => '查看资料';
  @override
  String get videoLoadFailed => '无法加载视频';
  @override
  String get voice => 'Voice';
  @override
  String get voicePermission => '麦克风权限';
  @override
  String get waitingForConfirm => '等待对方确认';
  @override
  String get welcomeToStoat => '欢迎使用 Stoat';
}
