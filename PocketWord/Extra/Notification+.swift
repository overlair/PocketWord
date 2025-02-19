//
//  Notification+.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import Foundation


extension Notification.Name {
    static var changeBook: Notification.Name {
          return .init(rawValue: "UserNavigation.book") }
static var changeChapter: Notification.Name {
          return .init(rawValue: "UserNavigation.chapter") }

    static var displayChapters: Notification.Name {
              return .init(rawValue: "UserNavigation.chaptersShown") }

static var changeSelection: Notification.Name {
          return .init(rawValue: "UserInteraction.selection") }
static var addNote: Notification.Name {
          return .init(rawValue: "UserInteraction.addNote") }
}
