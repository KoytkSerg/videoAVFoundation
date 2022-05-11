//
//  SoundViewController.swift
//  videoAVFoundation
//
//  Created by Sergii Kotyk on 4/2/2022.
//

import UIKit
import MobileCoreServices
import AVKit

class SoundViewController: UIViewController {


    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var addaudio1Button: UIButton!
    @IBOutlet weak var addaudio2Button: UIButton!
    
    @IBOutlet weak var animationButton: UIButton!
    var videoAsset1: AVAsset?
    var videoAsset2: AVAsset?
    var audioAsset1: AVAsset?
    var audioAsset2: AVAsset?
    var merge: Merge?
    var time = 1
    var audio1IsSelected = false
    var audio2IsSelected = false
    var animationSelected = false
    var animation = false
    var finalPlayerItem: AVPlayerItem?
    
    let audioFiles = [
        PlayableFile(name: "audio1", type: "mp3"),
        PlayableFile(name: "audio2", type: "mp3")
    ]
    
    @IBAction func animationButton(_ sender: Any) {
        if animationSelected{
            animationSelected = false
            animation = false
            animationButton.setTitle("добавить анимацию", for: .normal)
        } else {
            animationSelected = true
            animation = true
            animationButton.setTitle("убрать анимацию", for: .normal)
        }
    }
    @IBAction func playAudio1Button(_ sender: Any) {
        playAsset(asset: audioFiles[0].asset)
    }
    @IBAction func playAudio2Button(_ sender: Any) {
        playAsset(asset: audioFiles[1].asset)
    }
    @IBAction func addaudio1Button(_ sender: Any) {
        if audio1IsSelected{
            audio1IsSelected = false
            audioAsset1 = nil
            addaudio1Button.setImage(UIImage(systemName: "plus"), for: .normal)
            addaudio1Button.backgroundColor = UIColor.orange
        } else {
            audio1IsSelected = true
            audioAsset1 = audioFiles[0].asset
            addaudio1Button.setImage(UIImage(systemName: "minus"), for: .normal)
            addaudio1Button.backgroundColor = UIColor.red
        }
    }
    
    @IBAction func addaudio2Button(_ sender: Any) {
        if audio2IsSelected{
            audio2IsSelected = false
            audioAsset2 = nil
            addaudio2Button.setImage(UIImage(systemName: "plus"), for: .normal)
            addaudio2Button.backgroundColor = UIColor.orange
        } else {
            audio2IsSelected = true
            audioAsset2 = audioFiles[1].asset
            addaudio2Button.setImage(UIImage(systemName: "minus"), for: .normal)
            addaudio2Button.backgroundColor = UIColor.red
        }

    }
    @IBAction func merge(_ sender: Any) {
        let avm = AVModel()
        var audioTracks: [AVAsset] = []
        if audio1IsSelected{
            audioTracks.append(audioAsset1!)
        }
        if audio2IsSelected{
            audioTracks.append(audioAsset2!)
        }
        switch merge! {
        case .fade:
            finalPlayerItem = avm.mergeWithFade(video1: videoAsset1!, video2: videoAsset2!, TransitionDuration: Double(time), audioAssets: audioTracks)
        case .move:
                finalPlayerItem = avm.mergeWithMove(video1: videoAsset1!, video2: videoAsset2!, TransitionDuration: Double(time), audioAssets: audioTracks)
        case .apear:
                finalPlayerItem = avm.mergeWithCentrApear(video1: videoAsset1!, video2: videoAsset2!, TransitionDuration: Double(time), audioAssets: audioTracks)
        }
    }
    
    func playAsset(asset: AVAsset){
        let vc = AVPlayerViewController()
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        vc.player = player
        vc.player?.play()
        present(vc, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destenation = segue.destination as? FinalViewController{
            destenation.finalvideo = finalPlayerItem

        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        


    }
    


}


