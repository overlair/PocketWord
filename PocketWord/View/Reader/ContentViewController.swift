//
//  ContentViewController.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import AsyncDisplayKit
import Defaults
import SwiftUI

class ContentViewController: ASDKViewController<BooksNode> {
    init(size: CGSize) {
        super.init(node: BooksNode(size: size))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var bookObserver = Defaults.Observation?.none
    let titleButton = TitleButton(type: .system)
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
//        self.navigationController?.navigationBar.titleTextAttributes = [.font: Constant.bookFont()]
//        self.navigationController?.modalPresentationStyle = .custom
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
//        appearance.backgroundColor = .systemGray6
        appearance.titleTextAttributes  = [.font: Constant.bookFont()]
        appearance.backgroundEffect = UIBlurEffect(style: .dark)
        self.navigationItem.standardAppearance = appearance

        titleButton.translatesAutoresizingMaskIntoConstraints = false
        titleButton.setImage(UIImage(systemName: "chevron.up.circle.fill", withConfiguration: Constant.navBarConfig)?.tinted(.secondaryLabel), for: .normal)

        var titleConfig = UIButton.Configuration.plain()
        titleConfig.imagePadding = 4
        titleConfig.baseForegroundColor = .secondaryLabel
        titleButton.configuration = titleConfig
        titleButton.semanticContentAttribute = .forceRightToLeft
        titleButton.addTarget(self, action: #selector(onMenuOpen), for: .touchUpInside)
//        titleButton.addTarget(self, action: #selector(onMenuDown), for: .touchDown)
//        titleButton.addTarget(self, action: #selector(onMenuOutside), for: .touchUpOutside)
//        titleButton.addTarget(self, action: #selector(onMenuOutside), for: .touchCancel)
        titleButton.autoresizingMask = .flexibleWidth

        self.navigationItem.titleView = titleButton

        
        bookObserver = Defaults.observe(.book, handler: onBookDefaultChange)
        
        NotificationCenter.default
                         .addObserver(self,
                          selector:#selector(onBookChange),
                                      name: .changeBook,
                          object: nil)
        
        NotificationCenter.default
                         .addObserver(self,
                          selector:#selector(onChapterChange),
                                      name: .changeChapter,
                          object: nil)
        NotificationCenter.default
                         .addObserver(self,
                          selector:#selector(onSelectionChange),
                                      name: .changeSelection,
                          object: nil)
        NotificationCenter.default
                         .addObserver(self,
                          selector:#selector(onChaptersChange),
                                      name: .displayChapters,
                          object: nil)
        NotificationCenter.default
                         .addObserver(self,
                          selector:#selector(onAddNote),
                                      name: .addNote,
                          object: nil)

    }
    
    var selection = RangeLocator?.none
    var titleDisplay = TitleDisplay() {
        didSet {
            let string = NSMutableAttributedString()
            let book = NSAttributedString(string: titleDisplay.book,
                                            attributes: [.font: Constant.titleBookFont(),
                                                         .foregroundColor: UIColor.label])
            let chapter = NSAttributedString(string: " " + titleDisplay.chapter,
                                            attributes: [.font: Constant.titleBookFont(),
                                                         .foregroundColor: UIColor.tertiaryLabel])
            string.append(book)
            string.append(chapter)
            

            titleButton.setAttributedTitle(string, for: .normal)

        }
    }
    
    @objc func onMenuOutside() {
        titleButton.alpha = 1
    }
     
    @objc func onMenuDown() {
        print("downdown")
        titleButton.alpha = 0.2
        
    }
    
    @objc func onMenuOpen(button: UIButton)  {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.titleButton.alpha = 1
        }

        let controller = ASNavigationController(rootViewController: MenuViewController())

        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred(intensity: 0.8)
        impact.impactOccurred()

       present(controller, animated: true)
    }
    
    @objc func onAddNote(notification: Notification) {
        guard let note = notification.object as? NoteInput,
                let selection  = selection else {
            return
        }
        
        let record = NoteRecord(id: UUID(),
                   version: selection.version,
                   book: selection.book,
                   chapter: selection.chapter,
                              startVerse: 0,
                              endVerse: 0,
                              startOffset: selection.range.location,
                              endOffset: selection.range.location + selection.range.length,
                   note: note.text,
                              isFavorite: note.isFavorite)
        
        
        do {
            let didWrite = try AppDatabase.shared.database.write { db in
                try record.inserted(db)
            }
            
            let bookCell = node.store.books.nodeForPage(at: selection.book - 1) as! BookCellNode
            let chapterCell = bookCell.store.chapters.nodeForRow(at: .init(row: selection.chapter - 1, section: 0)) as! ChapterCellNode
            let range = selection.range
            
            chapterCell.store.text.textView.textStorage.beginEditing()
            chapterCell.store.text.textView.textStorage.addAttribute(.underlineColor, value: UIColor.systemGray3, range: range)
            chapterCell.store.text.textView.textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.thick.rawValue, range: range)
            chapterCell.store.text.textView.textStorage.endEditing()

            
        } catch {
            print(error)

        }
        
    }
    @objc func onSelectionChange(notification: Notification) {
        guard let locator = notification.object as? RangeLocator? else {
            return
        }
        
        selection = locator

        if let locator {
            node.store.showingControls = true
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(onSelectionDone))
        } else {
            node.store.showingControls = false
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc func onSelectionDone() {
        guard let selection,
              let bookCell = node.store.books.nodeForPage(at: selection.book - 1) as? BookCellNode,
              let chapterCell = bookCell.store.chapters.nodeForRow(at: .init(row: selection.chapter - 1, section: 0)) as? ChapterCellNode
        else { return }
        chapterCell.store.text.resignFirstResponder()
        
        self.selection = nil
        node.store.showingControls = false
        navigationItem.rightBarButtonItem = nil

    }
    
    @objc func onBookChange(notification: Notification) {
        guard let book = notification.object as? Int else {
            return
        }
        
        Defaults[.book] = book
        
        node.store.books.scrollToPage(at: book - 1, animated: false)


    }
    
    func onBookDefaultChange(change: Defaults.KeyChange<Int>) {
        do {
            let name = try AppDatabase.shared.reader.read { db in
                let sql = """
                      SELECT name
                      FROM books
                      WHERE id IS ?
                      """
                return try String.fetchOne(db, sql: sql, arguments: [change.newValue])
            }
            
            if let name {
                titleDisplay.book = name
//                self.navigationItem.title = name
            }
            
            updateChaptersLabel()

        } catch {
        }
    }

    @objc func onChaptersChange(notification: Notification) {
        updateChaptersLabel()
       
    }
    
    func updateChaptersLabel() {
        guard let book = node.store.books.visibleNodes.first as? BookCellNode else {
            return
        }
        let chapters = book.store.chapters.visibleNodes.compactMap { $0.indexPath }.map { $0.row }.sorted()
        var visible = ""
        if let start = chapters.first {
            visible += String(start + 1)
        }
        if let end = chapters.last, end != chapters.first {
            visible += "-"
            visible += String(end + 1)
        }
        
        titleDisplay.chapter = visible
        
        
    }
    @objc func onChapterChange(notification: Notification) {
//        guard let node, let chapter = notification.object as? Int else {
//            return
//        }
//        
////        Defaults[.book] = chapter
//        DispatchQueue.main.async {
//            let visible = node.store.books.currentPageIndex
//            let node = node.store.books.nodeForPage(at: visible) as? BookCellNode
//            let cell = node?.store.chapters.nodeForRow(at: .init(row: chapter - 1, section: 0)) as? ChapterCellNode
//            cell?.isExpanded = true
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//
//            node?.store.chapters.scrollToRow(at: .init(row: chapter - 1, section: 0),
//                                             at: .top,
//                                             animated: false)
////            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
////                cell?.isExpanded = true
//            }
//        }

    }
    
    /*
        
        stopSelecting
     */
    
    func changeBook(_ book: Int) {
        node.store.books.scrollToPage(at: book - 1, animated: false)

    }
    func stopSelecting() {
        guard let selection  else { return }
        
        let bookCell = node.store.books.nodeForPage(at: selection.book - 1) as! BookCellNode
        let chapterCell = bookCell.store.chapters.nodeForRow(at: .init(row: selection.chapter - 1, section: 0)) as! ChapterCellNode
        chapterCell.store.text.selectedRange = .init()
        
        
        node.store.showingControls = false
    }
    
    func highlightSelection(color: HighlightColor) {
        guard let selection  else { return }
          
        let bookCell = node.store.books.nodeForPage(at: selection.book - 1) as! BookCellNode
        let chapterCell = bookCell.store.chapters.nodeForRow(at: .init(row: selection.chapter - 1, section: 0)) as! ChapterCellNode
        let range = selection.range
        
        chapterCell.store.text.textView.textStorage.beginEditing()
        chapterCell.store.text.textView.textStorage.addAttribute(.highlight, value: color.uiColor.withAlphaComponent(0.2), range: range)
        chapterCell.store.text.textView.textStorage.endEditing()
            
        
        do {
           let record = HighlightRecord(id: UUID(),
                                        version: selection.version,
                                        book: selection.book,
                                        chapter: selection.chapter,
                                        startVerse: 0,
                                        endVerse: 0,
                                        startOffset: range.location,
                                        endOffset: range.location + range.length,
                                        color: color)
            
            
            try AppDatabase.shared.database.write { db in
                try record.inserted(db)
            }
        } catch {
            
        }
    }
    
    func eraseSelection() {
        guard let selection  else { return }

        let bookCell = node.store.books.nodeForPage(at: selection.book - 1) as! BookCellNode
        let chapterCell = bookCell.store.chapters.nodeForRow(at: .init(row: selection.chapter - 1, section: 0)) as! ChapterCellNode
        let range = selection.range

        chapterCell.store.text.textView.textStorage.beginEditing()
        chapterCell.store.text.textView.textStorage.removeAttribute(.highlight, range: range)
        chapterCell.store.text.textView.textStorage.endEditing()

        
        do {
            let highlights = try AppDatabase.shared.reader.read { db in
                let sql = """
                          """
                try HighlightRecord.fetchAll(db, sql: sql)
                    
            }
        } catch {
            
        }
    }
    
 
    
    func bookmarkSelection() {
        // send this somewhere else
        
        guard let selection  else { return }

        let bookCell = node.store.books.nodeForPage(at: selection.book - 1) as! BookCellNode
        let chapterCell = bookCell.store.chapters.nodeForRow(at: .init(row: selection.chapter - 1, section: 0)) as! ChapterCellNode
        let range = selection.range

        let locator =  RangeLocator(version: selection.version,
                                    book: selection.book,
                                    chapter: selection.chapter,
                                    range: range)

        let prevBookmark = Defaults[.bookmark]
            
            
        if let prevBookmark,
           let priorBookCell = node.store.books.nodeForPage(at: prevBookmark.book - 1) as? BookCellNode,
           let possiblePriorChapterNode = priorBookCell.store.chapters.nodeForRow(at: .init(row: prevBookmark.chapter - 1, section: 0)) as? ChapterCellNode {
            possiblePriorChapterNode.store.text.textView.textStorage.removeAttribute(.bookmark, range: prevBookmark.range)
            
        }
            
        chapterCell.store.text.textView.textStorage.beginEditing()

            if prevBookmark == nil || prevBookmark !=  locator {
                Defaults[.bookmark] = locator
                chapterCell.store.text.textView.textStorage.addAttribute(.bookmark, value: UIColor(Color.blue), range: range)
                
                node.store.bookmark.setImage(UIImage(systemName: "bookmark.fill",
                                                withConfiguration: Constant.selectBarConfig)?.tinted(UIColor(Color.blue)), for: .normal)

            } else {
                Defaults[.bookmark] = nil
                
                node.store.bookmark.setImage(UIImage(systemName: "bookmark",
                                                withConfiguration: Constant.selectBarConfig)?.tinted(UIColor(Color.blue)), for: .normal)

            }
            
        chapterCell.store.text.textView.textStorage.endEditing()

        
    }
    
    
    
    
    
    deinit {
        NotificationCenter.default
                            .removeObserver(self,
                                            name: .changeBook ,
                                            object: nil)
        NotificationCenter.default
                            .removeObserver(self,
                                            name: .changeChapter ,
                                            object: nil)
        NotificationCenter.default
                            .removeObserver(self,
                                            name: .changeSelection,
                                            object: nil)
        NotificationCenter.default
                            .removeObserver(self,
                                            name: .displayChapters,
                                            object: nil)
        NotificationCenter.default
                            .removeObserver(self,
                                            name: .addNote,
                                            object: nil)
    }
}


class TitleButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            print(isHighlighted)
            if oldValue == false && isHighlighted {
                highlight()
            } else if oldValue == true && !isHighlighted {
                unHighlight()
            }
        }
    }

    var highlightDuration: TimeInterval = 0.18

    func highlight() {
        // Animate changes for highlighting
        UIView.animate(withDuration: highlightDuration) {
            self.titleLabel?.alpha = 0.1
            self.imageView?.alpha = 0.1
        }
    }

    func unHighlight() {
        // Animate changes for un-highlighting
        UIView.animate(withDuration: highlightDuration) {
            self.titleLabel?.alpha = 1
            self.imageView?.alpha = 1
        }
    }
}




func buildChapter(_ book: Int, _ chapter: Int) -> NSAttributedString? {
    // fetch and build string here?
    
    let value: [VerseTextRecord]? =  try? AppDatabase.shared.reader.read { db in
        let sql = """
            SELECT verse, text
            FROM verses
            WHERE book IS ?
            AND chapter IS ?
            """
        return try VerseTextRecord.fetchAll(db, sql: sql, arguments: [book, chapter])
     }
    
    
    guard let value, !value.isEmpty else {
        return nil
    }
    
    
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 4
    paragraphStyle.lineBreakStrategy = .hangulWordPriority
    paragraphStyle.firstLineHeadIndent = 5
    paragraphStyle.alignment = .justified
    
    let font = Constant.bodyFont()
    var numberFont = UIFont.systemFont(ofSize: 13, weight: .medium)
    if #available(iOS 16.0, *) {
        numberFont = UIFont.systemFont(ofSize: 13, weight: .medium)
    }

    let string = NSMutableAttributedString()

    for verse in value  {
        var verseNumber = NSAttributedString(string: String(verse.verse), attributes: [
                                                .font: numberFont,
                                              .foregroundColor: UIColor.tertiaryLabel,
                                                .baselineOffset: CGFloat(4),
                                                .tracking: CGFloat(3),
                                              .paragraphStyle: paragraphStyle,
                                                .verse: verse.verse])
        if verse.verse >= 10 {
            let string = NSMutableAttributedString()

            let start = verse.verse / 10
            let end = verse.verse % 10
            let startDigits = NSAttributedString(string: String(start), attributes: [
                                                    .font: numberFont,
                                                  .foregroundColor: UIColor.tertiaryLabel,
                                                    .baselineOffset: CGFloat(4),
    //                                                .tracking: CGFloat(3),
                                                  .paragraphStyle: paragraphStyle,
                                                    .verse: verse.verse])
            var endDigit = NSAttributedString(string: String(end), attributes: [
                                                    .font: numberFont,
                                                  .foregroundColor: UIColor.tertiaryLabel,
                                                    .baselineOffset: CGFloat(4),
                                                    .tracking: CGFloat(3),
                                                  .paragraphStyle: paragraphStyle,
                                                    .verse: verse.verse])
            string.append(startDigits)
            string.append(endDigit)
            
            verseNumber = string

        }
        
        let verseText = NSAttributedString(string: verse.text,
                                           attributes: [.font: font,
                                                        .paragraphStyle: paragraphStyle,
                                                        .verse: verse.verse])

        string.append(NSAttributedString(string: " ", attributes: [.font: font, .paragraphStyle: paragraphStyle]))
        string.append(verseNumber)
        string.append(verseText)
    }
    
    if let bookmark = Defaults[.bookmark],
       bookmark.book == book,
       bookmark.chapter == chapter  {
        string.addAttribute(.bookmark, value: UIColor(Color.blue), range: bookmark.range)
    }

    let highlights: [HighlightRecord]? =  try? AppDatabase.shared.reader.read { db in
        let sql = """
            SELECT *
            FROM highlights
            WHERE version IS ?
            AND book IS ?
            AND chapter IS ?
            """
        return try HighlightRecord.fetchAll(db, sql: sql, arguments: [BibleVersion.kjv.rawValue, book, chapter])
     }
    
    if let highlights, !highlights.isEmpty {
        for highlight in highlights {
            let range = NSRange(location: highlight.startOffset, length: highlight.endOffset - highlight.startOffset)
            string.addAttribute(.highlight, value: highlight.color.uiColor.withAlphaComponent(0.2), range: range)
        }
    }
    
    let notes: [NoteRecord]? =  try? AppDatabase.shared.reader.read { db in
        let sql = """
            SELECT *
            FROM notes
            WHERE version IS ?
            AND book IS ?
            AND chapter IS ?
            """
        return try NoteRecord.fetchAll(db, sql: sql, arguments: [BibleVersion.kjv.rawValue, book, chapter])
     }
    
    if let notes, !notes.isEmpty {
        for note in notes {
            let range = NSRange(location: note.startOffset, length: note.endOffset - note.startOffset)
            string.addAttribute(.underlineColor, value: UIColor.systemGray3, range: range)
            string.addAttribute(.underlineStyle, value: NSUnderlineStyle.thick.rawValue, range: range)
        }
    }

    return string
    
}



