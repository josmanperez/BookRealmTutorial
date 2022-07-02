//
//  SettingsViewController.swift
//  App
//
//  Created by Josman Pedro Pérez Expósito on 29/4/22.
//

import UIKit
import RealmSwift
import Realm.RLMUser
import FirebaseMessaging

enum ColorSegment: String {
    case black = "#000000FF"
    case blue = "#1AA7ECFF"
    case red = "#B22222FF"
    
    var code: Int {
        switch self {
        case .black:
            return 0
        case .blue:
            return 1
        case .red:
            return 2
        }
    }
    
    static func getColor(_ code: Int) -> ColorSegment {
        switch code {
        case 0:
            return .black
        case 1:
            return .blue
        case 2:
            return .red
        default:
            return .black
        }
    }
}

protocol OnSettingChanged {
    func didSettingChanged(customData: [String: Any])
}

class SettingsViewController: UIViewController {
    
    static let booksTopic = "books"
    
    var user: RLMUser?
    var delegate: OnSettingChanged?
    lazy var document: [String: Any] = [:]
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var fullImageQuality: UISwitch!
    @IBOutlet weak var settingView: UIView! {
        didSet {
            settingView.layer.masksToBounds = true
            settingView.layer.cornerRadius = 10
        }
    }
    @IBOutlet weak var segmentedCrl: UISegmentedControl!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var booksNotificationBtn: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let _user = user else {
            dismiss(animated: true)
            return
        }
        setLoading(true)
        _user.refreshCustomData { result in
            DispatchQueue.main.async {
                self.setLoading(false)
                switch result {
                case .failure(let error):
                    self.dismiss(animated: true) {
                        self.reportError(error)
                    }
                case .success(let dictionary):
                    print("loaded custom user data")
                    self.configureView(with: dictionary)
                }
            }
        }
        
    }
    
    func setLoading(_ loading: Bool) {
        loading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        fullImageQuality.isEnabled = !loading
        saveBtn.isEnabled = !loading
        booksNotificationBtn.isEnabled = !loading
    }
    
    func configureView(with dictionary: [AnyHashable : Any]) {
        fullImageQuality.setOn(
            dictionary["fullImage"] as? Bool ?? false
            , animated: true)
        let color = ColorSegment(rawValue: (dictionary["color"] as? String) ?? "#000000FF")
        segmentedCrl.selectedSegmentIndex = color?.code ?? 0
        booksNotificationBtn.setOn(
            dictionary["bookNotification"] as? Bool ?? false, animated: true)
    }
    
    @IBAction func setBookPushNotification(_ sender: Any) {
        if booksNotificationBtn.isOn {
            Messaging.messaging().subscribe(toTopic: SettingsViewController.booksTopic)
            print("Subscribed to \(SettingsViewController.booksTopic)")
        } else {
            Messaging.messaging().unsubscribe(fromTopic: SettingsViewController.booksTopic)
            print("Unsubscribed to \(SettingsViewController.booksTopic)")
        }
    }
    
    @IBAction func saveSettings(_ sender: Any) {
        guard let user = user else { return }
        setLoading(true)
        let color = ColorSegment.getColor(segmentedCrl.selectedSegmentIndex).rawValue
        document = ["color": color, "fullImage": fullImageQuality.isOn]
        user.functions.updateCustomData([AnyBSON(color),AnyBSON(fullImageQuality.isOn),AnyBSON(booksNotificationBtn.isOn)], self.onCustomDataUpdated(result:realmError:))
    }
    
    private func onCustomDataUpdated(result: AnyBSON?, realmError: Error?) {
        DispatchQueue.main.async {
            self.setLoading(false)
            var errorMessage: String? = nil
            
            if (realmError != nil) {
                // Error from Realm (failed function call, network error...)
                errorMessage = realmError!.localizedDescription
            } else if let resultDocument = result?.documentValue {
                // Check for user error. The addTeamMember function we defined returns an object
                // with the `error` field set if there was a user error.
                errorMessage = resultDocument["error"]??.stringValue
            } else {
                // The function call did not fail but the result was not a document.
                // This is unexpected.
                errorMessage = "Unexpected result returned from server"
            }
            // Present error message if any
            guard errorMessage == nil else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage!])
                print("Delete user failed: \(errorMessage!)")
                self.reportError(error)
                return
            }
            self.dismiss(animated: true) { [self] in
                delegate?.didSettingChanged(customData: document)
            }
        }
    }
}
