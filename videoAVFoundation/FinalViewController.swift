//
//  FinalViewController.swift
//  videoAVFoundation
//
//  Created by Sergii Kotyk on 8/2/2022.
//

import UIKit
import AVFoundation
import AVKit
import MobileCoreServices
import Photos

class FinalViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var playButton: UIButton!
    
    var finalvideo: AVPlayerItem?
    let expoter = Exporter()
    
    @IBAction func playButton(_ sender: Any) {
        play(playerItem: finalvideo!)
    }
    
    @IBAction func saveButton(_ sender: Any) {
        activityIndicator.startAnimating()
        expoter.export(track: finalvideo!) { exprt in
            self.exportDidFinish(exprt)
            DispatchQueue.main.async {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    func play(playerItem: AVPlayerItem){
        let vc = AVPlayerViewController()
        let player = AVPlayer(playerItem: playerItem)
        vc.player = player
        vc.player?.play()
        present(vc, animated: true)
    }
    
    func exportDidFinish(_ session: AVAssetExportSession) {
        activityIndicator.stopAnimating()

      guard
        session.status == AVAssetExportSession.Status.completed,
        let outputURL = session.outputURL
        else { return }

      let saveVideoToPhotos = {
      let changes: () -> Void = {
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
      }
      PHPhotoLibrary.shared().performChanges(changes)
          { saved, error in
        DispatchQueue.main.async {
          let success = saved && (error == nil)
          let title = success ? "Success" : "Error"
          let message = success ? "Video saved" : "Failed to save video"

          let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
          alert.addAction(UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.cancel,
            handler: nil))
          self.present(alert, animated: true, completion: nil)
        }
      }
      }

      // Ensure permission to access Photo Library
      if PHPhotoLibrary.authorizationStatus() != .authorized {
        PHPhotoLibrary.requestAuthorization { status in
          if status == .authorized {
            saveVideoToPhotos()
          }
        }
      } else {
        saveVideoToPhotos()
      }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        playButton.layer.cornerRadius = playButton.bounds.height / 2


    }
    


}
