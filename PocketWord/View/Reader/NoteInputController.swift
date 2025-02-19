//
//  NoteInputController.swift
//  PocketWord
//
//  Created by John Knowles on 2/17/25.
//


import AsyncDisplayKit
import Defaults
import SwiftUI

class NoteInputController: ASDKViewController<NoteInputNode>  {
    
    override init() {
        super.init(node: NoteInputNode())
    }
    
    required  init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class Store {
        
        var isFavorite: Bool = false
    }
    
    let store = Store()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
                
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(onCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(onDone))
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.navigationItem.title = "Add note"
        let menu = UIDeferredMenuElement.uncached { [store] provider in
           let favorite = UIAction(title: store.isFavorite ? "Unfavorite" : "Favorite",
                     image: UIImage(systemName: store.isFavorite ? "heart" : "heart.fill")?.tinted(UIColor(Color.red)),
                     handler: { _ in
                store.isFavorite.toggle()
            })
            
            provider([favorite])
        }
        if #available(iOS 16.0, *) {
            self.navigationItem.titleMenuProvider = { _ in
                UIMenu(children: [menu])
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        node.textNode.becomeFirstResponder()
    }
    
    @objc func onCancel() {
        dismiss(animated: true)
    }
    @objc func onDone() {
        dismiss(animated: true)
        // notification, or just write straight to db and close...
        // need to access
        guard let text = node.textNode.attributedText?.string else {
            return
        }
        
        let note = NoteInput(text, store.isFavorite)
        NotificationCenter.default
            .post(name: .addNote,
                    object: note)
    }
}

typealias NoteInput = (text: String, isFavorite: Bool)
class NoteInputNode:ASDisplayNode, ASEditableTextNodeDelegate {
    override init() {
        super.init()
        self.automaticallyManagesSubnodes = true
        self.automaticallyRelayoutOnSafeAreaChanges  = true
        textNode.delegate = self
        textNode.typingAttributes = [NSAttributedString.Key.font.rawValue: Constant.noteFont()]
        textNode.textContainerInset = .init(top: 9, left: 15, bottom: 9, right: 15)
//        textNode.
    }
    
    lazy  var textNode = ASEditableTextNode()
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var insets = safeAreaInsets
        insets.bottom = 0
        return ASInsetLayoutSpec(insets: insets, child: textNode)
    }
    
    func editableTextNodeDidUpdateText(_ editableTextNode: ASEditableTextNode) {
        
        let isEnabled = !(editableTextNode.attributedText?.string ?? "").isEmpty
        if let rightButton = self.closestViewController?.navigationItem.rightBarButtonItem,
           rightButton.isEnabled != isEnabled
        {
            rightButton.isEnabled = isEnabled
        }

    }
}
