//
//  CleanRecordsButton.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 26.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import Foundation
import UIKit

class CleanRecordsButton: UIButton {
    
    enum ButtonState: String {
        case clean = ""
    }
    
    var recordButton: UIButton!
    var buttonState: ButtonState!
    
    required init() {
        super.init(frame: CGRect(x: 10, y: 110, width: 160, height: 64))
        
        self.backgroundColor = UIColor.magenta
        self.setTitle(NSLocalizedString("Clean", comment: "Button title"), for: .normal)
        self.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
