//
//  ViewController.swift
//  ShareMyLocationBySmsSwiftProject
//
//  Created by Edanur Sesli on 12.05.2025.
//

import UIKit
import ContactsUI
import CoreLocation
import MessageUI
import AVFoundation

class ViewController: UIViewController, CNContactPickerDelegate, CLLocationManagerDelegate, MFMessageComposeViewControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var selectedPhoneNumber: String?

    // Video oynatıcı için gerekli değişkenler
    var queuePlayer: AVQueuePlayer?
    var playerLooper: AVPlayerLooper?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Arka plan videosunu oynat
        playBackgroundVideo()

        // Konum izni al
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func playBackgroundVideo() {
        guard let path = Bundle.main.path(forResource: "map", ofType: "mp4") else {
            print("Video bulunamadı.")
            return
        }

        let url = URL(fileURLWithPath: path)
        let playerItem = AVPlayerItem(url: url)

        queuePlayer = AVQueuePlayer()
        playerLooper = AVPlayerLooper(player: queuePlayer!, templateItem: playerItem)

        let playerLayer = AVPlayerLayer(player: queuePlayer!)

        // Ekranın ortasına yerleştirilmiş, daha küçük bir alan tanımla
        let width = view.bounds.width * 1.0
        let height = view.bounds.height * 1.0
        let x = (view.bounds.width - width) / 1
        let y = (view.bounds.height - height) / 1
        playerLayer.frame = CGRect(x: x, y: y, width: width, height: height)

        playerLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(playerLayer, at: 0)

        queuePlayer?.play()
    }


    @objc func selectContact() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        present(contactPicker, animated: true, completion: nil)
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        selectContact()
    }

    // Kişi seçildiğinde
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue else {
            print("Telefon numarası bulunamadı")
            return
        }
        selectedPhoneNumber = phoneNumber

        // Konumu almaya başla
        locationManager.startUpdatingLocation()
    }

    // Konum güncellendiğinde
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        guard let location = locations.last else { return }
        currentLocation = location

        sendSMS()
    }

    // SMS gönderme
    func sendSMS() {
        guard MFMessageComposeViewController.canSendText(),
              let phoneNumber = selectedPhoneNumber,
              let location = currentLocation else {
            print("SMS gönderilemedi")
            return
        }

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let message = "Benim konumum: https://maps.google.com/?q=\(lat),\(lon)"

        let messageVC = MFMessageComposeViewController()
        messageVC.body = message
        messageVC.recipients = [phoneNumber]
        messageVC.messageComposeDelegate = self

        present(messageVC, animated: true, completion: nil)
    }

    // SMS gönderimi tamamlandığında
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}
