//
//  ChaptersCellNode.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import AsyncDisplayKit
import Defaults

class ChaptersCellNode: ASCellNode,
                         ASCollectionDelegate,
                         ASCollectionDataSource {
    override init() {
        super.init()
        self.automaticallyManagesSubnodes = true
        self.automaticallyRelayoutOnSafeAreaChanges = true
        store.list.delegate = self
        store.list.dataSource = self

    }
    let store = Store()
    
    class Store {
        var batchedChapters = 0
        var maxChapters = 0
        let layout = UICollectionViewFlowLayout()
        lazy var list =  ASCollectionNode(collectionViewLayout: layout)
        let semaphore = DispatchSemaphore(value: 1)
    }
    
    let BATCH_SIZE = 10
    var keepFetchingBatches: Bool = true
    
    override func didLoad() {
        super.didLoad()
        
        store.layout.scrollDirection = .horizontal
        
        store.list.backgroundColor = .clear
        store.list.alwaysBounceHorizontal = true
        
        let version = Defaults[.version]
        let book = Defaults[.book]
        
        do {
            let chapters = try AppDatabase.shared.reader.read { db in
                let sql = """
                    SELECT MAX(chapter)
                    FROM verses
                    WHERE book IS ?
                    """
                return try Int.fetchOne(db, sql: sql, arguments: [book])
            }
            
            if let chapters {
                store.maxChapters = chapters
            }
        } catch {
            
        }
        
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(insets: .zero, child: store.list)
    }
    
    func shouldBatchFetch(for collectionNode: ASCollectionNode) -> Bool {
        keepFetchingBatches
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, willBeginBatchFetchWith context: ASBatchContext) {
        context.beginBatchFetching()

        print("BEging BATCHING")
        let offset = store.batchedChapters
        let end = min(offset + BATCH_SIZE, store.maxChapters)
        let range = Array(offset..<end)
      
        
        keepFetchingBatches = offset + range.count < store.maxChapters
        
        let paths = range.map { IndexPath(row: $0, section: 0)}

     
        DispatchQueue.main.async { [store] in
            store.batchedChapters += range.count
            store.semaphore.wait()
            store.list.insertItems(at: paths)
            store.semaphore.signal()
        
            context.completeBatchFetching(true)
        }
        
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        store.batchedChapters
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let chapter = indexPath.row + 1
        return {
            let node = ASTextCellNode()
            node.text = String(chapter)
            node.textInsets = Constant.chapterInset
            node.textAttributes = [.font: Constant.chapterFont(),
                                   .foregroundColor: UIColor.label]
            node.selectionStyle = .default
            node.style.flexGrow = 1
//            node.style.height = .init(unit: .points, value: Constant.chapterFont().lineHeight + 10)

            return node
        }
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let chapter = indexPath.row + 1
        NotificationCenter.default
            .post(name: .changeChapter,
                    object: chapter)
        
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred(intensity: 0.8)

        self.closestViewController?.dismiss(animated: true)
    }
   
    
}
