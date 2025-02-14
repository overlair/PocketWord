//
//  VerseSearchViewNode.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import AsyncDisplayKit
import Combine
import SwiftUI
import GRDB


class VerseSearchViewNode: ASDisplayNode,
                       ASTableDelegate,
                       ASTableDataSource,
                       UISearchResultsUpdating {
    override init() {
        super.init()
        self.automaticallyManagesSubnodes = true
        self.automaticallyRelayoutOnSafeAreaChanges = true
        self.automaticallyRelayoutOnLayoutMarginsChanges = true
        store.list.delegate = self
        store.list.dataSource = self
        
        
        searchPipe
            .debounce(for: 0.1, scheduler: RunLoop.main)
            .throttle(for: 0.3, scheduler: RunLoop.main, latest: true)
            .sink(receiveValue: handleSearch)
            .store(in: &cancellables)
    }
    
    deinit {
        countCancellable?.cancel()
        countCancellable = nil
    }
    
    class Store {
        var verses = [VerseNamedRecord]()
        var keepFetchingBatches = true
        var totalCount = 0
        
        var query = ""
        
        var list = ASTableNode()
        
        let semaphore = DispatchSemaphore(value: 1)
        let refreshSemaphore = DispatchSemaphore(value: 1)
        
        
        func verse(for path: IndexPath) -> VerseNamedRecord? {
            guard path.row >= 0 && path.row < verses.count else {
                return nil
            }
            
            return verses[path.row]
        }
    }
    
    let store =  Store()
    
    var searchPipe = PassthroughSubject<String, Never>()
    var cancellables = Set<AnyCancellable>()
    
    var countCancellable = AnyDatabaseCancellable?.none
    var countQueue = DispatchQueue(label: "items.count.\(UUID())", qos: .userInitiated)

    let BATCH_SIZE = 10
    
    override func didLoad() {
        super.didLoad()
        store.list.style.flexGrow = 1
        store.list.style.width = .init(unit: .fraction, value: 1)
        store.list.backgroundColor = .clear
        store.list.view.separatorStyle = .none
        

        startCountCancellable()
    }
    
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        var insets = safeAreaInsets
        insets.bottom = 0
        
        return ASInsetLayoutSpec(insets: insets,
                                 child: store.list)
    }
  
    
    func adjustBottomInset(_ position: CGFloat) {
        let safeAreaTop = safeAreaInsets.top
        let safeAreaBottom = safeAreaInsets.bottom

        let height = view.frame.height
        let offset = height - position - safeAreaBottom
        
        store.list.contentInset.bottom = offset
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text,
              !text.isEmpty else {
            return
        }
        
        searchPipe.send(text)
        
    }
    
    func handleSearch(text: String) {
        if store.query != text {
            store.query = text
            refresh()

        }
    }
    
    
    func refresh() {
        startCountCancellable()
        
        do {
            store.semaphore.wait()

            let sql = """
                      SELECT book, chapter, verse, kjv_verses.text, kjv_books.name AS bookName
                      FROM kjv_verses
                      JOIN kjv_verses_ft
                          ON kjv_verses_ft.rowid = kjv_verses.rowid
                      JOIN kjv_books
                          ON kjv_books.rowid = kjv_verses.book
                      AND kjv_verses_ft MATCH ?
                      LIMIT 10
                      """
            
            let verses = try AppDatabase.shared.reader.read { db in
                return try VerseNamedRecord.fetchAll(db,
                                                sql: sql,
                                                arguments: [FTS3Pattern(matchingAllPrefixesIn: store.query)])
            }
            
            let width = store.list.calculatedSize.width
//            let items = newItems.map {
//                DisplayableItem.create(item: $0, in: width)
//            }
            
            store.keepFetchingBatches = store.totalCount > verses.count
            let paths = Array(0..<verses.count).map { IndexPath(row: $0, section: 0)}
            let allRows = Array(0..<store.verses.count).map { IndexPath(row: $0, section: 0)}

            store.semaphore.signal()

            DispatchQueue.main.async { [store] in
//                store.semaphore.wait()


                print("REFRESH", paths.count, allRows.count)

                store.list.performBatchUpdates {
                    store.verses = verses
                    store.list.deleteRows(at: allRows, with: .top)
                    store.list.insertRows(at: paths, with: .none)

                } completion: { _ in
                    store.list.setContentOffset(.zero, animated: false)
                }
                

            }
            
        } catch {
            print(error)
        }
    }
    
    func startCountCancellable() {
        countCancellable?.cancel()
        countCancellable = ValueObservation.tracking({  db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM kjv_verses")
        })
        .start(in: AppDatabase.shared.reader, scheduling: .immediate, onError: { _ in }, onChange: { [store] count in
            if let count {
                store.totalCount = count
            }
        })
    }
    /*
     BATCH FETCHING
     */
    
    func shouldBatchFetch(for tableNode: ASTableNode) -> Bool {
        store.keepFetchingBatches
    }
    
    
    
    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        
        context.beginBatchFetching()
        store.semaphore.wait()

        let offset = store.verses.count
        
        do {
            
            let sql = """
                      SELECT book, chapter, verse, kjv_verses.text, kjv_books.name AS bookName
                      FROM kjv_verses
                      JOIN kjv_verses_ft
                          ON kjv_verses_ft.rowid = kjv_verses.rowid
                      JOIN kjv_books
                          ON kjv_books.rowid = kjv_verses.book
                      AND kjv_verses_ft MATCH ?
                      LIMIT ?
                      OFFSET ?
                      """
            
            let verses = try AppDatabase.shared.reader.read { db in
                return try VerseNamedRecord.fetchAll(db,
                                                sql: sql,
                                                arguments: [FTS3Pattern(matchingAllPrefixesIn: store.query), BATCH_SIZE, offset])
            }
            
            
            let width = tableNode.calculatedSize.width
            
//            let items = newItems.map {
//                DisplayableItem.create(item: $0, in: width)
//            }
            
            store.keepFetchingBatches = store.totalCount > store.verses.count + verses.count
            store.verses.append(contentsOf: verses)
            let paths = Array(offset..<offset + verses.count).map { IndexPath(row: $0, section: 0)}
            store.semaphore.signal()

            DispatchQueue.main.async { [store] in
//                store.semaphore.wait()

                store.list.performBatchUpdates({
                    store.list.insertRows(at: paths, with: .none)
                }, completion: { didComplete in
                    context.completeBatchFetching(true)
//                    store.semaphore.signal()
                })
            }
            
            
        } catch {
            print(error)
            context.completeBatchFetching(false)
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return store.verses.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        
        
        return { [store] in
            guard let verse = store.verse(for: indexPath) else {
                return  ASCellNode()
            }
            
            let node =  VerseCellNode()
           
            let indices = verse.text.indicesOf(string: store.query)
            let string = NSMutableAttributedString(string: verse.text, attributes: [.font: Constant.bodyFont()])
            
            let length =  (store.query as NSString).length
            for i in indices {
                string.addAttributes([.backgroundColor : UIColor(Color.yellow.opacity(0.5))], range: .init(location: i, length: length))
            }
            node.textNode.attributedText  = string
            node.verseNode.attributedText  = NSAttributedString(string: "\(verse.bookName) \(verse.chapter):\(verse.verse)",
                                                                attributes: [.font: Constant.labelFont(size: 13),
                                                                             .foregroundColor: UIColor.tertiaryLabel])
            return node
        }
    }
  
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {

    }
    
    
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
       return nil
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return nil
    }
    
    
    func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {
        return nil

    }
}

