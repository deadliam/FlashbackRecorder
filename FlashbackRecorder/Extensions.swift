//
//  Extensions.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 26.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import Foundation

extension FileManager {
    
//    func urls(for directory: FileManager.SearchPathDirectory, skipsHiddenFiles: Bool = true ) -> [URL]? {
//        let documentsURL = urls(for: directory, in: .userDomainMask)[0]
//        let fileURLs = try? contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
//        return fileURLs
//    }
    
    func creationDate(for fileURL: URL) -> Date {
        var creationDate: Date!
        do {
            let resources = try fileURL.resourceValues(forKeys: [.creationDateKey])
            creationDate = resources.creationDate!
            
        }
        catch {
            print(error)
        }
        return creationDate
    }
    
//    static var documentDirectoryURL: URL {
////        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//        let documentDirectoryURL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
//        return documentDirectoryURL
//    }
}

extension Date {
    func toString( dateFormat format  : String ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
