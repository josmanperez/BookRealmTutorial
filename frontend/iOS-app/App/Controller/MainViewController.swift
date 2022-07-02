//
//  MainViewController.swift
//  App
//
//  Created by Josman Pedro Pérez Expósito on 19/4/22.
//

import Foundation
import UIKit
import RealmSwift
import Realm.RLMUser
import FirebaseMessaging

class MainViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    static let showApp = "showApp"
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleLoggein()
    }
    
    fileprivate func handleLoggein() {
        // If a user is already looged in, return true
        if let user = realmApp.currentUser {
            self.setLoading(true)
            self.setDefaultConfiguration(forUser: user)
            Messaging.messaging().token { token, error in
                if let error = error {
                    print("Error fetching FCM registration token: \(error)")
                } else if let token = token {
                    print("FCM registration token: \(token)")
                    // Save token in user collection
                    user.functions.updateFCMUserToken([AnyBSON(token), AnyBSON("add")], self.onCustomDataUpdated(result:realmError:))
                }
            }
            user.refreshCustomData { (_) in
                DispatchQueue.main.async {
                    self.setLoading(false)
                    self.performSegue(withIdentifier: MainViewController.showApp, sender: nil)
                }
            }
        } else {
            anonymousSignIn()
        }
    }
    
    private func onCustomDataUpdated(result: AnyBSON?, realmError: Error?) {
        DispatchQueue.main.async {
            
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
                print("Update user FCM token failed: \(errorMessage!)")
                self.reportError(error)
                return
            }
            print("Update user FCM token success")
        }
    }
    
    // MARK: - Anonymous login
    
    /// Logs in with an existing user.
    func anonymousSignIn() {
        setLoading(true)
        realmApp.login(credentials: Credentials.anonymous) { result in
            DispatchQueue.main.async {
                self.setLoading(false)
                switch result {
                case let .failure(error):
                    print("Failed to log in: \(error)")
                    self.reportError(error)
                case let .success(user):
                    print("The user has been authenticated using anonymous auth")
                    self.onSignInComplete(user)
                }
            }
        }
    }

    /// Called when sign in completes. Opens the realm asynchronously and navigates to the BooksView screen.
    func onSignInComplete(_ user: RLMUser) {
        setLoading(true)
        openPublicRealm(for: user)
    }
    
    fileprivate func openPublicRealm(for user: RLMUser) {
        setDefaultConfiguration(forUser: user)
        Realm.asyncOpen(configuration: user.configuration(partitionValue: "global")) { result in
            self.setLoading(false)
            switch result {
            case .failure(let error):
                print("Failed to open realm: \(error)")
                self.reportError(error)
            case .success(let realm):
                self.setLoading(true)
                self.openUserRealm(userRealm: realm)
            }
        }
    }
    
    fileprivate func openUserRealm(userRealm: Realm) {
        Realm.asyncOpen { result in
            self.setLoading(false)
            switch result {
            case .failure(let error):
                print("Failed to open realm: \(error)")
                self.reportError(error)
            case .success(let realm):
                // Realm fully loaded
                self.performSegue(withIdentifier: MainViewController.showApp, sender: realm)
            }
        }
    }
    
    /// Sets the configuration to use when opening a realm for the given user.
    func setDefaultConfiguration(forUser user: RLMUser) {
        Realm.Configuration.defaultConfiguration = user.configuration(partitionValue: "\(user.id)")
    }
    
    func setLoading(_ loading: Bool) {
        loading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }
    
}

extension UIViewController {
    /// Presents the user with an error alert.
    func reportError(_ error: Error) {
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            alertController.dismiss(animated: true)
        }))
        present(alertController, animated: true)
    }
}

extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
}
