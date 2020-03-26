//
//  RecordsTableView.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 26.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import Foundation
import UIKit

class RecordsTableView: BaseScrollViewController {
    
    var stackView: UIStackView!
    
//    let tableView = UITableView.init(frame: .zero, style: UITableView.Style.grouped)
    
    func setupStackView() {
        stackView.removeFromSuperview()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 10
        stackView.distribution = .fill
        scrollView.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          // Attaching the content's edges to the scroll view's edges
          stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
          stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
          stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
          stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

          // Satisfying size constraints
          stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    // Таблица -> есть для этого класс UITableView
    // у него есть dataSource и delegate
    // слегка сложный в настройке но импользуется повсеместно, он даже сразу скроллиться умеет на iOS (на маке не умеет)
    func setupTable() {
        let contentsOfDocuments = RecordingStorage().getRecordsArray()
        for i in 0...5 {
            let listView = UIView()
            listView.backgroundColor = .gray
            stackView.addArrangedSubview(listView)
            listView.translatesAutoresizingMaskIntoConstraints = false
            // Doesn't have intrinsic content size, so we have to provide the height at least
            listView.heightAnchor.constraint(equalToConstant: 0).isActive = true

            // Label (has instrinsic content size)
            let label = UILabel()
            label.font = label.font.withSize(25)
            label.backgroundColor = .orange
            if contentsOfDocuments.indices.contains(i) {
                let labelText = contentsOfDocuments[i].filePath.dropFirst(10).dropLast(4)
                label.text = String(labelText)
            } else {
                break
            }
            label.textAlignment = .left
            stackView.addArrangedSubview(label)
        }
    }
    
}
