//
//  PickerViewController.swift
//  videoAVFoundation
//
//  Created by Sergii Kotyk on 3/2/2022.
//

import MobileCoreServices
import Photos
import UIKit
import AVKit

class PickerViewController: UIViewController {

    @IBOutlet weak var video1Button: UIButton!
    @IBOutlet weak var video2Button: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var resset1Button: UIButton!
    @IBOutlet weak var resset2Button: UIButton!
    
    let exporter = Exporter()

    var buttonId = 1
    var asset1IsSelected = false
    var asset2IsSelected = false
    
    var asset1: AVAsset?
    var asset2: AVAsset?
    
    let videos = [
        PlayableFile(name: "Fog", type: "mp4"),
        PlayableFile(name: "Road", type: "mp4"),
        PlayableFile(name: "Flowers", type: "mp4")
    ]
    let audioFiles = [
        PlayableFile(name: "audio1", type: "mp3"),
        PlayableFile(name: "audio2", type: "mp3")
    ]
    
    
    @IBAction func resset1Button(_ sender: Any) {
        video1Button.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        asset1IsSelected = false
        nextButton.isEnabled = false
        asset1 = nil
        resset1Button.isHidden = true
    }
    
    @IBAction func resset2Button(_ sender: Any) {
        video2Button.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        asset2IsSelected = false
        nextButton.isEnabled = false
        asset1 = nil
        resset2Button.isHidden = true
    }
    
    @IBAction func getVideo1Button(_ sender: Any) {
        activityIndicator.startAnimating()
        exporter.export(track: videos[0].playerItem) { exprt in
            self.exportDidFinish(exprt)
        }
    }
    
    @IBAction func getVideo2Button(_ sender: Any) {
        activityIndicator.startAnimating()
        exporter.export(track: videos[1].playerItem) { exprt in
            self.exportDidFinish(exprt)
        }
    }
    @IBAction func getVideo3Button(_ sender: Any) {
        activityIndicator.startAnimating()
        exporter.export(track: videos[2].playerItem) { exprt in
            self.exportDidFinish(exprt)
        }
    }
    @IBAction func video1Button(_ sender: UIButton) {
        buttonId = 1
        if asset1IsSelected{
            playAsset(asset: asset1!)
        } else {
            VideoPicker.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        }
        
    }
    @IBAction func video2Button(_ sender: UIButton) {
        buttonId = 2
        if asset2IsSelected{
            playAsset(asset: asset2!)
        } else {
            VideoPicker.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        }
    }
    @IBAction func nextButtonAction(_ sender: Any) {
    }
    
    func playAsset(asset: AVAsset){
        let vc = AVPlayerViewController()
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        vc.player = player
        vc.player?.play()
        present(vc, animated: true)
    }
    
    func savedPhotosAvailable() -> Bool {
      guard !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum)
        else { return true }

      let alert = UIAlertController(
        title: "Not Available",
        message: "No Saved Album found",
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(
        title: "OK",
        style: UIAlertAction.Style.cancel,
        handler: nil))
      present(alert, animated: true, completion: nil)
      return false
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destenation = segue.destination as? MergeViewController{
            destenation.asset1 = asset1
            destenation.asset2 = asset2
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resset1Button.isHidden = !asset1IsSelected
        resset2Button.isHidden = !asset2IsSelected
    

    }
}

extension PickerViewController: UIImagePickerControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    dismiss(animated: true, completion: nil)

    guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
        mediaType == (kUTTypeMovie as String),
        let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
        else { return }

    let avAsset = AVAsset(url: url)
    var message = ""
      
    if buttonId == 1 {
        
        message = "Video one loaded"
        asset1 = avAsset
        video2Button.isEnabled = true
        video1Button.setImage(UIImage(systemName: "play"), for: .normal)
        asset1IsSelected = true
        resset1Button.isHidden = false

    } else {
        message = "Video two loaded"
        asset2 = avAsset
        video2Button.setImage(UIImage(systemName: "play"), for: .normal)
        asset2IsSelected = true
        resset2Button.isHidden = false
    }
      if asset1IsSelected && asset2IsSelected {
          nextButton.isEnabled = true
      } else {
          nextButton.isEnabled = false
      }
    let alert = UIAlertController(
        title: "Asset Loaded",
        message: message,
        preferredStyle: .alert)
    alert.addAction(UIAlertAction(
        title: "OK",
        style: UIAlertAction.Style.cancel,
        handler: nil))
    present(alert, animated: true, completion: nil)
  }
}


extension PickerViewController: UINavigationControllerDelegate{
    
}
