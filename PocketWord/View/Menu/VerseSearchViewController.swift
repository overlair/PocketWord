//
//  VerseSearchViewController.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import AsyncDisplayKit


class VerseSearchViewController: ASDKViewController<VerseSearchViewNode>   {
    
    override init() {
        super.init(node: VerseSearchViewNode())
    }
    
    
    required  init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
}
