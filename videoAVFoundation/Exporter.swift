//
//  Exporter.swift
//  videoAVFoundation
//
//  Created by Sergii Kotyk on 3/2/2022.
//

import Foundation
import AVFoundation
import Photos
import UIKit

protocol ExportStatusProtocol{
    func status()
}
class Exporter{
    
    func export(track: AVPlayerItem, completion: @escaping (AVAssetExportSession) -> Void){
        let asset = track.asset
        let videoComposition = track.videoComposition
        guard let documentDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask).first
          else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        let date = dateFormatter.string(from: Date())
        let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")

        // 8 - Create Exporter
        guard let exporter = AVAssetExportSession(
          asset: asset,
          presetName: AVAssetExportPresetHighestQuality)
          else { return }
        exporter.outputURL = url
        exporter.outputFileType = AVFileType.mov
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = videoComposition
        exporter.exportAsynchronously {
          DispatchQueue.main.async {
              completion(exporter)
          }
        }

    }
    
    
}
