//
//  ImageViewController.swift
//  SharedList
//
//  Created by Pieter Stragier on 14/11/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreData

class ImageViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    // MARK: - variables and constants
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let coreDelegate = CoreDataManager(modelName: "dataModel")
    weak var objectPersonal: Personal?
    var imagePicker = UIImagePickerController()
    var newPic: Bool?
    var image:UIImage?
    var storedPics: [[String:Any]] = []
    var imageInfo:[String:Any] = [:]
    @IBOutlet weak var viewTitle: UILabel!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveImageButton: UIButton!
    @IBOutlet weak var addImageButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var itemName: UILabel!
    
    @IBOutlet var imageTapped: [UIImageView]!
    @IBAction func saveTapped(_ sender: UIButton) {
        print("save tapped")
        for pics in storedPics {
            let image = pics[UIImagePickerControllerOriginalImage] as? UIImage
            prepareImageForSaving(info: pics, image: image!)
        }
    }
    @IBAction func cancelTapped(_ sender: UIButton) {
    }
    
    @IBAction func addImageTapped(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            print("Button capture")
            
            let myAlert = UIAlertController(title: "Select Image From", message: "", preferredStyle: .actionSheet)
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { (action) in
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = UIImagePickerControllerSourceType.camera
                    imagePicker.mediaTypes = [kUTTypeImage as String]
                    imagePicker.allowsEditing = false
                    self.present(imagePicker, animated: true, completion: nil)
                    self.newPic = true
                }
            }
            let cameraRollAction = UIAlertAction(title: "Camera Roll", style: .default) { (action) in
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
                    imagePicker.mediaTypes = [kUTTypeImage as String]
                    imagePicker.allowsEditing = false
                    self.present(imagePicker, animated: true, completion: nil)
                    self.newPic = false
                }
            }
            
            myAlert.addAction(cameraAction)
            myAlert.addAction(cameraRollAction)
            self.present(myAlert, animated: true)
            
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            print("mediaType is: \(mediaType)")
            print("info: \(info)")
            image = info[UIImagePickerControllerOriginalImage] as? UIImage
            imageView.image = image
            storedPics.append(info)
            print("storedPics: \(storedPics)")
            imageInfo = info
            if newPic == true {
                UIImageWriteToSavedPhotosAlbum(image!, self, #selector(imageError), nil)
            }
            if let imageURL = info[UIImagePickerControllerReferenceURL] as? URL {
                print("imageURL: \(imageURL)")
            }
        } else {
            print("mediaType not correct")
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func imageError(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo:UnsafeRawPointer) {
        if error != nil {
            let alert = UIAlertController(title: "Save Failed", message: "Failed to save image", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        itemName.text = objectPersonal?.item!
        let coupledImages:[UIImage?] = [objectPersonal?.images?.value(forKey: "image") as? UIImage]
        let firstImage = coupledImages[0]
        if firstImage != nil {
            imageView.image = firstImage
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ImageViewController {
    func prepareImageForSaving(info:[String:Any], image:UIImage) {
        // Use info as unique id
        
        // dispatch with gcd
        DispatchQueue.global(qos: .userInitiated).async {
            // Create NSData from UIImage
            guard let imageData = UIImageJPEGRepresentation(image, 1) else {
                // handle failed conversion
                print("jpg error")
                return
            }
            let imagePath = info[UIImagePickerControllerReferenceURL] as! URL
            // Scale image
            let thumbnail = image.scale(toSize: self.view.frame.size)
            guard let thumbnailData = UIImageJPEGRepresentation(thumbnail, 0.7) else {
                // handle failed conversion
                print("jpg error on thumbnail")
                return
            }
            // send to save function
            self.saveImage(imageData: imageData as NSData, imageURL: imagePath, thumbnailData: thumbnailData as NSData, info: info)
        }
    }
    
    func saveImage(imageData:NSData, imageURL:URL, thumbnailData:NSData, info:[String:Any]) {
        DispatchQueue.global(qos: .userInitiated).async {
            // create new objects in moc
            let moc = self.appDelegate.persistentContainer.viewContext
            let Image = Pimages(context: moc)
            Image.setValue(imageData, forKey: "image")
            Image.setValue(imageURL, forKey: "url")
            Image.setValue(thumbnailData, forKey: "thumbnail")
            Image.setValue(info, forKey: "info")
            do {
                try moc.save()
            } catch {
                print("Could not save")
            }
            self.objectPersonal?.addToImages(Image)
            self.coreDelegate.saveContext()
        }
    }
}
extension CGSize {
    func resizeFill(toSize: CGSize) -> CGSize {
        let scale:CGFloat = (self.height / self.width) < (toSize.height / toSize.width) ? (self.height / toSize.height) : (self.width / toSize.width)
        return CGSize(width: (self.width / scale), height: (self.height / scale))

    }
}
extension UIImage {
    func scale(toSize newSize:CGSize) -> UIImage {
        // make sure the new size has the correct aspect ratio
        let aspectFill = self.size.resizeFill(toSize: newSize)
        
        UIGraphicsBeginImageContextWithOptions(aspectFill, false, 0.0);
        self.draw(in: CGRect(x: 0, y: 0, width: aspectFill.width, height: aspectFill.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
