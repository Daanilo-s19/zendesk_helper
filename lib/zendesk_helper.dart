// ignore_for_file: avoid_classes_with_only_static_members
import 'dart:async';

import 'package:flutter/services.dart';

/// Provides embed chat functionality
class Zendesk {
  static const MethodChannel _channel = MethodChannel('zendesk');

  /// Initialize the Zendesk SDK with the provided [accountKey] and [appId]
  ///
  /// Offical Docs
  /// iOS: https://developer.zendesk.com/embeddables/docs/chat-sdk-v-2-for-ios/getting_started#initializing-the-sdk
  /// Android: https://developer.zendesk.com/embeddables/docs/chat-sdk-v-2-for-android/getting_started#initializing-the-sdk
  static Future<void> initialize(String accountKey, String appId) async {
    await _channel.invokeMethod<void>('initialize', {
      'accountKey': accountKey,
      'appId': appId,
    });
  }

  /// Convenience utility to prefill visitor information and optionally set
  /// a support [department]
  static Future<void> setVisitorInfo({
    String? name,
    String? email,
    String? phoneNumber,
    String? department,
  }) async {
    await _channel.invokeMethod<void>('setVisitorInfo', {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'department': department,
    });
  }

  /// Open chat modal.
  ///
  /// Optionally set theme color on iOS using [primaryColor]
  ///
  /// If [isPreChatFormEnabled] is true, the pre-chat form will be shown to the user.
  ///
  /// If [isAgentAvailabilityEnabled] is true, offline message will be shown to the
  /// user in case no agent is available.
  ///
  /// If [isChatTranscriptPromptEnabled] is true, users are asked if they want to request a
  /// chat transcript at the end of the chat.
  ///
  /// If [isOfflineFormEnabled] is true, the offline form will be shown to the user.
  ///
  /// If [disableEndChatMenuAction] is true, disable the end chat menu item
  ///
  /// If [isPreChatEmailField] is false, The field email in pre-chat is hidden
  ///
  /// If [isPreChatNameField] is false, The field name in pre-chat is hidden
  ///
  /// If [isPreChatPhoneField] is false, The field phone in pre-chat is hidden
  /// Optionally set bot's name using [botName]
  /// Optionally set toolbarTitle using [toolbarTitle]
  static Future<void> startChat({
    bool? isDarkTheme,
    Color? primaryColor,
    bool isPreChatFormEnabled = true,
    bool isPreChatEmailField = true,
    bool isPreChatNameField = true,
    bool isPreChatPhoneField = true,
    bool isAgentAvailabilityEnabled = true,
    bool isChatTranscriptPromptEnabled = true,
    bool isOfflineFormEnabled = true,
    bool disableEndChatMenuAction = false,
    String? botName = 'Answer Bot',
    String? toolbarTitle = 'Contact Us',
    String? closeAction = 'Close',
  }) async {
    await _channel.invokeMethod<void>('startChat', {
      'isDarkTheme': isDarkTheme,
      'primaryColor': primaryColor?.value,
      'isPreChatFormEnabled': isPreChatFormEnabled,
      'isPreChatEmailField': isPreChatEmailField,
      'isPreChatNameField': isPreChatNameField,
      'isPreChatPhoneField': isPreChatPhoneField,
      'isAgentAvailabilityEnabled': isAgentAvailabilityEnabled,
      'isChatTranscriptPromptEnabled': isChatTranscriptPromptEnabled,
      'isOfflineFormEnabled': isOfflineFormEnabled,
      'disableEndChatMenuAction': disableEndChatMenuAction,
      'toolbarTitle': toolbarTitle,
      'botName': botName,
      'closeAction': closeAction,
    });
  }

  /// Utility to optionaly add tags to the conversation. This can be set to
  /// a `List` of strings which will then appear to the agent in the chat.
  static Future<void> addTags({List<String>? tags}) async {
    await _channel.invokeMethod<void>('addTags', {
      'tags': tags,
    });
  }

  /// Utility to remove tags that were added to the conversation.
  static Future<void> removeTags({List<String>? tags}) async {
    await _channel.invokeMethod<void>('removeTags', {
      'tags': tags,
    });
  }

  /// Send [message] to the chat
  static Future<void> sendMessage(String message) async {
    await _channel.invokeMethod<void>('sendMessage', {
      'message': message,
    });
  }

  static Future<void> endChat() async {
    await _channel.invokeMethod<void>('endChat');
  }

  static Future<void> registerPushToken(String pushToken) async {
    await _channel.invokeMethod<void>('registerPushToken', {
      'pushToken': pushToken,
    });
  }

  static Future<void> unregisterPushToken() async {
    await _channel.invokeMethod<void>('unregisterPushToken');
  }
}
