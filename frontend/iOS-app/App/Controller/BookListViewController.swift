//
//  BookListViewController.swift
//  App
//
//  Created by Josman Pedro Pérez Expósito on 19/4/22.
//

import UIKit
import Realm.RLMUser
import RealmSwift
import FirebaseMessaging

class BookListViewController: UITableViewController {
    
    static let loginSegue = "showLogin"
    static let showFavorites = "showFavorites"
    static let showSettings = "showSettings"
    
    @IBOutlet weak var userActions: UIBarButtonItem!
    @IBOutlet weak var favoriteBtn: UIBarButtonItem!
    @IBOutlet weak var settingBtn: UIBarButtonItem!
    
    let spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        return  view
    }()
    var spinnerView = UIView(frame: CGRect.zero)
    
    /// Use the default realm. For a synced realm, the default realm configuration
    /// should already be set to the user's sync configuration.
    var realm = try! Realm()
    lazy var books: Results<Book>? = nil
    var notificationToken: NotificationToken?
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLoadingView()
        tableView.register(UINib(nibName: BookCell.nibName, bundle: nil), forCellReuseIdentifier: BookCell.reuseIdentifier)
        if let _user = realmApp.currentUser {
            let publicRealm = try! Realm(configuration: _user.configuration(partitionValue: "global"))
            books = publicRealm.objects(Book.self).sorted(byKeyPath: "identifier")
        }
    }
    
    /// Stops observing the user  in the realm when the view disappears.
    override func viewWillDisappear(_ animated: Bool) {
        notificationToken?.invalidate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureTintColor()
        if let _user = realm.objects(User.self).first {
            observeUser(_user)
            setUserActionBtn(for: _user)
            user = _user
        }
    }
    
    
    /// MongoDB Realm does not dynamically update the value of the client-side user custom data document immediately when underlying data changes. Instead, MongoDB Realm fetches the most recent version of custom user data whenever a user refreshes their access token, which is used by most SDK operations that contact the MongoDB Realm back end. If the token is not refreshed before its default 30 minute expiration time, Realm refreshes the token on the next call to the backend. Custom user data could be stale for up to 30 minutes plus the time until the next SDK call to the backend occurs
    func configureTintColor() {
        guard let user = realmApp.currentUser else { return }
        if let color = (user.customData["color"] as? AnyBSON)?.stringValue {
            navigationController?.navigationBar.tintColor = UIColor(hex: color)
            tableView.tintColor = UIColor(hex: color)
        }
    }
    
    func configureLoadingView() {
        spinnerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        spinner.center = spinnerView.center
        spinner.style = .large
        spinnerView.backgroundColor = UIColor.lightGray
        spinnerView.alpha = 0.5
        spinnerView.addSubview(spinner)
        spinnerView.isHidden = true
        self.tableView.addSubview(spinnerView)
    }
    
    func setLoading(_ show: Bool) {
        tableView.isScrollEnabled = !show
        show ? spinner.startAnimating() : spinner.stopAnimating()
        spinnerView.isHidden = !show
    }
    
    func observeUser(_ user: User) {
        notificationToken = user.observe { changes in
            switch changes {
            case .change(let object, let properties):
                for property in properties {
                    print("Property '\(property.name)' changed")
                }
                self.tableView.reloadData()
                self.setUserActionBtn(for: object as! User)
            case .error(let error):
                print("An error occurred: \(error)")
            case .deleted:
                print("The object was deleted.")
            }
        }
    }
    
    /// Change the title of the button depending on the type of authentication
    /// - Parameter user: User
    func setUserActionBtn(for user: User) {
        userActions.isEnabled = user.providerType?.provider_type == .anon
        userActions.title = user.providerType?.provider_type == .anon ? "Register" : user.userPreferences?.displayName
        favoriteBtn.isEnabled = user.providerType?.provider_type == .anon ? false : true
        settingBtn.isEnabled = user.providerType?.provider_type == .anon ? false : true
    }
    
    // MARK: - TableView methods
    
    /// Returns the number of books in the realm.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let books = books else { return 0 }
        return books.count
    }
    
    /// Defines the appearance of the books items in the list.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BookCell.reuseIdentifier, for: indexPath) as? BookCell else { return UITableViewCell() }
        guard let books = books else { return UITableViewCell() }
        let book = books[indexPath.row]
        // Show the books name text on the left.
        cell.configureCell(book: book, favorites: user?.favoriteBooks)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let user = user, let books = books else { return }
        let book = books[indexPath.row]
        if !user.registered {
            createAlert(title: "Register!", message: "To save \(book.volumeInfo?.title ?? "") as a favorite, you need to register first")
        } else {
            addToFavorite(user: user, book: book)
        }
        
    }
    
    fileprivate func addToFavorite(user: User, book: Book) {
        let alertController: UIAlertController
        // Check if is already added
        if !user.favoriteBooks.contains(book._id) {
            alertController = UIAlertController(title: "Add to favorites", message: "Do you want to add \(book.volumeInfo?.title ?? "") as favorite?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alertController.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
                // Any writes to the Realm must occur in a write block.
                do {
                    try self.realm.write {
                        // Add the book to the wine list for the user
                        user.favoriteBooks.append(book._id)
                    }
                } catch (let error) {
                    self.reportError(error)
                }
                alertController.dismiss(animated: true)
            }))
        } else {
            alertController = UIAlertController(title: "Remove from favorites", message: "Do you want to remove \(book.volumeInfo?.title ?? "") from your favorite list?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alertController.addAction(UIAlertAction(title: "Accept", style: .default, handler: { _ in
                // Any writes to the Realm must occur in a write block.
                do {
                    try self.realm.write {
                        if let index = user.favoriteBooks.firstIndex(of: book._id) {
                            user.favoriteBooks.remove(at: index)
                        }
                    }
                } catch (let error) {
                    self.reportError(error)
                }
                alertController.dismiss(animated: true)
            }))
        }
        present(alertController, animated: true)
    }
    
    fileprivate func createAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            alertController.dismiss(animated: true)
        }))
        present(alertController, animated: true)
    }
    
    // MARK: - Button actions
    
    /// Method to launch either the login screen or to logout depending on the state of the current user
    /// - Parameter sender: Any
    @IBAction func userAction(_ sender: Any) {
        guard let user = user else { return }
        if !user.registered {
            performSegue(withIdentifier: BookListViewController.loginSegue, sender: nil)
        }
    }
    
    @IBAction func showFavorites(_ sender: Any) {
        guard let user = user else { return }
        performSegue(withIdentifier: BookListViewController.showFavorites, sender: user)
    }
    
    @IBAction func showOptions(_ sender: Any) {
        guard let user = realmApp.currentUser else { return }
        performSegue(withIdentifier: BookListViewController.showSettings, sender: user)
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == BookListViewController.loginSegue {
            if let vc = segue.destination as? LoginViewController, let prevUser = realmApp.currentUser {
                vc.anonUser = prevUser
                vc.delegate = self
            }
        } else if segue.identifier == BookListViewController.showFavorites {
            if let vc = segue.destination as? FavoritesTableViewController, let user = sender as? User {
                vc.user = user
                vc.books = books
                vc.delegate = self
            }
        } else if segue.identifier == BookListViewController.showSettings {
            if let vc = segue.destination as? SettingsViewController, let user = sender as? RLMUser {
                vc.user = user
                vc.delegate = self
            }
        }
    }
    
}

extension BookListViewController: RemoveFavoriteProtocol {
    
    /// Eliminar los favoritos desde la vista de favoritos
    /// - Parameter index: El indice del favorito a borrar
    func didRemoveFavorite(index: Int) {
        guard let user = user else { return }
        do {
            try realm.write {
                user.favoriteBooks.remove(at: index)
                self.tableView.reloadData()
            }
        } catch (let error) {
            self.reportError(error)
        }
    }
}

extension BookListViewController: OnLoginProtocol {
    
    func didLoginSuccessful() {
        if let user = realmApp.currentUser {
            setLoading(true)
            Realm.Configuration.defaultConfiguration = user.configuration(partitionValue: "\(user.id)")
            // Open new user Realm
            Realm.asyncOpen { [self] result in
                setLoading(false)
                switch result {
                case .failure(let error):
                    print("Failed to open realm: \(error)")
                    self.reportError(error)
                case .success(let realm):
                    self.realm = realm
                    if let _user = realm.objects(User.self).first {
                        self.observeUser(_user)
                        self.setUserActionBtn(for: _user)
                        self.user = _user
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    func didLinkedSuccessful() {
        print("Linked successfull")
    }
}

extension BookListViewController: OnSettingChanged {
    
    func didSettingChanged(customData: [String: Any]) {
        guard let color = customData["color"] as? String else { return }
        navigationController?.navigationBar.tintColor = UIColor(hex: color)
        tableView.tintColor = UIColor(hex: color)
    }
}


