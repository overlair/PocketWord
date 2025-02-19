//
//  BookCellNode.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import Defaults
import AsyncDisplayKit

class BookCellNode: ASCellNode, ASTableDelegate, ASTableDataSource {
    let book: Int
    let width: CGFloat
    init(book: Int, width: CGFloat) {
        self.book = book
        self.width = width
        super.init()
        self.automaticallyManagesSubnodes  = true
        self.automaticallyRelayoutOnSafeAreaChanges = true
        self.style.flexGrow = 1
        self.selectionStyle = .none

        store.chapters.delegate = self
        store.chapters.dataSource = self
//        store.chapters.contentInset.top = Constant.bookFont().lineHeight + Constant.bookInset.top + Constant.bookInset.bottom

    }
    
    let store = Store()
    class Store {
        lazy var book = ASTextNode()
        lazy var visibleChapters = ASTextNode()
        lazy var chapters = ASTableNode()
        lazy var openIndicator = ASImageNode()
        lazy var divider = ASDisplayNode()
        lazy var header = ASDisplayNode()
        lazy var bookBackground = ASDisplayNode()

        var chapterText = [Int: NSAttributedString]()
        var numChapters = 0
        
        let semaphore = DispatchSemaphore(value: 1)
    }
    
    let HEADER_FONT_SIZE = CGFloat(21)
    let BATCH_SIZE = 4
    var keepFetchingBatches: Bool = true
    
    @objc func onBookOutside() {
        store.header.layer.opacity = 1
    }
     
    @objc func onBookDown() {
        store.header.layer.opacity = 0.2
    }
    
    @objc func onBook() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [store] in
            store.header.layer.opacity = 1
        }

        print("SELECT")
        let controller = ASNavigationController(rootViewController: MenuViewController())

        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred(intensity: 0.8)
        impact.impactOccurred()

        self.closestViewController?.present(controller, animated: true)
    }
    override func didLoad() {
        super.didLoad()
        
        store.openIndicator.image = UIImage(systemName: "chevron.up.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .secondaryLabel))?.tinted(.label)
        store.openIndicator.style.preferredSize = .init(width: 30, height: 30)
       
        store.book.style.width = .init(unit: .fraction, value: 1)
        store.book.textContainerInset =  Constant.bookInset
        store.book.addTarget(self, action: #selector(BookCellNode.onBook), forControlEvents: .touchUpInside)
        store.book.addTarget(self, action: #selector(BookCellNode.onBookDown), forControlEvents: .touchDown)
        store.book.addTarget(self, action: #selector(BookCellNode.onBookOutside), forControlEvents: .touchUpOutside)
        store.book.addTarget(self, action: #selector(BookCellNode.onBookOutside), forControlEvents: .touchCancel)

        
        store.chapters.backgroundColor = .clear
        store.chapters.style.flexGrow = 1
//        store.chapters.cornerRadius = 17
//        store.chapters.layer.cornerCurve = .continuous
//        store.chapters.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
//        store.chapters.clipsToBounds = true
        
//        store.chapters.view.separatorStyle = .none
        store.chapters.view.separatorStyle = .singleLine
        store.chapters.view.separatorColor = .systemGray6
        store.chapters.view.separatorInset = .init(top: 0, left: 30, bottom: 0, right: 0)
        store.chapters.contentInset = .init(top: 24, left: 0, bottom: 100, right: 0)
//        store.title.style.flexGrow = 1

        
        store.visibleChapters.textContainerInset = .init(top: 9, left: 23, bottom: 9, right: 0)

        store.divider.backgroundColor = .systemGray6
        store.divider.style.width = .init(unit: .fraction, value: 1)
        store.divider.style.height = .init(unit: .points, value: 2)
        
        
        let effect = UIBlurEffect(style: .systemThinMaterial)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        store.bookBackground = ASDisplayNode {
            effectView
        }
        store.bookBackground.style.flexGrow = 1
        
        
        
        store.header.automaticallyManagesSubnodes = true
        store.header.layoutSpecBlock = { [store] node, range in
            let overlayStack  = ASStackLayoutSpec.horizontal()
            overlayStack.children = [ store.visibleChapters, store.openIndicator]
            overlayStack.alignItems = .center
            overlayStack.spacing = 7
            
            let overlayInset = ASInsetLayoutSpec(insets: .init(top: 0, left: 0, bottom: 0, right: 13), child: overlayStack)
            let relative = ASRelativeLayoutSpec(horizontalPosition: .end, verticalPosition: .center, sizingOption: .minimumHeight, child: overlayInset)
            let overlay = ASOverlayLayoutSpec(child: store.book, overlay: relative)
            let safeArea = node.supernode?.safeAreaInsets ?? node.safeAreaInsets
            overlay.style.minHeight = .init(unit: .points, value: Constant.bookFont().lineHeight + Constant.bookInset.top + Constant.bookInset.bottom)

            let backgroundInset = ASInsetLayoutSpec(insets: .init(top: safeArea.top, left: 0, bottom: 0, right: 0), child: overlay)
            backgroundInset.style.width = .init(unit: .fraction, value: 1)

            return ASBackgroundLayoutSpec(child: backgroundInset, background: store.bookBackground)

        }
        store.header.style.flexGrow = 1
        
        do {
            let version = Defaults[.version]
            let name = try AppDatabase.shared.reader.read { db in
                let table = "\(version)_books"
                let sql = """
                          SELECT name
                          FROM books
                          WHERE id IS ?
                          """
                return try String.fetchOne(db, sql: sql, arguments: [book])
            }
            
            print(name)
            if let name {
                store.book.attributedText = .init(string: name, attributes: [.font: Constant.bookFont()])
            }
            
            let chapters = try AppDatabase.shared.reader.read { db in
                let table = "\(version)_verses"
                let sql = """
                    SELECT MAX(chapter)
                    FROM verses
                    WHERE book IS ?
                    """
                return try Int.fetchOne(db, sql: sql, arguments: [book])
            }
            
            if let chapters {
                store.numChapters = chapters
            }
            
            let range = Array(0..<BATCH_SIZE)

            let strings: [(Int, Int, NSAttributedString)] = range.compactMap {
                
                guard let chapter = buildChapter(book, $0 + 1) else {
                    return nil
                }
                
                return ($0, $0 + 1, chapter)
                
            }
            if store.numChapters > 0 {
                keepFetchingBatches = store.chapterText.keys.count + strings.count < store.numChapters
            }
            let paths = strings.map { IndexPath(row: $0.0, section: 0)}
    //        store.semaphore.signal()

//            DispatchQueue.main.async { [store] in
                for (index, chapter, string) in strings {
                    store.chapterText[chapter] = string
                }
                store.chapters.insertRows(at: paths, with: .left)
    //            store.semaphore.signal()
                self.updateVisibleChapters()
//            }
            
        } catch {
            
        }
        
        store.header.setNeedsLayout()

    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let headerHeight = safeAreaInsets.top + Constant.bookFont().lineHeight + Constant.bookInset.top + Constant.bookInset.bottom
        let header = store.header
        header.style.width = .init(unit: .fraction, value: 1)
        header.style.height = .init(unit: .points, value: headerHeight)
        
        let headerRelative = ASRelativeLayoutSpec(horizontalPosition: .center,
                                                  verticalPosition: .start,
                                                  sizingOption: .minimumHeight,
                                                  child: header)

        let contentInset = ASInsetLayoutSpec(insets: .init(top: headerHeight, left: 0, bottom: 0, right: 0),  child: store.chapters)
        let content = ASOverlayLayoutSpec(child: contentInset, overlay: headerRelative)

        let dividerInset = ASInsetLayoutSpec(insets: .init(top: 0, left: 15, bottom: 0, right: 15), child: store.divider)

        let stack = ASStackLayoutSpec.vertical()
        stack.children = [dividerInset, store.chapters]
        var insets = safeAreaInsets
        insets.bottom = 0
//        return ASInsetLayoutSpec(insets: .zero, child: content)
        return ASInsetLayoutSpec(insets: insets, child: stack)

    }
    
    override func layout() {
        super.layout()
    }
    
    
    override func didEnterPreloadState() {
        super.didEnterPreloadState()
        guard store.chapterText.isEmpty else { return }
//        store.semaphore.wait()

//        let range = Array(0..<BATCH_SIZE)
//
//        let strings: [(Int, Int, NSAttributedString)] = range.compactMap {
//            
//            guard let chapter = buildChapter(book, $0 + 1) else {
//                return nil
//            }
//            
//            return ($0, $0 + 1, chapter)
//            
//        }
//        if store.numChapters > 0 {
//            keepFetchingBatches = store.chapterText.keys.count + strings.count < store.numChapters
//        }
//        let paths = strings.map { IndexPath(row: $0.0, section: 0)}
////        store.semaphore.signal()
//
//        DispatchQueue.main.async { [store] in
//            for (index, chapter, string) in strings {
//                store.chapterText[chapter] = string
//            }
//            store.chapters.insertRows(at: paths, with: .left)
////            store.semaphore.signal()
//            self.updateVisibleChapters()
//        }
    }
    
    func shouldBatchFetch(for tableNode: ASTableNode) -> Bool {
        keepFetchingBatches
    }
    
    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        context.beginBatchFetching()
//        store.semaphore.wait()

        let offset = store.chapterText.count
        let range = Array(offset..<offset + BATCH_SIZE)


        let strings: [(Int, Int, NSAttributedString)] = range.compactMap {
            
            guard let chapter = buildChapter(book, $0 + 1) else {
                return nil
            }
            
            return ($0, $0 + 1, chapter)
            
        }
        
        keepFetchingBatches = store.chapterText.keys.count + strings.count < store.numChapters

        let paths = strings.map { IndexPath(row: $0.0, section: 0)}

//        store.semaphore.signal()
        DispatchQueue.main.async { [store] in
            for (index, chapter, string) in strings {
                store.chapterText[chapter] = string
            }
//            store.semaphore.wait()
            store.chapters.insertRows(at: paths, with: .left)
           
           
//            store.semaphore.signal()
            context.completeBatchFetching(true)
            
        }
        
    }
    
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        1
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        store.chapterText.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let width = width
        let book = book
        let chapter = indexPath.row + 1
        let text = store.chapterText[chapter]
        return { ChapterCellNode(book: book, chapter: chapter, width: width, string: text) }
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred(intensity: 0.5)

        (tableNode.nodeForRow(at: indexPath) as? ChapterCellNode)?.isExpanded.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateVisibleChapters()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        print("BEGING DRAGGNIG")
        UIMenuController.shared.hideMenu()
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateVisibleChapters()
            attemptShowEditMenu()
        }
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateVisibleChapters()
        attemptShowEditMenu()
    }
    
    func attemptShowEditMenu() {
        guard let node = store.chapters.visibleNodes.compactMap { node in node as? ChapterCellNode }.filter {  node in node.store.text.selectedRange.length > 0 }.first,
        let indexPath = node.indexPath,
        let position = node.store.text.textView.position(from: node.store.text.textView.beginningOfDocument,
                                                         offset: node.store.text.selectedRange.location)
        else {
            return
        }
        
        let cellRect = store.chapters.rectForRow(at: indexPath).minY
        let rect = node.store.text.textView.caretRect(for: position)
        let offset = store.chapters.contentOffset.y - 80
        let height = store.chapters.calculatedSize.height - 80
        let cellOffset = cellRect + rect.minY

        if cellOffset > offset && cellOffset < offset + height {
            UIMenuController.shared.showMenu(from: node.store.text.textView, rect: rect)
        }
                        
        
    }
    
    func updateVisibleChapters() {
//        let chapters = store.chapters.visibleNodes.compactMap { $0.indexPath }.map { $0.row }.sorted()
//        var visible = ""
//        if let start = chapters.first {
//            visible += String(start + 1)
//        }
//        if let end = chapters.last, end != chapters.first {
//            visible += "-"
//            visible += String(end + 1)
//        }
        
        print(book)
        NotificationCenter.default
            .post(name: .displayChapters,
                    object: nil)
        
        
//        store.visibleChapters.attributedText = .init(string: visible, attributes: [.font: Constant.labelFont(size: 21),
//                                                                                   .foregroundColor: UIColor.quaternaryLabel])

    }
}
