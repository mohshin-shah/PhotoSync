//
//  GalleryPhoto.swift
//  PhotoSyncWithRealm
//
//  Created by Mohshinsha Shahmadar on 2024-03-15.
//

import Foundation
import RealmSwift

class GalleryPhoto: Object {
  @Persisted var assetID: String = ""
  @Persisted var createdDate: Date = Date()
  @Persisted var url: String?
  @Persisted var syncStatus: String = "Local"
  @Persisted var sectionID: Date
  @Persisted var mediaType: Int
  
  // Specify primary key
  override class func primaryKey() -> String? {
    return "assetID"
  }
  
  var formattedCreatedDate: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return dateFormatter.string(from: createdDate)
  }
}

