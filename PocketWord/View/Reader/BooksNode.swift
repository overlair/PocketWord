//
//  BooksNode.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import AsyncDisplayKit
import Defaults
import SwiftUI


class BooksNode: ASDisplayNode,
                   ASPagerDelegate,
                   ASPagerDataSource {
    
    override init() {
        super.init()
        self.automaticallyManagesSubnodes = true
        self.automaticallyRelayoutOnSafeAreaChanges = true
        store.books.setDelegate(self)
        store.books.setDataSource(self)

    }
    
    class Store {
        var numBooks = Int(0)
        var books = ASPagerNode()
        
        var controls = ASDisplayNode()
        var highlight = ASDisplayNode()
        var bookmark = ASButtonNode()
        
        var crossReferences = ASButtonNode()
        var note = ASButtonNode()
        var close = ASButtonNode()
        var controlsBackground = ASDisplayNode()

        let semaphore = DispatchSemaphore(value: 1)
    }
    
    let store = Store()
    let BATCH_SIZE = 3
    var keepFetchingBatches: Bool = true
    
    var isFirstDisplay = true
    var showingControls = true {
        didSet {
            let showingControls = showingControls
            let transform = showingControls ? CATransform3DIdentity : CATransform3DMakeTranslation(0, 300, 0)
//            UIView.animate(springDuration: 0.9) { [store] in
//                store.controls.transform = transform
//            }
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0) { [store] in
                store.controls.transform = transform
            }
        }
    }
    
    override func didLoad() {
        super.didLoad()
        showingControls = false

//        store.books.style.flexGrow = 1
        store.books.style.width = .init(unit: .fraction, value: 1)
        store.books.style.height = .init(unit: .fraction, value: 1)
        store.books.backgroundColor = .clear
        store.books.allowsSelection = true


        let effect = UIBlurEffect(style: .systemUltraThinMaterial)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        store.controlsBackground = ASDisplayNode {
            effectView
        }
        store.controlsBackground.style.flexGrow = 1
        store.controlsBackground.cornerRadius = 23
        store.controlsBackground.layer.cornerCurve = .continuous
        store.controlsBackground.clipsToBounds = true
        
        store.controls.automaticallyManagesSubnodes = true
        store.controls.layoutSpecBlock = { [store] node, range in
            let stack = ASStackLayoutSpec.horizontal()
            stack.children = [store.bookmark, store.highlight, store.note, store.crossReferences,  store.close]
            stack.justifyContent = .spaceBetween
            stack.alignItems = .center
            
            let inset = ASInsetLayoutSpec(insets: .init(top: 13, left: 15, bottom: 13, right: 15),
                              child: stack)
            let background = ASBackgroundLayoutSpec(child: inset, background: store.controlsBackground)
            let outerInset = ASInsetLayoutSpec(insets: .init(top: 0, left: 15, bottom: 0, right: 15),
                              child: background)
            return outerInset
        }
        
        store.controls.style.width = .init(unit: .fraction, value: 1)
        store.controls.layer.shadowColor = UIColor.systemGray.cgColor
        store.controls.layer.shadowRadius = 4
        store.controls.layer.shadowOpacity = 0.5
        store.controls.layer.shadowOffset = .init(width: 0, height: 2)
//        store.controls.style.height = .init(unit: .points, value: 80)
        
        var config = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 27, weight: .bold))
        store.bookmark.setImage(UIImage(systemName: "bookmark.fill", withConfiguration: config)?.tinted(UIColor(Color.blue)), for: .normal)
        store.bookmark.style.preferredSize = .init(width: 44, height: 44)
        store.bookmark.addTarget(self, action: #selector(onBookmark), forControlEvents: .touchUpInside)

        let highlightButton = UIButton.init(type: .custom)
        
        let hConfig = config //.applying(UIImage.SymbolConfiguration(paletteColors: [ UIColor.label, UIColor(Color.yellow)]))
        let hImage = UIImage(systemName: "square.fill")?.applyingSymbolConfiguration(hConfig)?.tinted(UIColor(Color.yellow))
        highlightButton.setImage(hImage, for: .normal)
        highlightButton.menu = UIMenu(children: [UIAction(title: "Empty", handler: { _ in })])
        highlightButton.addTarget(self, action: #selector(onHighlight), for: .touchUpInside)
        store.highlight = ASDisplayNode { highlightButton }
//            .applying(UIImage.SymbolConfiguration(hierarchicalColor: UIColor(Color.yellow))))?.tinted(UIColor.label),
//            .applying(UIImage.SymbolConfiguration(paletteColors: [ UIColor(Color.yellow), UIColor.secondaryLabel])))?.tinted(UIColor.label),
                               
        store.highlight.style.preferredSize = .init(width: 44, height: 44)

        store.crossReferences.setImage(UIImage(systemName: "line.3.horizontal", withConfiguration: config)?.tinted(UIColor.label), for: .normal)
        store.crossReferences.style.preferredSize = .init(width: 44, height: 44)
        store.crossReferences.addTarget(self, action: #selector(onCrossReferences), forControlEvents: .touchUpInside)
       
        store.note.setImage(UIImage(systemName: "square.and.pencil", withConfiguration: config)?.tinted(UIColor.label), for: .normal)
        store.note.transform = CATransform3DMakeTranslation(0, -2, 0)
        store.note.style.preferredSize = .init(width: 44, height: 44)
        store.note.addTarget(self, action: #selector(onNote), forControlEvents: .touchUpInside)

        store.close.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 33, weight: .bold)).applying(UIImage.SymbolConfiguration(hierarchicalColor: .secondaryLabel)))?.tinted(.secondaryLabel), for: .normal)
        store.close.style.preferredSize = .init(width: 44, height: 44)
        store.close.addTarget(self, action: #selector(onClose), forControlEvents: .touchUpInside)

        let version = Defaults[.version]
        let book = Defaults[.book]

        let value =  try? AppDatabase.shared.reader.read { db in
            let sql = """
                SELECT COUNT(*)
                FROM books
                """
            return try Int.fetchOne(db, sql: sql)
        }
        
        print("NUMBER BOOKS", value)
        store.numBooks = value ?? 0
        
    }
    
    @objc func onClose() {
        let bookIndex = store.books.currentPageIndex
        let bookCell = store.books.nodeForPage(at: bookIndex) as! BookCellNode
        let possibleNodes = bookCell.store.chapters.visibleNodes.compactMap { $0 as? ChapterCellNode }.filter { $0.isExpanded }
        for node in possibleNodes {
            node.store.text.selectedRange = .init()
        }
        showingControls = false
    }
    
    @objc func onHighlight() {
        let bookIndex = store.books.currentPageIndex
        let bookCell = store.books.nodeForPage(at: bookIndex) as! BookCellNode
        let possibleNode = bookCell.store.chapters.visibleNodes.compactMap { $0 as? ChapterCellNode }.filter { $0.isExpanded }.first
        if let possibleNode {
            let range = possibleNode.store.text.selectedRange
            possibleNode.store.text.textView.textStorage.beginEditing()
            possibleNode.store.text.textView.textStorage.addAttribute(.highlight, value: UIColor(Color.yellow.opacity(0.18)), range: range)
            possibleNode.store.text.textView.textStorage.endEditing()

        }
    }
    
    @objc func onBookmark() {
        let bookIndex = store.books.currentPageIndex
        let bookCell = store.books.nodeForPage(at: bookIndex) as! BookCellNode
        let possibleNode = bookCell.store.chapters.visibleNodes.compactMap { $0 as? ChapterCellNode }.filter { $0.isExpanded }.first
        if let possibleNode {
            // check iif range is bookmark, and remove if so
            // also should change a Default[] value
            let range = possibleNode.store.text.selectedRange
            let length = possibleNode.store.text.textView.textStorage.length
            possibleNode.store.text.textView.textStorage.beginEditing()
            possibleNode.store.text.textView.textStorage.removeAttribute(.bookmark, range: NSRange(location: 0, length: length))
            possibleNode.store.text.textView.textStorage.addAttribute(.bookmark, value: UIColor(Color.blue.opacity(0.2)), range: range)
//            possibleNode.store.text.textView.layoutManager.invalidateDisplay(forGlyphRange: range)
            possibleNode.store.text.textView.textStorage.endEditing()

            Defaults[.bookmark] = .init(book: bookIndex + 1, chapter: possibleNode.chapter, range: range)

        }
    }
    
    @objc func onNote() {
        let controller = UIHostingController(rootView: Color.white)
        self.closestViewController?.present(controller, animated: true)
    }
    
    @objc func onCrossReferences() {
        let controller = UIHostingController(rootView: Color.white)
        self.closestViewController?.present(controller, animated: true)

    }
    
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let inset = ASInsetLayoutSpec(insets: safeAreaInsets, child: store.controls)
        let relative = ASRelativeLayoutSpec(horizontalPosition: .center,
                                            verticalPosition: .end,
                                            sizingOption: .minimumHeight,
                                            child: inset)
        let overlay = ASOverlayLayoutSpec(child: store.books,
                                          overlay: relative)
        return overlay
    }
    
  
    func shouldBatchFetch(for collectionNode: ASCollectionNode) -> Bool {
        keepFetchingBatches
    }
    
    
    func collectionNode(_ collectionNode: ASCollectionNode, willBeginBatchFetchWith context: ASBatchContext) {
        context.beginBatchFetching()

        
    }
    
    func numberOfPages(in pagerNode: ASPagerNode) -> Int {
      
        return store.numBooks
     
    }
    


    func pagerNode(_ pagerNode: ASPagerNode, nodeBlockAt index: Int) -> ASCellNodeBlock {
        {
            return BookCellNode(book: index + 1)
            
        }
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        print("select")
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, willDisplayItemWith node: ASCellNode) {
        print(node.indexPath)
        if isFirstDisplay {
            isFirstDisplay = false
            let book = Defaults[.book]
            store.books.scrollToItem(at:.init(row:  book - 1, section: 0),
                                     at: .left,
                                     animated: false)

        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setBook(store.books.currentPageIndex + 1)
    }
    
    func setBook(_ book: Int) {
        if let vc = closestViewController as? ContentViewController {
//            vc.setChapter(book)
        }
        
        Defaults[.book] = book
    }
}
