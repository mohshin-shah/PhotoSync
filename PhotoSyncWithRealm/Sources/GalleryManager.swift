//
//  GalleryManager.swift
//  PhotoSyncApp
//
//  Created by Mohshinsha Shahmadar on 2024-03-12.
//

import Foundation
import Photos
import Combine
import UIKit

class GalleryManager {
  static let shared = GalleryManager()
  
  let imageManager = PHCachingImageManager()
  
  let fetchOptions: PHFetchOptions = {
    let options = PHFetchOptions()
    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    return options
  }()
}

extension GalleryManager {
  func groupPhotosByDate(
    _ galleryPhotos: [GalleryPhoto]
  ) -> [Date: [GalleryPhoto]] {
    var groupedPhotos = [Date: [GalleryPhoto]]()
    for photo in galleryPhotos {
      let date = Calendar.current.startOfDay(for: photo.createdDate)
      if var photos = groupedPhotos[date] {
        photos.append(photo)
        groupedPhotos[date] = photos
      } else {
        groupedPhotos[date] = [photo]
      }
    }
    return groupedPhotos
  }
}

extension GalleryManager {
  func loadThumbnail(
    forAssetID assetID: String?,
    completion: @escaping (UIImage?, [String: Any]?
    ) -> Void) {
    guard let assetID = assetID else { return }
    DispatchQueue.global(qos: .userInteractive).async {
      let options = PHFetchOptions()
      let asset = PHAsset
        .fetchAssets(
          withLocalIdentifiers: [assetID],
          options: options
        )
        .firstObject
      
      guard let phAsset = asset else {
        DispatchQueue.main.async { completion(nil, nil) }
        return
      }
      
      let requestOptions = PHImageRequestOptions()
      requestOptions.isSynchronous = false
      
      self.imageManager.requestImage(for: phAsset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: requestOptions) { image, _ in
        
        DispatchQueue.main.async {
          completion(image, nil)
        }
      }
    }
  }
}

extension GalleryPhoto {
  public override var description: String { "\(assetID) Status: \(syncStatus) "}
}
