//
//  MockTester.swift
//  PhotoSyncWithRealm
//
//  Created by Mohshinsha Shahmadar on 2024-03-15.
//

import Foundation
import RealmSwift

class MockGalleryPhotoGenerator {
  private var timer: Timer?
  
  func startGenerating() {
    // Invalidate previous timer, if any
    stopGenerating()
    
    // Start a new timer to generate dummy GalleryPhotos every 2 seconds
    timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
      print("MOCK: Inserting API Synced Photo in the List")
      self?.addPhotosFromAPI()
    }
  }
  
  func stopGenerating() {
    // Invalidate the timer to stop generating dummy GalleryPhotos
    timer?.invalidate()
    timer = nil
  }
  
  private func addPhotosFromAPI() {
    DispatchQueue.main.async {
      let realm = try! Realm()
      let photos = realm
        .objects(GalleryPhoto.self)

      guard photos.count < 15000 else {
        print("MOCK: Loaded total \(photos.count) photos")
        self.stopGenerating()
        return
      }

      realm.writeAsync {
        (1...Int.random(in: 100...150)).forEach { _ in
          let photo = GalleryPhoto()
          let sectionID = Date
            .randomDateInMarch(
              month: .random(in: 1...4),
              year: 2024
            )
            .toDDMMYYYY().toDate()
          
          photo.assetID = UUID().uuidString
          photo.sectionID = sectionID
          photo.createdDate = sectionID
          photo.mediaType = Int.random(in: 0...3)
          photo.syncStatus = Bool.random() ? "Local" : "Synced"
          photo.url = nil
          realm.add(photo)
        }
      }
    }
  }
}

extension Date {
  static func randomDateInMarch(month: Int, year: Int) -> Date {
    let calendar = Calendar.current
    var components = DateComponents()
    components.year = year
    components.month = month // March
    
    guard let startDate = calendar.date(from: components),
          let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
      return .init()
    }
    
    let randomTimeInterval = TimeInterval(arc4random_uniform(UInt32(endDate.timeIntervalSince(startDate))))
    return Date(timeInterval: randomTimeInterval, since: startDate)
  }
}
