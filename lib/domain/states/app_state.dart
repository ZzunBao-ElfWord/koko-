import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user.dart';
import '../../data/models/server.dart';
import '../../data/models/channel.dart';
import '../../data/models/message.dart';

/// Global application state managed by Riverpod.

// Current authenticated user
final currentUserProvider = StateProvider<User?>((ref) => null);

// Connection state
final connectionStateProvider = StateProvider<String>((ref) => 'disconnected');

// Selected server
final selectedServerProvider = StateProvider<Server?>((ref) => null);

// Selected channel
final selectedChannelProvider = StateProvider<Channel?>((ref) => null);

// Messages for current channel
final channelMessagesProvider = StateProvider<List<Message>>((ref) => []);

// Servers list
final serversProvider = StateProvider<List<Server>>((ref) => []);

// Channels for selected server
final channelsProvider = StateProvider<List<Channel>>((ref) => []);

// DM channels
final dmChannelsProvider = StateProvider<List<Channel>>((ref) => []);

// Users cache (id -> User)
final usersCacheProvider = StateProvider<Map<String, User>>((ref) => {});

// Loading states
final isLoadingProvider = StateProvider<bool>((ref) => false);
final isSendingProvider = StateProvider<bool>((ref) => false);

// Locale / language
final appLocaleProvider = StateProvider<Locale?>((ref) => null); // null = follow system
