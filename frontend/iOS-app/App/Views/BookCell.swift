//
//  BookCell.swift
//  App
//
//  Created by Josman Pedro Pérez Expósito on 25/4/22.
//

import UIKit
import Kingfisher
import RealmSwift

class BookCell: UITableViewCell {

    static let reuseIdentifier = "WineCell"
    static let nibName = "BookCell"
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var ratingView: UIStackView!
    @IBOutlet weak var ratingValue: UILabel!
    @IBOutlet weak var categoryView: UIView!
    @IBOutlet weak var categoryValue: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        categoryView.layer.cornerRadius = 10
        categoryView.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureCell(book: Book, favorites: List<ObjectId>?) {
        guard let volumeInfo = book.volumeInfo else { return }
        if let images = volumeInfo.imageLinks {
            configureImage(images: images)
        }
        title.text = volumeInfo.title
        author.text = (volumeInfo.authors.first != nil) ? "By: \(volumeInfo.authors.first!)" : ""
        if let rating = volumeInfo.averageRating {
            ratingValue.text = "\(rating)"
            ratingView.isHidden = false
        } else {
            ratingView.isHidden = true
        }
        if let category = volumeInfo.categories.first {
            categoryView.isHidden = false
            categoryValue.text = category
        } else {
            categoryView.isHidden = true
        }
        self.selectionStyle = .none
        self.accessoryType = setFavorite(book, favorites: favorites) ? .checkmark : .none
    }
    
    
    /// This method will show the user if the books has been added as favorties
    /// Please note that this is not efficient, but it is just for the sake of this example
    /// - Parameters:
    ///   - book: The book that will be draw
    ///   - favorites: The list of favorites books added by the user
    /// - Returns: Returns true if the id is equal, which means the book have been added
    fileprivate func setFavorite(_ book: Book, favorites: List<ObjectId>?) -> Bool {
        guard let favorites = favorites else {
            return false
        }
        return favorites.contains(where: { $0 == book._id })
    }
    
    fileprivate func configureImage(images: imageLinks) {
        var stringUrl = images.thumbnail
        if let user = realmApp.currentUser, let fullImage = (user.customData["fullImage"] as? AnyBSON)?.boolValue {
            stringUrl = fullImage ? images.thumbnail : images.smallThumbnail
        }
        guard let _url = stringUrl else { return }
        let url = URL(string: _url)
        thumbnail.kf.indicatorType = .activity
        thumbnail.kf.setImage(with: url, options: [
            .transition(.fade(1))])
        
    }
    
}
