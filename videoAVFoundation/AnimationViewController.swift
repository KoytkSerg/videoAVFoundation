//
//  AnimationViewController.swift
//  videoAVFoundation
//
//  Created by Sergii Kotyk on 8/2/2022.
//

import MobileCoreServices
import Photos
import UIKit
import AVKit

class AnimationViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var saveVideoButton: UIButton!
    @IBOutlet weak var playVideoButton: UIButton!
    
    var asset: AVAsset?
    var avm = AVModel()
    var url: URL?
    
    @IBAction func getVideoButton(_ sender: Any) {
        self.playVideoButton.isHidden = true
        self.saveVideoButton.isHidden = true
        activityIndicator.startAnimating()
        VideoPicker.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
    }
    
    @IBAction func playVideoButton(_ sender: Any) {
        let asset = AVAsset(url: url!)
        let playerItem = AVPlayerItem(asset: asset)

        play(playerItem: playerItem)
        
    }
    @IBAction func saveVideoButton(_ sender: Any) {
        saveVideoToPhotos(url: url!)
    }
    
    func play(playerItem: AVPlayerItem){
        let vc = AVPlayerViewController()
        let player = AVPlayer(playerItem: playerItem)
        vc.player = player
        vc.player?.play()
        present(vc, animated: true)
    }
    
    private func saveVideoToPhotos(url: URL) {
      PHPhotoLibrary.shared().performChanges( {
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
      }) { [weak self] (isSaved, error) in
        if isSaved {
          print("Video saved.")
        } else {
          print("Cannot save video.")
          print(error ?? "unknown error")
        }
        DispatchQueue.main.async {
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playVideoButton.layer.cornerRadius = playVideoButton.bounds.height / 2
        saveVideoButton.isHidden = true
        playVideoButton.isHidden = true

    }


}

extension AnimationViewController: UIImagePickerControllerDelegate {
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
      message = "Video one loaded"
      avm.addRoundAnimation(asset: avAsset) { url in
          print("done")
          self.playVideoButton.isHidden = false
          self.saveVideoButton.isHidden = false
          self.url = url
          self.activityIndicator.stopAnimating()
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

extension AnimationViewController: UINavigationControllerDelegate{
    
}
