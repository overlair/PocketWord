//
//  ChapterCellNode.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import AsyncDisplayKit

class ChapterCellNode: ASCellNode , ASEditableTextNodeDelegate {
    let book: Int
    let chapter: Int
    let width: CGFloat
    
    init(book: Int, chapter: Int, width: CGFloat, string: NSAttributedString? = nil) {
        self.book = book
        self.chapter = chapter
        self.width = width
        
        super.init()
        self.automaticallyManagesSubnodes  = true
        self.automaticallyRelayoutOnSafeAreaChanges = true
        self.style.flexGrow = 1
        self.selectionStyle = .none
        self.backgroundColor = .clear
       
        
        
        let components = ASTextKitComponents(textStorage: store.textStorage,
                                             textContainerSize: .init(width: CGFloat.infinity,
                                                                      height: CGFloat.infinity),
                                             layoutManager: store.layoutManager)
        
        let placeholder = ASTextKitComponents(attributedSeedString: nil, textContainerSize: .zero)
        store.text = ASEditableTextNode(textKitComponents: components,
                                             placeholderTextKitComponents: placeholder)
       
        if let string {
            store.textStorage.setAttributedString(string)
            store.text.style.height = .init(unit: .points, value: string.height(withConstrainedWidth: width - 30))
        }
        

    }
    
    let store = Store()
    let tapGesture = VerseTapGestureRecognizer()
    
    class Store {
        lazy var title = ASTextNode()
        lazy var text = ASEditableTextNode()
        lazy var indicator = ASImageNode()
        
        lazy var textStorage = NSTextStorage()
        lazy var layoutManager = ChapterLayoutManager()

    }
    
    var isExpanded: Bool  = false {
        didSet {
            let isExpanded = isExpanded
            
            setNeedsLayout()

            UIView.animate(withDuration: 0.6) { [store] in
                store.title.tintColor = isExpanded  ? UIColor.label : UIColor.tertiaryLabel
                    store.text.layer.opacity = isExpanded ? 1 : 0
            }

            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 5.0) { [store] in
                store.indicator.transform =  CATransform3DMakeRotation(isExpanded ? -CGFloat.pi / 2 : 0, 0, 0, -1)
            }
            
            if !isExpanded &&  store.text.selectedRange.length > 0 {
                UIMenuController.shared.hideMenu()
                store.text.resignFirstResponder()
                
                NotificationCenter.default
                    .post(name: .changeSelection,
                            object: nil)

            }
            
//            layoutIfNeeded()
        }
    }
    
    
    override var isHighlighted: Bool {
        didSet {
            print(isHighlighted)
            if oldValue == false && isHighlighted {
                highlightBackground()
            } else if oldValue == true && !isHighlighted {
                unHighlightBackground()
            }
        }
    }

    var highlightDuration: TimeInterval = 0.25

    func highlightBackground() {
        // Animate changes for highlighting
        UIView.animate(withDuration: highlightDuration) { [store] in
            store.indicator.alpha = 0.1
            store.title.alpha = 0.1
        }
    }

    func unHighlightBackground() {
        // Animate changes for un-highlighting
        UIView.animate(withDuration: highlightDuration) { [store] in
            store.indicator.alpha = 1
            store.title.alpha = 1
        }
    }
    
    @objc func bookmark() { }
    @objc func highlight() { }
    @objc func onTap(gesture: VerseTapGestureRecognizer) {
        DispatchQueue.main.async { [store] in
            if !store.text.textView.isFirstResponder {
                store.text.textView.becomeFirstResponder()
            }
            

            if let (range, verse) = gesture.tappedState,
               store.text.textView.selectedRange != range,
               let position = store.text.textView.position(from: store.text.textView.beginningOfDocument,
                                                           offset: range.location) {
                store.text.textView.selectedRange = range
                let rect = store.text.textView.caretRect(for: position)
                UIMenuController.shared.showMenu(from: store.text.textView, rect: rect)

            } else {
                
                store.text.textView.selectedRange = .init()
                UIMenuController.shared.hideMenu()
            }
        }
        
        
        
//        let location = gesture.location(in: gesture.view)
//        let position = store.text.textView.closestPosition(to: location) ?? store.text.textView.beginningOfDocument
//        let offset = store.text.textView.offset(from: store.text.textView.beginningOfDocument, to: position)
//        let length = store.text.textView.offset(from: store.text.textView.beginningOfDocument, to: store.text.textView.endOfDocument)
//        let verse = store.text.textView.textStorage.attribute(.verse, at: offset, effectiveRange: nil) as? Int
//        let range = NSRange(location: 0, length: length)
//        store.text.textView.textStorage.enumerateAttribute(.verse, in: range) { [store] value, range, shouldContinue in
//            if let v = value as? Int, v == verse {
//
//                DispatchQueue.main.asyncAfter(deadline: .now() +  0.1) {
//                    if store.text.textView.selectedRange == range {
//                        store.text.textView.selectedRange = .init()
//                    } else {
//                        store.text.textView.selectedRange = range
//                    }
//                }
//                shouldContinue.pointee = false
//            }
//        }
       
        
    }
    
    override func didLoad() {
        super.didLoad()
        
        store.indicator.image = UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 17)))?.tinted(.tertiaryLabel)
        store.indicator.contentMode = .center
        
        let bookmarkMenuItem = UIMenuItem(title: "Bookmark",  action: #selector(bookmark))
        let highlightMenuItem = UIMenuItem(title: "Highlight",  action: #selector(highlight))
        UIMenuController.shared.menuItems = [bookmarkMenuItem, highlightMenuItem]

        tapGesture.addTarget(self, action: #selector(onTap))

   
        
        store.title.style.flexGrow = 1
        store.title.style.flexShrink = 1
        
        store.title.textColorFollowsTintColor = true
        store.title.tintColor = UIColor.tertiaryLabel
        store.title.attributedText = .init(string: String(chapter), attributes: [.font: Constant.chapterFont()])
       
        
        
        store.text.style.flexGrow = 1
//        store.text.style.flexShrink = 1

        store.text.layer.opacity = 0
        store.text.textView.isSelectable = true
        store.text.textView.isEditable = false
        store.text.textView.isScrollEnabled = false
        store.text.textView.addGestureRecognizer(tapGesture)
        store.text.textContainerInset = .init(top: 0, left: 15, bottom: 0, right: 15)
        store.text.delegate = self

        store.layoutManager.textContainerOriginOffset = .init(width: store.text.textContainerInset.left, height: store.text.textContainerInset.top)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let hStack = ASStackLayoutSpec.horizontal()
        hStack.justifyContent = .spaceBetween
        hStack.children = [store.title, store.indicator]
        let hStackInset = ASInsetLayoutSpec(insets: .init(top: 0, left: 25, bottom: 0, right: 25), child: hStack)

        let stack = ASStackLayoutSpec.vertical()
        stack.spacing = 11
        if isExpanded {
            stack.children = [hStackInset, store.text]
        } else {
            stack.children = [hStackInset]
        }
        let inset = ASInsetLayoutSpec(insets: .init(top: 15, left: 0, bottom: 15, right: 0), child: stack)
        return inset
    }
    
    func editableTextNodeDidChangeSelection(_ editableTextNode: ASEditableTextNode,
                                            fromSelectedRange: NSRange,
                                            toSelectedRange: NSRange,
                                            dueToEditing: Bool) {
        let locator = RangeLocator(version: .kjv, book: book, chapter: chapter, range: toSelectedRange)
       
        NotificationCenter.default
            .post(name: .changeSelection,
                  object: toSelectedRange.length > 0 ? locator : nil)

    }
}
