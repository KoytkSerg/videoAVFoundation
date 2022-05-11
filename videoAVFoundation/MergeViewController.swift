//
//  MergeViewController.swift
//  videoAVFoundation
//
//  Created by Sergii Kotyk on 4/2/2022.
//

import UIKit
import AVFoundation
import AVKit

class MergeViewController: UIViewController {
    
    @IBOutlet weak var fadeButton: UIButton!
    @IBOutlet weak var moveButton: UIButton!
    @IBOutlet weak var apearButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var stepper: UIStepper!
    
    @IBOutlet weak var timeSelectLabel: UILabel!
    var asset1: AVAsset?
    var asset2: AVAsset?
    var time = 1
    var activeMerge = ""
    var merge: Merge?
    
    
    @IBAction func fadeButton(_ sender: Any) {
        mergeIsSelected(.fade)
        
    }
    @IBAction func moveButton(_ sender: Any) {
        mergeIsSelected(.move)
    }
    @IBAction func apearButton(_ sender: Any) {
        mergeIsSelected(.apear)
    }
    @IBAction func timeChanger(_ sender: UIStepper) {
        time = Int(sender.value)
        timeLabel.text = activeMerge + "\(time) сек."
    }
    
    
    func mergeIsSelected(_ merge: Merge){
        stepper.isHidden = false
        timeSelectLabel.isHidden = false
        nextButton.isEnabled = true
        switch merge {
        case .fade:
            activeMerge = "затухание и появление\n"
            timeLabel.text = activeMerge + "\(time) сек."
            self.merge = .fade
        case .move:
            activeMerge = "сдвиг вправо\n"
            timeLabel.text = activeMerge + "\(time) сек."
            self.merge = .move
        case .apear:
            activeMerge = "появление из центра\n"
            timeLabel.text = activeMerge + "\(time) сек."
            self.merge = .apear
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destenation = segue.destination as? SoundViewController{
            destenation.videoAsset1 = asset1
            destenation.videoAsset2 = asset2
            destenation.merge = merge
            destenation.time = time
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        timeLabel.text = ""
        stepper.backgroundColor = UIColor.orange
        stepper.layer.cornerRadius = 10
        stepper.isHidden = true
        timeSelectLabel.isHidden = true

    }


}

public enum Merge{
       case fade, move, apear
}
