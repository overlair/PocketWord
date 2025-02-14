//
//  ContentViewController.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import AsyncDisplayKit

class ContentViewController: ASDKViewController<BooksNode> {
    override init() {
        super.init(node: BooksNode())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        
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

    }
    
    
    @objc func onSelectionChange(notification: Notification) {
//        guard let string = notification.object as? String else {
//            return
//        }
//
//        if node.showingControls != !string.isEmpty {
//            node.showingControls = !string.isEmpty
//        }
//        print(string)
        
    }
    
    @objc func onBookChange(notification: Notification) {
//        guard let book = notification.object as? Int else {
//            return
//        }
//        
//        Defaults[.book] = book
//        
//        node.store.books.scrollToPage(at: book - 1, animated: false)
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
    var numberFont = UIFont.systemFont(ofSize: 13, weight: .bold)
    if #available(iOS 16.0, *) {
        numberFont = UIFont.systemFont(ofSize: 13, weight: .bold, width: .condensed)
    }

    let string = NSMutableAttributedString()

    for verse in value  {
        let verseNumber = NSAttributedString(string: " " + String(verse.verse) + " ", attributes: [
                                                .font: numberFont,
                                              .foregroundColor: UIColor.tertiaryLabel,
                                                .baselineOffset: CGFloat(3),
                                              .paragraphStyle: paragraphStyle,
                                                .verse: verse.verse])
        let verseText = NSAttributedString(string: verse.text,
                                           attributes: [.font: font,
                                                        .paragraphStyle: paragraphStyle,
                                                        .verse: verse.verse])

        string.append(verseNumber)
        string.append(verseText)
    }
    return string
    
}
