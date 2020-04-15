//
//  RecordButton.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 26.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import Foundation
import UIKit

enum ButtonBuilder {

    static func createButton(name: String, color: UIColor, target: Any, action: Selector) -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = button.frame.size.height / 2
        button.backgroundColor = color
        button.setTitle(NSLocalizedString(name, comment: "Button title"), for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
}
