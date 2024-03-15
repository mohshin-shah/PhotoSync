//
//  GalleryManager+Local.swift
//  PhotoSyncAppWithDB
//
//  Created by Mohshinsha Shahmadar on 2024-03-14.
//

import Foundation
import Photos

typealias GalleryDateWisePhotos = [Date: [GalleryPhoto]]

extension GalleryManager {
  func loadLocalGalleryPhotos(
    offset: Int,
    pageSize: Int,
    completion: @escaping (Int) -> Void
  ) {
    DispatchQueue.global(qos: .userInteractive).async {
      let fetchResult = PHAsset.fetchAssets(with: .image, options: self.fetchOptions)
      let totalCount = fetchResult.count
      let start = min(offset, totalCount)
      let end = min(offset + pageSize, totalCount)
      
      var photoAssets = [PHAsset]()
      for index in start..<end {
        let asset = fetchResult.object(at: index)        
        photoAssets.append(asset)
      }
      print("PAGING: Loading page from \(offset) to \(offset + pageSize): \(photoAssets.count) new local photos found")
      DBManager.shared.updateOrInsertLocal(assets: photoAssets)
      DispatchQueue.main.async { completion(photoAssets.count) }
    }
  }
}

extension String {
  func toDate(with format: String = "dd/MM/yyyy") -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    return dateFormatter.date(from: self) ?? .init()
  }
}

extension Date {
  func toDDMMYYYY() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd/MM/yyyy"
    return dateFormatter.string(from: self)
  }
}
