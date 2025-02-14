//
//  VerseCellNode.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import AsyncDisplayKit


class VerseCellNode: ASCellNode {
    
    override init() {
        super.init()
        self.automaticallyManagesSubnodes = true
//        textNode.textContainerInset = .init(top: 11, left: 11, bottom: 11, right: 11)
//        textNode.textContainerInset = .init(top: 11, left: 11, bottom: 11, right: 11)
    }
    lazy var textNode = ASTextNode()
    lazy var verseNode = ASTextNode()
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let stack = ASStackLayoutSpec.vertical()
        stack.children = [verseNode, textNode]
        stack.spacing = 5
        return ASInsetLayoutSpec(insets: .init(top: 11, left: 11, bottom: 11, right: 11), child: stack)
    }
}
