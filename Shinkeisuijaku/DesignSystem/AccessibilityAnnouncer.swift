//
//  AccessibilityAnnouncer.swift
//  Shinkeisuijaku
//
//  VoiceOver に文を読み上げてもらう。ボタンを押した直後に出す読み上げは、ボタンの読み上げに消されないよう、優先度を高くして出す。
//

import SwiftUI

/// VoiceOver の読み上げを出す
enum AccessibilityAnnouncer {
    /// ボタンを押した直後に、結果を読み上げる（優先度を高くし、ほかの読み上げに消されないようにする）
    static func announceAfterPress(_ message: String) {
        var text = AttributedString(message)
        text.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(text).post()
    }
}
