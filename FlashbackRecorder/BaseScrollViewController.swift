//
//  BaseScrollViewController.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 24.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import Foundation
import UIKit

// От этого контроллер можно не наследовать, если ты хочешь просто что-то класть в скролл - то можно вместо наследования контент второго контроллера сюда класть
// Будет что-то типа

// let anotherViewController = ... // какой-то там другой контроллер
// let scrollController = BaseScrollViewController()
// scrollController.containerView = anotherViewController.view

// потом надо было бы делать сеттер для containerView
// было бы как-то так:
// var containerView: NSView? {
//   didSet {
//      oldValue?.removeFromSuperview() // удалили старый
//      if let newView = containerView {
//         scrollView.addSubview(newView) // положили новый
//      }
//   }
//}

// то есть контент бы не создавался, а клался снаружи


class BaseScrollViewController: UIViewController {

    // все свойства что непубичные надо делать private
    lazy var contentViewSize = CGSize(width: self.view.frame.width, height: self.view.frame.height + 100)
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
//        view.backgroundColor = .gray
        view.frame = self.view.bounds
        view.contentSize = contentViewSize
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var containerView: UIView = {
        let v = UIView()
//        v.backgroundColor = .gray
        v.frame.size = contentViewSize
        return v
    }()

    override func viewDidLoad() {
//        view.backgroundColor = .white
        view.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 200).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        scrollView.addSubview(containerView)
        setupContainer(containerView)
        super.viewDidLoad()

    }

    // ничего не делает метод, что-то недописанное не знаю что)
    public func setupContainer(_ container: UIView) {
        
    }
}
