//
//  PlayButton.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 26.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import Foundation
import UIKit

class PlayButton: UIButton {
    
    enum ButtonState: String {
        case play = "Play"
        case stop = "Stop"
    }
        
    var playButton: UIButton!
    var buttonState: ButtonState!
    
    required init() {
        super.init(frame: CGRect(x: 200, y: 30, width: 160, height: 64))
        
        self.backgroundColor = UIColor.green
        self.setTitle(NSLocalizedString("Play", comment: "Button title"), for: .normal)
        self.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

