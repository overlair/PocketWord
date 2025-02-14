//
//  MenuViewNode.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import AsyncDisplayKit
import Defaults

class MenuViewNode:     ASDisplayNode,
                        ASTableDelegate,
                        ASTableDataSource   {
    override init() {
        super.init()
        self.automaticallyManagesSubnodes = true
        self.automaticallyRelayoutOnSafeAreaChanges = true
        store.list.delegate = self
        store.list.dataSource = self

    }
    let store = Store()
    
    class Store {
        lazy  var list = ASTableNode()

     
        
        var batchedBooks = [BookNameRecord]()
        var allBooks = [BookNameRecord]()
        var selectedBook: String? = nil

        let semaphore = DispatchSemaphore(value: 1)
    }
    
    let BATCH_SIZE = 10
    var keepFetchingBatches: Bool = true

    override func didLoad() {
        super.didLoad()
        
        store.list.view.separatorStyle = .none
        store.list.style.flexGrow = 1
   
        let version = Defaults[.version]
        let book = Defaults[.book]
        
        do {
            let books = try AppDatabase.shared.reader.read { db in
                let sql = """
                    SELECT name
                    FROM books
                    """
                return try BookNameRecord.fetchAll(db, sql: sql)
            }
            
            store.allBooks = books
            store.selectedBook = books[book - 1].book
        } catch {
            
        }

    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {

        var insets = safeAreaInsets
        insets.bottom = 0
        let inset = ASInsetLayoutSpec(insets: insets, child: store.list)
        return inset
    }
    
    
    func shouldBatchFetch(for tableNode: ASTableNode) -> Bool {
        keepFetchingBatches
    }

    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        context.beginBatchFetching()

        store.semaphore.wait()

        let offset = store.batchedBooks.count
        let end = min(offset + BATCH_SIZE, store.allBooks.count)
        let range = Array(offset..<end)
      
        
        keepFetchingBatches = offset + range.count < store.allBooks.count
        
        let paths = range.map { IndexPath(row: $0, section: Section.books.rawValue)}
        let records = store.allBooks[offset..<end]
        store.batchedBooks += records
        store.semaphore.signal()

        DispatchQueue.main.async { [store] in
            store.list.insertRows(at: paths, with: .left)
            context.completeBatchFetching(true)
        }
        
    }
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        Section.allCases.count
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        
        if section == Section.books.rawValue {
            return store.batchedBooks.count
        } else {
            // books count
            return 1
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        switch Section(rawValue: indexPath.section) {
        case .chapterLabel:
            return {
                let node = ASTextCellNode()
                node.text = "Chapters"
                node.textAttributes = [.font: Constant.labelFont(size: 15),
                                       .foregroundColor: UIColor.tertiaryLabel]
                node.style.flexGrow = 1
                node.style.flexShrink = 1
                node.selectionStyle = .none

                return node
            }
        case .bookLabel:
            return {
                let node = ASTextCellNode()
                node.text = "Books"
                node.textAttributes = [.font: Constant.labelFont(size: 15),
                                       .foregroundColor: UIColor.tertiaryLabel]
                node.style.flexGrow = 1
                node.style.flexShrink = 1
                node.selectionStyle = .none

                return node
            }
        case .chapters:
            return {
//                let node = ASTextCellNode()
//                node.text = String(indexPath.row)
//                node.textAttributes = [.font: Constant.chapterFont(),
//                                       .foregroundColor: UIColor.label]
//                node.selectionStyle = .blue
//                node.style.flexGrow = 1
//                node.style.flexShrink = 1
                
                let node = ChaptersCellNode()
                node.selectionStyle = .blue
                node.style.height = .init(unit: .points, value: 80)

                return node
            }
        case .books:
            let book = store.batchedBooks[indexPath.row]
            let isSelected = store.selectedBook == book.book
            return {
                let node = ASTextCellNode()
                node.text = book.book
                node.textAttributes = [.font: Constant.bookFont(),
                                       .foregroundColor: isSelected ? UIColor.label : UIColor.tertiaryLabel]
                node.selectionStyle = .blue
                node.style.flexGrow = 1
                return node
            }
            
        default:
            return { ASCellNode() }
        }
    }
    
    enum Section: Int, CaseIterable {
        
        case chapterLabel
        case chapters
        case bookLabel
        case books
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section) {
            
        case .books:
            let book = indexPath.row + 1
            NotificationCenter.default
                .post(name: .changeBook,
                        object: book)
            
            let impact = UIImpactFeedbackGenerator(style: .soft)
            impact.impactOccurred()

            self.closestViewController?.dismiss(animated: true)
        default:
            break
        }
    }
    
}
