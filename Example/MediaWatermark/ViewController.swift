//
//  ViewController.swift
//  MediaWatermark
//
//  Created by Sergei on 03/05/2017.
//  Copyright © 2017 rubygarage. All rights reserved.
//

import UIKit
import MobileCoreServices
import MediaWatermark
import AVFoundation
import Photos

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var resultImageView: UIImageView!
    
    var imagePickerController: UIImagePickerController! = nil
    var player: AVPlayer! = nil
    var playerLayer: AVPlayerLayer! = nil
    
    // MARK: - view controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    // MARK: - setup
    func setup() {
        imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
    }
    
    // MARK: - actions
    @IBAction func openMediaButtonDidTap(_ sender: Any) {
        present(imagePickerController, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        let mediaType = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaType)] as! String
        picker.dismiss(animated: true, completion: nil)
        
        if (mediaType == kUTTypeVideo as String) || (mediaType == kUTTypeMovie as String) {
            let videoUrl = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as! URL
            processVideo(url: videoUrl)
        } else {
            let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage
            processImage(image: image!)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - processing
    func processImage(image: UIImage) {
        playerLayer?.removeFromSuperlayer()

        resultImageView.image = nil
        resultImageView.subviews.forEach({$0.removeFromSuperview()})
        
        let item = MediaItem(image: image)
        
        let logoImage = UIImage(named: "logo")
        
        let firstElement = MediaElement(image: logoImage!)
        firstElement.frame = CGRect(x: 0, y: 0, width: logoImage!.size.width, height: logoImage!.size.height)
        
        let secondElement = MediaElement(image: logoImage!)
        secondElement.frame = CGRect(x: 100, y: 100, width: logoImage!.size.width, height: logoImage!.size.height)
        
        item.add(elements: [firstElement])
        
        let mediaProcessor = MediaProcessor()
        mediaProcessor.processElements(item: item) { [weak self] (result, error) in
            self?.resultImageView.image = result.image
        }
    }
    
    func processVideo(url: URL) {
        resultImageView.image = nil
        
        if let item = MediaItem(url: url) {
            let logoImage = UIImage(named: "rglogo")?.alpha(0.6)
            
            let firstElement = MediaElement(image: logoImage!)
            let logoRatio = logoImage!.size.width / logoImage!.size.height
            let y = item.size.height - (logoImage!.size.height + 5)
            firstElement.frame = CGRect(x: 20, y: y, width: item.size.width * 0.306, height: item.size.width * 0.306 / logoRatio)
            
            print("Video: \(item.size.width)x\(item.size.height)")
            print("width:\(firstElement.frame.width) height:\(firstElement.frame.height)")
            print("logo: \(item.size.width * 0.306)x\(item.size.width * 0.306 / logoRatio)")
            print("waterMark: x\(20),y\(y) \(item.size.width * 0.306)x\(item.size.width * 0.306 / logoRatio)")
            
//            let secondElement = MediaElement(image: logoImage!)
//            secondElement.frame = CGRect(x: 150, y: 150, width:100, height: logoImage!.size.height)
            
            item.add(element: firstElement)
            
            let mediaProcessor = MediaProcessor()
//            mediaProcessor.processElements(item: item) { [weak self] (result, error) in
//                DispatchQueue.main.async {
//                    self?.playVideo(url: result.processedUrl!, view: (self?.resultImageView)!)
//                    PHPhotoLibrary.shared().performChanges({
//                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: result.processedUrl!)
//                    }, completionHandler: nil)
//                }
//            }
            mediaProcessor.processElements(item: item) { [weak self](result, error) in
                guard let blockSelf = self, let prossedURL = result.processedUrl else {
                    return
                }
                DispatchQueue.main.async {
                    blockSelf.playVideo(url: prossedURL, view: blockSelf.resultImageView)
                }
                
            }
        }
    }
    
    func playVideo(url: URL, view: UIView) {
        playerLayer?.removeFromSuperlayer()
        
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        
        view.layer.addSublayer(playerLayer)
        
        player.play()
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
extension UIImage {
    
    func alpha(_ value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
