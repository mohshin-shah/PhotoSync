//
//  PhotoCell.swift
//  PhotoSyncApp
//
//  Created by Mohshinsha Shahmadar on 2024-03-12.
//

import Foundation
import UIKit
import Photos
import SDWebImage

class PhotoCell: UICollectionViewCell {
  static let reuseIdentifier = "PhotoCell"
  
  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()
  
  private let syncedIcon: UIImageView = {
    let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
    imageView.tintColor = UIColor.green
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()
  
  private let labelIndicator: UILabel = {
    let label = UILabel()
    label.textColor = .green
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupUI() {
    contentView.addSubview(imageView)
    contentView.addSubview(syncedIcon)
    contentView.addSubview(labelIndicator)
    
    // Constraints for the label
    NSLayoutConstraint.activate([
      labelIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      labelIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
    ])
    
    // Constraints for imageView
    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
    
    // Constraints for syncedIcon
    NSLayoutConstraint.activate([
      syncedIcon.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      syncedIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      syncedIcon.widthAnchor.constraint(equalToConstant: 20),
      syncedIcon.heightAnchor.constraint(equalToConstant: 20),
    ])
  }
  
  func configure(with galleryPhoto: GalleryPhoto) {
    if let urlString = galleryPhoto.url {
      imageView.sd_setImage(with: URL(string: urlString))
    } else {
      GalleryManager
        .shared
        .loadThumbnail(
          forAssetID: galleryPhoto.assetID,
          completion: { [weak self] image, metaData in
            self?.imageView.image = image
          })
    }
    
    switch galleryPhoto.syncStatus {
    case "Syncing":
      backgroundColor = .orange
      labelIndicator.text = "Syncing"
    case "Synced":
      backgroundColor = .purple
      labelIndicator.text = "Done"
    default:
      backgroundColor = .lightGray
      labelIndicator.text = "Local"
    }
    syncedIcon.isHidden = galleryPhoto.syncStatus != "Synced"

  }
}
