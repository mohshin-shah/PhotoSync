//
//  SyncManager.swift
//  PhotoSyncWithRealm
//
//  Created by Mohshinsha Shahmadar on 2024-03-15.
//

import Foundation
import RealmSwift
import Photos

class SyncManager {
  private let batchSize = 300
  private var isSyncing = false
  private var shouldStopSyncing = false
  private var pollingPeriod: UInt32 = 5
  private var notificationToken: NotificationToken?
  
  static let shared = SyncManager()
  
  init(pollingPeriod: UInt32 = 5) {
    self.pollingPeriod = pollingPeriod
    observeDatabaseChanges()
    startSyncing()
  }
  
  private func observeDatabaseChanges() {
    let realm: Realm = try! Realm()
    notificationToken = realm.objects(GalleryPhoto.self).observe { [weak self] changes in
      guard let self = self else { return }
      
      switch changes {
      case .update:
        // Database has been updated, check if there are unsynced photos
        if self.shouldContinueSyncing() && !self.isSyncing {
          self.startSyncing()
        }
      default:
        break
      }
    }
  }
  
  func startSyncing() {
    guard !isSyncing else { return }
    isSyncing = true
    shouldStopSyncing = false
    DispatchQueue.global().async { [weak self] in
      guard let self = self else { return }
      
      while !self.shouldStopSyncing, self.shouldContinueSyncing() {
        print("SyncManager: Checing if anything to sync")
        DispatchQueue.main.async { self.syncNextBatch() }
        sleep(self.pollingPeriod)
      }
      self.isSyncing = false
      print("SyncManager: Synchronization completed")
    }
  }
  
  func stopSyncing() {
    shouldStopSyncing = true
    print("SyncManager: Stopping synchronization")
  }
  
  
  func shouldContinueSyncing() -> Bool {
    let realm: Realm = try! Realm()
    let unsyncedPhotos = realm
      .objects(GalleryPhoto.self)
      .filter("syncStatus == %@", "Local")
    
    if unsyncedPhotos.count == 0 {
      print("SyncManager: Everything Synced Up 🎉")
    }
    
    return unsyncedPhotos.count > 0
  }
  
  private func syncNextBatch() {
    let realm: Realm = try! Realm()
    
    let unsyncedPhotos = realm
      .objects(GalleryPhoto.self)
      .filter("syncStatus == %@", "Local")
    
    guard unsyncedPhotos.count > 0 else {
      stopSyncing()
      return
    }
    
    let batchedPhotos = unsyncedPhotos.prefix(batchSize)
    
    let operations = batchedPhotos
      .map { photo -> SyncOperation in
        DispatchQueue.main.async {
          realm.writeAsync {
            photo.syncStatus = "Syncing"
          }
        }
        let operation = SyncOperation(assetID: photo.assetID) { error in
          DispatchQueue.main.async {
            realm.writeAsync {
              // TODO: For testing I have made it synced, but handle error
              // photo.syncStatus = error == nil ? "Synced" : "Local"
              photo.syncStatus = "Synced"
              photo.url = "https://placehold.co/600x600.jpg"            
            }
            print("SyncManager: Photo \(photo.assetID) synced successfully")
          }
        }
        return operation
      }
    
    let operationQueue = OperationQueue()
    operationQueue.maxConcurrentOperationCount = 30
    operationQueue.addOperations(Array(operations), waitUntilFinished: false)
    print("SyncManager: Synchronizing batch of \(operations.count) photos")
  }
}

class SyncOperation: Operation {
  private let assetID: String
  let completion: ((Error?) -> Void)?

  init(assetID: String, completion: ((Error?) -> Void)?) {
    self.assetID = assetID
    self.completion = completion
    super.init()
  }
  
  override func main() {
    guard !isCancelled else { return }
    
    // Perform synchronization task (e.g., API call)
    // For demonstration purposes, let's print a log statement
    guard let asset = fetchAsset(withLocalIdentifier: assetID) else { return }
    print("SyncOperation: Synchronizing photo \(assetID)")
    print("SyncOperation: Starting to upload photo \(assetID)")
    guard let fileURL = copyAssetToFileDirectory(asset) else {
      print("SyncOperation Error: Failed to copy asset \(assetID)")
      return
    }
    uploadFileToServer(fileURL)
  }
  
  private func fetchAsset(withLocalIdentifier localIdentifier: String) -> PHAsset? {
    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
    return fetchResult.firstObject
  }
  
  private func copyAssetToFileDirectory(_ asset: PHAsset) -> URL? {
    let fileManager = FileManager.default
    let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let directoryURL = documentsDirectory.appendingPathComponent("Assets", isDirectory: true)
    
    do {
      // Create directory if it doesn't exist
      try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
      let fileName = assetID.replacing("/", with: "_")
      let fileURL = directoryURL.appendingPathComponent("\(fileName).jpg")
      
      let options = PHImageRequestOptions()
      options.isNetworkAccessAllowed = true
      
      let imageManager = PHImageManager.default()
      imageManager.requestImageDataAndOrientation(for: asset, options: options) { [weak self] (data, _, _, _) in
        if let imageData = data {
          do {
            // Write the image data to the file
            try imageData.write(to: fileURL)
          } catch {
            self?.completion?(error)
            print("SyncOperation Error: Writing image data to file failed: \(error)")
          }
        }
      }
      return fileURL
    } catch {
      completion?(error)
      print("SyncOperation Error: Creating directory failed: \(error)")
      return nil
    }
  }
  
  
  private func uploadFileToServer(_ fileURL: URL) {
    // let uploadTask = URLSession.shared.uploadTask(with: request, fromFile: fileURL) { data, response, error in
    //     // Handle upload response
    // }
    // uploadTask.resume()
    print("Uploading file to server: \(fileURL)")
    sleep(2)
    completion?(nil)
  }
}
