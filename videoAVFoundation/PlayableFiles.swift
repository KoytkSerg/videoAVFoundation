//
//  PlayebleFiles.swift
//  videoAVFoundation
//
//  Created by Sergii Kotyk on 3/2/2022.
//

import Foundation
import AVFoundation

class PlayableFile{
    let name: String
    let type: String
    init(name: String,
         type: String){
        self.type = type
        self.name = name
    }
    
    var url: URL {
        get{
            URL(fileURLWithPath: Bundle.main.path(forResource: self.name, ofType: self.type)!)
        }
    }
    var asset: AVAsset{
        get{
            AVAsset(url: self.url)
        }
    }
    
    var playerItem: AVPlayerItem{
        get{
            AVPlayerItem(asset: asset)
        }
    }
}
