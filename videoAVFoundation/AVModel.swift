//
//  AVSetups.swift
//  videoAVFoundation
//
//  Created by Sergii Kotyk on 31/1/2022.
//

import Foundation
import AVFoundation
import AVKit
import UIKit

class AVModel{

    func startPlay(file: PlayableFile, volume: Float, view: UIView){
        let url = file.url
        let player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        player.volume = volume
        view.layer.addSublayer(playerLayer)
        player.play()
        
    }
    func startPlay(asset: AVAsset, volume: Float, view: UIView){
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        player.volume = volume
        view.layer.addSublayer(playerLayer)
        player.play()
    }
    
    func startPlayWithComposition(asset: AVAsset, composition: AVVideoComposition, view: UIView, volume: Float){
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.videoComposition = composition
        let player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        player.volume = volume
        view.layer.addSublayer(playerLayer)
        player.play()
        
    }
    func roundAnimation(to layer: CALayer, videoSize: CGSize){

        let width = videoSize.width
        let height = videoSize.height
        let roundLayer = CALayer()
        roundLayer.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        roundLayer.backgroundColor = UIColor.white.cgColor
        roundLayer.cornerRadius = 75
        roundLayer.opacity = 0.5
        roundLayer.displayIfNeeded()

        
        let scaleAnimation = CABasicAnimation(keyPath: "position")
        scaleAnimation.fromValue = [0, 0]
        scaleAnimation.toValue = [width, height]
        scaleAnimation.duration = 5
        scaleAnimation.repeatCount = .greatestFiniteMagnitude
        scaleAnimation.autoreverses = true
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        scaleAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
        scaleAnimation.isRemovedOnCompletion = false
        roundLayer.add(scaleAnimation, forKey: "position")
        
        layer.addSublayer(roundLayer)
    }
    
    
    func addRoundAnimation(asset: AVAsset, completion: @escaping (URL?) -> Void){
        let composition = AVMutableComposition()
        
        guard let compositionTrack = composition.addMutableTrack(
            withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              
             let assetTrack = asset.tracks(withMediaType: .video).first
             else {
                 print("Something is wrong with the asset.")
                 fatalError()
           }
        
        do {
          let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
          try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
          
          if let audioAssetTrack = asset.tracks(withMediaType: .audio).first,
            let compositionAudioTrack = composition.addMutableTrack(
              withMediaType: .audio,
              preferredTrackID: kCMPersistentTrackID_Invalid) {
            try compositionAudioTrack.insertTimeRange(
              timeRange,
              of: audioAssetTrack,
              at: .zero)
          }
        } catch {
          print(error)
        }
        
        compositionTrack.preferredTransform = assetTrack.preferredTransform
        let videoInfo = orientation(from: assetTrack.preferredTransform)
        
        let videoSize: CGSize
        if videoInfo.isPortrait {
          videoSize = CGSize(
            width: assetTrack.naturalSize.height,
            height: assetTrack.naturalSize.width)
        } else {
          videoSize = assetTrack.naturalSize
        }
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
    
        roundAnimation(to: overlayLayer, videoSize: videoSize)
        
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(overlayLayer)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
          postProcessingAsVideoLayer: videoLayer,
          in: outputLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(
          start: .zero,
          duration: composition.duration)
        videoComposition.instructions = [instruction]
        let layerInstruction = compositionLayerInstruction(
          for: compositionTrack,
          assetTrack: assetTrack)
        instruction.layerInstructions = [layerInstruction]
        
        guard let export = AVAssetExportSession(
          asset: composition,
          presetName: AVAssetExportPresetHighestQuality)
          else {
            print("Cannot create export session.")
            fatalError()
        }
        
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
          .appendingPathComponent(videoName)
          .appendingPathExtension("mov")
        
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        
        export.exportAsynchronously {
          DispatchQueue.main.async {
            switch export.status {
            case .completed:
              completion(exportURL)
            default:
              print("Something went wrong during export.")
              print(export.error ?? "unknown error")
              fatalError()
              break
            }
          }
        }
    }
    
    private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
      var assetOrientation = UIImage.Orientation.up
      var isPortrait = false
      if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
        assetOrientation = .right
        isPortrait = true
      } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
        assetOrientation = .left
        isPortrait = true
      } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
        assetOrientation = .up
      } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
        assetOrientation = .down
      }
      
      return (assetOrientation, isPortrait)
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
      let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
      let transform = assetTrack.preferredTransform
      
      instruction.setTransform(transform, at: .zero)
      
      return instruction
    }
    
    private func trackCreaterForMerging(video1: AVAsset, video2: AVAsset, audioAssets: [AVAsset]?, TransitionTime: Double) -> (AVMutableCompositionTrack, AVMutableCompositionTrack, AVMutableComposition, CMTime, CMTimeRange){
        let composition = AVMutableComposition()
        let transitionDuration = CMTime(seconds: TransitionTime, preferredTimescale: 600)
        let transitionTimeRange = CMTimeRange(start: video1.duration - transitionDuration, duration: transitionDuration)
        
        guard let videoTrack1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        guard let videoTrack2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        
        try? videoTrack1.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video1.duration),
                                        of: video1.tracks(withMediaType: .video)[0],
                                         at: CMTime.zero)
        try? videoTrack2.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video2.duration),
                                        of: video2.tracks(withMediaType: .video)[0],
                                         at: video1.duration - transitionDuration)
        
        if audioAssets != nil && !audioAssets!.isEmpty{
            let fullVideoDuration = video1.duration + video2.duration - transitionDuration
            var fullAudioDuration = CMTime()
            for i in audioAssets!{
                fullAudioDuration = fullAudioDuration + i.duration
            }
            
            guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
            if fullAudioDuration <= fullVideoDuration{
                try? audioTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: audioAssets![0].duration), of: audioAssets![0].tracks(withMediaType: .audio)[0], at: CMTime.zero)
            } else {
                try? audioTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: fullVideoDuration), of: audioAssets![0].tracks(withMediaType: .audio)[0], at: CMTime.zero)
            }
            if audioAssets!.count == 2{
                if fullAudioDuration <= fullVideoDuration{
                    try? audioTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: audioAssets![1].duration), of: audioAssets![1].tracks(withMediaType: .audio)[0], at: audioAssets![0].duration)
                } else {
                    try? audioTrack.insertTimeRange(CMTimeRange(start: audioAssets![0].duration, duration: fullVideoDuration - audioAssets![0].duration), of: audioAssets![1].tracks(withMediaType: .audio)[0], at: audioAssets![0].duration)
                }
            }
        }
        return (videoTrack1, videoTrack2, composition, transitionDuration, transitionTimeRange)
        
    }
    
    func mergeWithFade(video1: AVAsset, video2: AVAsset, TransitionDuration: Double, audioAssets: [AVAsset]?) -> (AVPlayerItem){
        
        let (videoTrack1,
             videoTrack2,
             composition,
             transitionDuration,
             transitionTimeRange
             ) = trackCreaterForMerging(video1: video1, video2: video2, audioAssets: audioAssets, TransitionTime: TransitionDuration)
        let mainComposition = AVMutableVideoComposition(propertiesOf: composition)
        
        let firstInsruction = AVMutableVideoCompositionInstruction()
        firstInsruction.timeRange = CMTimeRangeMake( start: .zero, duration: video1.duration - transitionDuration)
        let firstLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack1)
        firstInsruction.layerInstructions = [firstLayerInstruction]
        
        let margingInstruction = AVMutableVideoCompositionInstruction()
        margingInstruction.timeRange = transitionTimeRange
        let fadeOutInst = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack1)
        let fadeInInst = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack2)
        fadeOutInst.setOpacityRamp(fromStartOpacity: 1, toEndOpacity: 0, timeRange: transitionTimeRange)
        fadeInInst.setOpacityRamp(fromStartOpacity: 0, toEndOpacity: 1, timeRange: transitionTimeRange)
        margingInstruction.layerInstructions = [fadeOutInst, fadeInInst]
        
        let secondInstruction = AVMutableVideoCompositionInstruction()
        secondInstruction.timeRange = CMTimeRangeMake( start: video1.duration, duration: video2.duration)
        let secondLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack2)
        secondInstruction.layerInstructions = [secondLayerInstruction]
        
        mainComposition.instructions = [firstInsruction, margingInstruction, secondInstruction]

        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = mainComposition

        return (playerItem)
    }
    
    func mergeWithCentrApear(video1: AVAsset, video2: AVAsset, TransitionDuration: Double, audioAssets: [AVAsset]?) -> (AVPlayerItem){
        
        let (videoTrack1,
             videoTrack2,
             composition,
             transitionDuration,
             transitionTimeRange
             ) = trackCreaterForMerging(video1: video1, video2: video2, audioAssets: audioAssets, TransitionTime: TransitionDuration)

        let mainComposition = AVMutableVideoComposition(propertiesOf: composition)
        
        let firstInsruction = AVMutableVideoCompositionInstruction()
        firstInsruction.timeRange = CMTimeRangeMake( start: .zero, duration: video1.duration - transitionDuration)
        let firstLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack1)
        firstInsruction.layerInstructions = [firstLayerInstruction]
        
        let margingInstruction = AVMutableVideoCompositionInstruction()
        margingInstruction.timeRange = transitionTimeRange
        
        let track2FromCentr = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack2)
        let centrX = videoTrack2.naturalSize.width / 2
        let centrY = videoTrack2.naturalSize.height / 2
        
        let defultTransformation1 = CGAffineTransform(scaleX: 0.001, y: 0.001)
        let defultTransformation2 = CGAffineTransform(translationX: centrX, y: centrY)
        

        let finalTransformation1 = CGAffineTransform(scaleX: 1, y: 1)
        let finalTransformation2 = CGAffineTransform(translationX: 0, y: 0)
        
        track2FromCentr.setTransformRamp(fromStart: defultTransformation1.concatenating(defultTransformation2),
                                         toEnd: finalTransformation1.concatenating(finalTransformation2),
                                       timeRange: transitionTimeRange)
        
        let track1 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack1)
        margingInstruction.layerInstructions = [track2FromCentr, track1]
        
        let secondInstruction = AVMutableVideoCompositionInstruction()
        secondInstruction.timeRange = CMTimeRangeMake( start: video1.duration, duration: video2.duration)
        let secondLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack2)
        secondInstruction.layerInstructions = [secondLayerInstruction]
        
        mainComposition.instructions = [firstInsruction, margingInstruction, secondInstruction]
        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = mainComposition

        return (playerItem)
    }
    
    func mergeWithMove(video1: AVAsset, video2: AVAsset, TransitionDuration: Double, audioAssets: [AVAsset]?) -> (AVPlayerItem){
        
        let (videoTrack1,
             videoTrack2,
             composition,
             transitionDuration,
             transitionTimeRange
             ) = trackCreaterForMerging(video1: video1, video2: video2, audioAssets: audioAssets, TransitionTime: TransitionDuration)
        let mainComposition = AVMutableVideoComposition(propertiesOf: composition)
        
        let firstInsruction = AVMutableVideoCompositionInstruction()
        firstInsruction.timeRange = CMTimeRangeMake( start: .zero, duration: video1.duration - transitionDuration)
        let firstLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack1)
        firstInsruction.layerInstructions = [firstLayerInstruction]
        
        let margingInstruction = AVMutableVideoCompositionInstruction()
        margingInstruction.timeRange = transitionTimeRange
        
        let track1Move = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack1)
        let track2Move = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack2)
        
        let backX = videoTrack2.naturalSize.width
        track2Move.setTransformRamp(fromStart: CGAffineTransform(translationX: -backX, y: 0),
                                    toEnd: CGAffineTransform(translationX: 0, y: 0),
                                    timeRange: transitionTimeRange)
        track1Move.setTransformRamp(fromStart: CGAffineTransform(translationX: 0, y: 0),
                                    toEnd: CGAffineTransform(translationX: backX, y: 0),
                                    timeRange: transitionTimeRange)
        
        margingInstruction.layerInstructions = [track2Move, track1Move]
        
        let secondInstruction = AVMutableVideoCompositionInstruction()
        secondInstruction.timeRange = CMTimeRangeMake( start: video1.duration, duration: video2.duration)
        let secondLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack2)
        secondInstruction.layerInstructions = [secondLayerInstruction]
        
        mainComposition.instructions = [firstInsruction, margingInstruction, secondInstruction]
        
        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = mainComposition

        return (playerItem)
    }
    
    func stickTogather(videos: [PlayableFile], audio: [PlayableFile]) -> AVPlayerItem{
        let composition = AVMutableComposition()
        var videoInsrtTime = CMTime.zero
        var audioInsrtTime = CMTime.zero
        
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: 2) else { fatalError() }

        for i in videos{
            let video = i.asset
            try? videoTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video.duration),
                                            of: video.tracks(withMediaType: .video)[0],
                                            at: videoInsrtTime)
            videoInsrtTime = video.duration + videoInsrtTime
            
        }
        
        for i in audio{
            let audio = i.asset
            try? audioTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: audio.duration),
                                            of: audio.tracks(withMediaType: .audio)[0],
                                            at: audioInsrtTime)
            audioInsrtTime = audio.duration + audioInsrtTime
        }
        let playerItem = AVPlayerItem(asset: composition)
        return playerItem
    }
    
}


