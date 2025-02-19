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
    
    init(size: CGSize) {
        self.size = size
        super.init()
        self.automaticallyManagesSubnodes = true
        self.automaticallyRelayoutOnSafeAreaChanges = true
        self.automaticallyRelayoutOnLayoutMarginsChanges = true
        store.books.setDelegate(self)
        store.books.setDataSource(self)

    }
    
    let size: CGSize
    
    class HighlightButton: ASButtonNode {
        var color: HighlightColor
        
        init(color: HighlightColor) {
            self.color = color
            super.init()
        }
    }
    class Store {
        var numBooks = Int(0)
        var books = ASPagerNode()
        
        var baseControls = ASDisplayNode()
        var highlightControls = ASDisplayNode()
        var controls = ASDisplayNode()
        var bookmark = ASButtonNode()

        var highlight = ASButtonNode()
        var highlightButtons = [HighlightButton]()
        var highlightEraser = ASButtonNode()
        var highlightBack = ASButtonNode()

        var crossReferences = ASButtonNode()
        var note = ASButtonNode()
        var close = ASButtonNode()
        var controlsBackground = ASDisplayNode()

        let semaphore = DispatchSemaphore(value: 1)
        
        var showingHighlightControls: Bool = false {
            didSet {
                let showingHighlightControls = showingHighlightControls
                let size = controls.calculatedSize.width

                UIView.animate(withDuration: 0.7
                               ,
                               delay: 0,
                               usingSpringWithDamping: 0.9,
                               initialSpringVelocity: 0) { [unowned highlightControls, unowned baseControls] in
                                        highlightControls.transform = showingHighlightControls ? CATransform3DIdentity : CATransform3DMakeTranslation(size, 0, 0)
                    baseControls.transform = showingHighlightControls ? CATransform3DMakeTranslation(-size, 0, 0) : CATransform3DIdentity
                }
            }
        }
        
        var showingControls = true {
            didSet {
                let showingControls = showingControls
                let transform = showingControls ? CATransform3DIdentity : CATransform3DMakeTranslation(0, 300, 0)
    //            UIView.animate(springDuration: 0.9) { [store] in
    //                store.controls.transform = transform
    //            }
//                controls.transform = transform
                UIView.animate(withDuration: 0.7
                               ,
                               delay: 0,
                               usingSpringWithDamping: 0.9,
                               initialSpringVelocity: 0) { [unowned controls] in
                    controls.transform = transform
                }
                
                if !showingControls && showingHighlightControls {
                    showingHighlightControls = false
                }
            }
        }
    }
    
    let store = Store()
    let BATCH_SIZE = 3
    var keepFetchingBatches: Bool = true
    
    var isFirstDisplay = true
    
    
    override func didLoad() {
        super.didLoad()
        store.showingControls = false

//        store.books.style.flexGrow = 1
        store.books.style.width = .init(unit: .fraction, value: 1)
//        store.books.style.height = .init(unit: .fraction, value: 1)
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
        
        store.baseControls.automaticallyManagesSubnodes = true
        store.baseControls.layoutSpecBlock = { [store] node, range in
            let stack = ASStackLayoutSpec.horizontal()
            stack.children = [store.bookmark, store.highlight, store.note, store.crossReferences,  store.close]
            stack.justifyContent = .spaceBetween
            stack.alignItems = .center
            stack.style.width = .init(unit: .fraction, value: 1)
            return stack
        }
        store.baseControls.clipsToBounds = true

        store.highlightControls.automaticallyManagesSubnodes = true
        store.highlightControls.layoutSpecBlock = { [store] node, range in
            let stack = ASStackLayoutSpec.horizontal()
            stack.children = [store.highlightEraser,] + store.highlightButtons + [ store.highlightBack]
            stack.justifyContent = .spaceBetween
            stack.alignItems = .center
            stack.style.width = .init(unit: .fraction, value: 1)
            return stack
        }
        store.highlightControls.clipsToBounds = true

        
        store.controls.automaticallyManagesSubnodes = true
        store.controls.automaticallyRelayoutOnSafeAreaChanges = true
        store.controls.layoutSpecBlock = { [store] node, range in
//            let stack = ASStackLayoutSpec.horizontal()
//            if store.showingHighlightControls {
//                stack.children = [store.highlightEraser,] + store.highlightButtons + [ store.highlightBack]
//            } else {
//                stack.children = [store.bookmark, store.highlight, store.note, store.crossReferences,  store.close]
//            }
//            stack.justifyContent = .spaceBetween
//            stack.alignItems = .center
            
            let absolute = ASAbsoluteLayoutSpec(sizing: .sizeToFit, children: [store.highlightControls, store.baseControls])
            absolute.style.width = .init(unit: .fraction, value: 1)
//            let safeArea = node.supernode?.safeAreaInsets.bottom ?? 0
            let safeArea = node.safeAreaInsets.bottom
            let inset = ASInsetLayoutSpec(insets: .init(top: 13, left: 15, bottom: 3 + safeArea, right: 15),
                              child: absolute)
            let background = ASBackgroundLayoutSpec(child: inset, background: store.controlsBackground)
//            let outerInset = ASInsetLayoutSpec(insets: .init(top: 0, left: 15, bottom: 0, right: 15),
//                              child: background)
            return background
        }
        
        store.controls.style.width = .init(unit: .fraction, value: 1)
        store.controls.layer.shadowColor = UIColor.systemGray.cgColor
        store.controls.layer.shadowRadius = 4
        store.controls.layer.shadowOpacity = 0.5
        store.controls.layer.shadowOffset = .init(width: 0, height: 2)
//        store.controls.style.height = .init(unit: .points, value: 80)
        
        let hasDefault = Defaults[.bookmark] != nil
        store.bookmark.setImage(UIImage(systemName: "bookmark\(hasDefault ? ".fill" : "")",
                                        withConfiguration: Constant.selectBarConfig)?.tinted(UIColor(Color.blue)), for: .normal)
        store.bookmark.style.preferredSize = .init(width: 44, height: 44)
        store.bookmark.addTarget(self, action: #selector(onBookmark), forControlEvents: .touchUpInside)

        let highlightButton = UIButton.init(type: .custom)
        
//        let hConfig = config //.applying(UIImage.SymbolConfiguration(paletteColors: [ UIColor.label, UIColor(Color.yellow)]))
        let hImage = UIImage(systemName: "square.fill")?.applyingSymbolConfiguration(Constant.selectBarConfig)?.tinted(Defaults[.highlight].uiColor)
        store.highlight.setImage(hImage, for: .normal)
//        highlightButton.menu = UIMenu(children: [UIAction(title: "Empty", handler: { _ in })])
        store.highlight.addTarget(self, action: #selector(onHighlight), forControlEvents: .touchUpInside)
//        store.highlight = ASDisplayNode { highlightButton }
//            .applying(UIImage.SymbolConfiguration(hierarchicalColor: UIColor(Color.yellow))))?.tinted(UIColor.label),
//            .applying(UIImage.SymbolConfiguration(paletteColors: [ UIColor(Color.yellow), UIColor.secondaryLabel])))?.tinted(UIColor.label),
                               
        store.highlight.style.preferredSize = .init(width: 44, height: 44)

        
        for color in HighlightColor.allCases {
            
            let image = UIImage(systemName: "square.fill")?.applyingSymbolConfiguration(Constant.selectBarConfig)?.tinted(color.uiColor)

            let button = HighlightButton(color: color)
            button.setImage(image, for: .normal)
            button.style.preferredSize = .init(width: 44, height: 44)
            button.addTarget(self, action: #selector(onHighlightButton), forControlEvents: .touchUpInside)

            store.highlightButtons.append(button)
        }

        let eraserImage = UIImage(systemName: "eraser.fill")?.applyingSymbolConfiguration(Constant.selectBarConfig)
        store.highlightEraser.setImage(eraserImage, for: .normal)
        store.highlightEraser.style.preferredSize = .init(width: 44, height: 44)
        store.highlightEraser.addTarget(self, action: #selector(onHighlightErase), forControlEvents: .touchUpInside)

        let highlightBackImage = UIImage(systemName: "chevron.right.circle.fill")?.applyingSymbolConfiguration(Constant.selectBarBigConfig.applying(UIImage.SymbolConfiguration(hierarchicalColor: .secondaryLabel)))?.tinted(.secondaryLabel)
        store.highlightBack.setImage(highlightBackImage, for: .normal)
        store.highlightBack.style.preferredSize = .init(width: 44, height: 44)
        store.highlightBack.addTarget(self, action: #selector(onHighlightBack), forControlEvents: .touchUpInside)
        
        
        
        store.crossReferences.setImage(UIImage(systemName: "line.3.horizontal", withConfiguration: Constant.selectBarConfig)?.tinted(UIColor.label), for: .normal)
        store.crossReferences.style.preferredSize = .init(width: 44, height: 44)
        store.crossReferences.addTarget(self, action: #selector(onCrossReferences), forControlEvents: .touchUpInside)
       
        store.note.setImage(UIImage(systemName: "square.and.pencil", withConfiguration: Constant.selectBarConfig)?.tinted(UIColor.label), for: .normal)
        store.note.transform = CATransform3DMakeTranslation(0, -2, 0)
        store.note.style.preferredSize = .init(width: 44, height: 44)
        store.note.addTarget(self, action: #selector(onNote), forControlEvents: .touchUpInside)

        store.close.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: Constant.selectBarBigConfig.applying(UIImage.SymbolConfiguration(hierarchicalColor: .secondaryLabel)))?.tinted(.secondaryLabel), for: .normal)
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
    
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
//        let inset = ASInsetLayoutSpec(insets: .init(top: 0, left: 0, bottom: safeAreaInsets.bottom, right: 0), child: store.controls)
//        let background = ASBackgroundLayoutSpec(child: inset, background: store.controlsBackground)

        let relative = ASRelativeLayoutSpec(horizontalPosition: .center,
                                            verticalPosition: .end,
                                            sizingOption: .minimumHeight,
                                            child: store.controls)
        let overlay = ASOverlayLayoutSpec(child: store.books,
                                          overlay: relative)
        return overlay
    }
    
  
    
    
    @objc func onClose() {
        let vc = self.closestViewController as? ContentViewController
        vc?.stopSelecting()
        
    }
    
    @objc func onHighlight() {
        let vc = self.closestViewController as? ContentViewController
        store.showingHighlightControls = true
        let color = Defaults[.highlight]
        
        vc?.highlightSelection(color: color)
    }
    
    
    @objc func onHighlightBack() {
        store.showingHighlightControls = false
    }
    
    
    @objc func onNote() {
        let controller = ASNavigationController(rootViewController: NoteInputController())
        self.closestViewController?.present(controller, animated: true)
    }
    
    @objc func onCrossReferences() {
        let controller = UIHostingController(rootView: Color.white)
        self.closestViewController?.present(controller, animated: true)
    }
    
    
    @objc func onHighlightButton(button: HighlightButton) {
        let vc = self.closestViewController as? ContentViewController
        Defaults[.highlight] = button.color
        
        let hImage = UIImage(systemName: "square.fill")?.applyingSymbolConfiguration(Constant.selectBarConfig)?.tinted(button.color.uiColor)
        store.highlight.setImage(hImage, for: .normal)

        vc?.highlightSelection(color: button.color)
    }
    
    @objc func onHighlightErase() {
        let vc = self.closestViewController as? ContentViewController
        vc?.eraseSelection()

    }
    
 
    
    @objc func onBookmark() {
        let vc = self.closestViewController as? ContentViewController
        vc?.bookmarkSelection()

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
        let width = size.width
        
        return {
            return BookCellNode(book: index + 1, width: width)
            
        }
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        print("select")
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, willDisplayItemWith node: ASCellNode) {

        if isFirstDisplay {
            isFirstDisplay = false
            
            let book = Defaults[.book]
            store.books.scrollToItem(at:.init(row:  book - 1, section: 0),
                                     at: .left,
                                     animated: false)

            store.highlightControls.transform = CATransform3DMakeTranslation(self.view.frame.width, 0, 0)
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
