//
//  FavoritesTableViewController.swift
//  App
//
//  Created by Josman Pedro Pérez Expósito on 23/4/22.
//

import UIKit
import RealmSwift

protocol RemoveFavoriteProtocol {
    func didRemoveFavorite(index: Int)
}

class FavoritesTableViewController: UITableViewController {

    var user: User?
    static let cellIdentifier = "favCell"
    var books: Results<Book>?
    var delegate: RemoveFavoriteProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let user = user else { return 0 }
        return user.favoriteBooks.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let user = user, let books = books else { return UITableViewCell() }
        let _books = books.where {
            ($0._id == user.favoriteBooks[indexPath.row])
        }
        guard let book = _books.first, let title = book.volumeInfo?.title else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: FavoritesTableViewController.cellIdentifier, for: indexPath)
        cell.textLabel?.text = title
        cell.selectionStyle = .none
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            delegate?.didRemoveFavorite(index: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

}
