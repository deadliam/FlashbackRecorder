//
//  RecordButton.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 26.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import Foundation
import UIKit

class RecordButton: UIButton {
    
    enum ButtonState: String {
        case record = "Record"
        case stop = "Stop"
    }
    
    var recordButton: UIButton!
    var buttonState: ButtonState!
    
    required init() {
        super.init(frame: CGRect(x: 10, y: 30, width: 160, height: 64))
        
        self.backgroundColor = UIColor.red
        self.setTitle(NSLocalizedString("Record", comment: "Button title"), for: .normal)
        self.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
