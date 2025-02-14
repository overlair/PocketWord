//
//  MenuViewController.swift
//  PocketWord
//
//  Created by John Knowles on 2/13/25.
//

import AsyncDisplayKit
import Defaults
import SwiftUI

class MenuViewController: ASDKViewController<MenuViewNode>  {
    
    override init() {
        super.init(node: MenuViewNode())
    }
    
    required  init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        var config = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 27, weight: .bold))
        
        
        let closeButton = UIButton.init(type: .custom)
        closeButton.tintColor = .secondaryLabel
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill",
                                     withConfiguration: config.applying(UIImage.SymbolConfiguration(hierarchicalColor: .secondaryLabel))),//?.tinted(.secondaryLabel),
                             for: .normal)
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
        
        let hasBookmark = Defaults[.bookmark] != nil
        // read defaults to deciide if bookmark is filled or not
        let bookmarkButton = UIButton.init(type: .custom)
        bookmarkButton.setImage(UIImage(systemName: "bookmark\(hasBookmark ? ".fill" : "")",
                                        withConfiguration: config)?.tinted(UIColor(Color.blue)),
                                for: .normal)
        bookmarkButton.isEnabled = hasBookmark
        bookmarkButton.layer.opacity = hasBookmark ? 1 : 0.3
        if hasBookmark {
            bookmarkButton.menu = UIMenu(children: [UIAction(title: "Remove", handler: { [weak self] _  in
                Defaults[.bookmark] = nil
                if let button = self?.navigationItem.leftBarButtonItem?.customView as? UIButton {
                    button.setImage(UIImage(systemName: "bookmark",  withConfiguration: config)?.tinted(UIColor(Color.blue)),
                                    for: .normal)
                    button.layer.opacity = 0.3
                    button.isEnabled = false
                }
            })])
        }
        bookmarkButton.addTarget(self, action: #selector(onBookmark), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: bookmarkButton)

        var pageMenuOptions = UIMenu.Options()
        var keepPresented = UIAction.Attributes()
        if #available(iOS 17.0, *) {
            pageMenuOptions =  [.displayAsPalette, .displayInline]
            keepPresented = .keepsMenuPresented
        } else {
            pageMenuOptions = [.displayInline]
        }
        
        var menuButtonConfig = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 23, weight: .bold))
        var menuColorButtonConfig = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 29, weight: .heavy))

        let menu = UIDeferredMenuElement.uncached { provider in
            print("open")
            let selection = UISelectionFeedbackGenerator()
            selection.selectionChanged()
            
            provider([
                
                     
                    UIAction(title: "Version",
                                                  image: UIImage(systemName: "books.vertical.fill",
                                                                 withConfiguration: menuButtonConfig)?.tinted(.secondaryLabel),
                                                  handler: { _ in
//                                                      self.node.store.books.reloadData()
//                let controller = VersionPickerController()
//                self.present(controller, animated:  true)
            }),
                                         
                    UIAction(title: "Help",
                                                      image: UIImage(systemName: "info.circle",
                                                                     withConfiguration: menuButtonConfig)?.tinted(.secondaryLabel),
                             handler: { _ in }),
                                         UIMenu(title: "Settings", image: UIImage(systemName: "gearshape.fill",
                                                                                  withConfiguration: menuButtonConfig)?.tinted(.secondaryLabel),
                                                children: [
                                                    UIMenu(title: "Page Color", options: pageMenuOptions, children: [
                                                        UIAction(image:UIImage(systemName: "square",
                                                                               withConfiguration: menuColorButtonConfig)?.tinted(.secondaryLabel),
                                                                 attributes: keepPresented,
                                                                 handler: { _ in }),
                                                        UIAction(image:UIImage(systemName: "square.fill",
                                                                               withConfiguration: menuColorButtonConfig)?.tinted(.red),
                                                                 attributes: keepPresented,
                                                                 handler: { _ in }),
                                                        UIAction(image:UIImage(systemName: "square.fill",
                                                                               withConfiguration: menuColorButtonConfig)?.tinted(.orange),
                                                                 attributes: keepPresented,
                                                                 handler: { _ in }),
                                                        UIAction(image:UIImage(systemName: "square.fill",
                                                                               withConfiguration: menuColorButtonConfig)?.tinted(.yellow),
                                                                 attributes: keepPresented,
                                                                 handler: { _ in }),
                                                        UIAction(image:UIImage(systemName: "square.fill",
                                                                               withConfiguration: menuColorButtonConfig)?.tinted(.green),
                                                                 attributes: keepPresented,
                                                                 handler: { _ in }),
                                                        
                                                    ]),
                                                    UIMenu(title: "Text Size",
                                                           options: .displayInline,
//                                                           preferredElementSize: .small,
                                                           children: [
                                                        UIAction(title: "Small",
                                                                 attributes: keepPresented,
                                                                 handler: { _ in
                                                                 }),
                                                        UIAction(title: "Default",
                                                                 attributes: keepPresented,
                                                                 handler: { _ in
                                                                 }),
                                                        UIAction(title: "Big",
                                                                 attributes: keepPresented,
                                                                 handler: { _ in
                                                                 }),
                                                        
                                                    ]),
                                                    UIMenu(title: "Line Spacing",
                                                           options: .displayInline,
//                                                           preferredElementSize: .small,
                                                           children: [
                                                        UIAction(title: "Tight",
                                                                 attributes: keepPresented,
                                                                 handler: { _ in
                                                                 }),
                                                        UIAction(title: "Default",
                                                                 attributes: keepPresented,
                                                                 handler: { _ in
                                                                 }),
                                                        UIAction(title: "Loose",
                                                                 attributes: keepPresented,
                                                                 handler: { _ in
                                                                 }),
                                                        
                                                    ]),
                                                ])])
        }
        

        self.navigationItem.title = "King James Version"
        if #available(iOS 16.0, *) {
            self.navigationItem.titleMenuProvider = { elements in
                UIMenu(children: [menu])
            }
        } else {
            // Fallback on earlier versions
        }
        
        
        
        let controller = VerseSearchViewController()
        let searchController = UISearchController(searchResultsController: controller)
//        searchController.delegate = self
        searchController.searchResultsUpdater = controller.node
        searchController.searchBar.placeholder = "Search verses..."
        searchController.hidesNavigationBarDuringPresentation = false
//        let inputView = UIHostingController(rootView: ItemSearchBarView(onClose: { [unowned searchController] in
//            searchController.searchBar.resignFirstResponder()
//        }, onCancel: { [unowned searchController] in
//            searchController.searchBar.text = ""
//        })).view
//        inputView?.frame.size.height = 48
        
        searchController.searchBar.inputAccessoryView = inputView
        self.navigationItem.hidesSearchBarWhenScrolling = true
        self.navigationItem.searchController = searchController
    }

    
    @objc func onBookmark() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred(intensity: 0.5)
        
        self.dismiss(animated: true)
    }
    
    @objc func onClose() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred(intensity: 0.5)

        self.dismiss(animated: true)
    }
}
