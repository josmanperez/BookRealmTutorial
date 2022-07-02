import UIKit
import RealmSwift
import Realm.RLMUser

protocol OnLoginProtocol {
    func didLoginSuccessful()
    func didLinkedSuccessful()
}

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var changeModeButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    private var isInSignUpMode = true
    var delegate: OnLoginProtocol?
    var anonUser: RLMUser?

    override func viewDidLoad() {
        super.viewDidLoad()
        changeModeButton.addTarget(self, action: #selector(modeChangeButtonPressed), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitButtonPressed), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
    }

    /// Switches the UI between sign in (log in) and sign up (create account) mode.
    @IBAction func modeChangeButtonPressed() {
        isInSignUpMode = !isInSignUpMode
        if (isInSignUpMode) {
            submitButton.setTitle("Create Account", for: .normal)
            changeModeButton.setTitle("Already have an account? Log In", for: .normal)
        } else {
            submitButton.setTitle("Log In", for: .normal)
            changeModeButton.setTitle("Don't have an account? Create Account", for: .normal)
        }
    }
    
    /// Action called when the submit button is pressed to either create an account or log in.
    @IBAction func submitButtonPressed() {
        let email = emailField.text!
        let password = passwordField.text!
        if (isInSignUpMode) {
            signUp(email: email, password: password)
        } else {
            link(email: email, password: password)
        }
    }
    
    /// Registers a new user with the email/password authentication provider.
    func signUp(email: String, password: String) {
        setLoading(true)
        realmApp.emailPasswordAuth.registerUser(email: email, password: password) { error in
            DispatchQueue.main.async {
                self.setLoading(false)
                guard error == nil else {
                    print("Account creation failed: \(error!)")
                    self.reportError(error!)
                    return
                }
                self.link(email: email, password: password)
            }
        }
    }
    
    /// Logs in with an existing user.
    func link(email: String, password: String) {
        guard let user = anonUser else {
            return
        }
        self.setLoading(true)
        user.linkUser(credentials: Credentials.emailPassword(email: email, password: password)) { (result) in
            DispatchQueue.main.async {
                self.setLoading(false)
                switch result {
                case .failure(let error):
                    print("Failed to link user: \(error.localizedDescription)")
                    //self.reportError(error)
                    self.login(email: email, password: password, anonId: user.id)
                case .success(let user):
                    print("Successfully linked user: \(user)")
                    self.onLinkInComplete()
                }
            }
        }
    }
    
    func login(email: String, password: String, anonId: String) {
        setLoading(true)
        realmApp.login(credentials: Credentials.emailPassword(email: email, password: password)) { result in
            DispatchQueue.main.async {
                self.setLoading(false)
                switch result {
                case let .failure(error):
                    print("Failed to log in: \(error)")
                    self.reportError(error)
                case .success:
                    guard let user = realmApp.currentUser else { return }
                    self.setLoading(true)
                    user.functions.deleteAnonymousUser([AnyBSON(anonId)], self.onDeleteAnonymousUserCompletion(result:realmError:))
                }
            }
        }
    }
    
    //deleteAnonymousUser
    private func onDeleteAnonymousUserCompletion(result: AnyBSON?, realmError: Error?) {
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
            self.onSignInComplete()
        }
    }
    
    /// Called when sign in completes. Opens the realm asynchronously and navigates to the BooksList screen.
    func onSignInComplete() {
        dismiss(animated: true) {
            self.delegate?.didLoginSuccessful()
        }
    }
    
    func onLinkInComplete() {
        dismiss(animated: true) {
            self.delegate?.didLinkedSuccessful()
        }
    }
    
    /// Turns on or off the activity indicator.
    func setLoading(_ loading: Bool) {
        if loading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        emailField.isEnabled = !loading
        passwordField.isEnabled = !loading
        submitButton.isEnabled = !loading
        changeModeButton.isEnabled = !loading
    }
    
}

