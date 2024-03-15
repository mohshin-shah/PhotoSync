//
//  DataBase.swift
//  PhotoSyncApp
//
//  Created by Mohshinsha Shahmadar on 2024-03-14.
//

import Foundation
import Photos
import RealmSwift

class DBManager {
  static let shared = DBManager()
  
  func saveAsset(_ asset: PHAsset) {
    DispatchQueue.main.async {
      let realm = try! Realm()
      realm.writeAsync {
        let assetID = asset.localIdentifier
        if let existingAsset = realm.object(ofType: GalleryPhoto.self, forPrimaryKey: assetID) {
          // Update existing asset if needed
          // TODO: Replace with any data if needed
        } else if let createdDate = asset.creationDate {
          let photo = GalleryPhoto()
          let sectionID = createdDate.toDDMMYYYY().toDate()
          photo.assetID = asset.localIdentifier
          photo.sectionID = sectionID
          photo.createdDate = createdDate
          photo.mediaType = asset.mediaType.rawValue
          photo.syncStatus = "Local"
          photo.url = nil
          realm.add(photo)
        }
      } onComplete: { error in
        if let error = error {
          debugPrint("DB: Error while saving \(error)")
        }
      }
    }
  }
  
  func updateOrInsertLocal(assets: [PHAsset]) {
    for asset in assets {
      saveAsset(asset)
    }
  }
}
