//
//  Datasource.swift
//  PhotoSyncAppWithDB
//
//  Created by Mohshinsha Shahmadar on 2024-03-15.
//

import Foundation
import UIKit
import RealmSwift

import RealmSwift

class GalleryDataSource: NSObject {
  private var notificationToken: NotificationToken?
  private var sectionedGalleryPhotos: SectionedResults<Date, GalleryPhoto>!
  
  private weak var collectionView: UICollectionView?
  
  init(collectionView: UICollectionView) {
    self.collectionView = collectionView
    super.init()
    performFetch()
  }
  
  private func performFetch() {
    DispatchQueue.main.async {
      do {
        let realm = try Realm()
        self.sectionedGalleryPhotos = realm.objects(GalleryPhoto.self)
          .sorted(by: \.createdDate)
          .sectioned(by: \.sectionID, ascending: false)
        self.notificationToken = self.sectionedGalleryPhotos
          .observe { [weak self] changes in
            guard let self = self else { return }
            self.handleChanges(changes)
          }
      } catch {
        print("Error initializing Realm: \(error.localizedDescription)")
      }
    }
  }
  
  private func handleChanges(_ changes: SectionedResultsChange<SectionedResults<Date, GalleryPhoto>>) {
    switch changes {
    case .initial:
      DispatchQueue.main.async {
        self.collectionView?.reloadData()
      }
    case .update(_, let deletions, let insertions, let modifications, let sectionsToInsert, let sectionsToDelete):
      DispatchQueue.main.async {
        UIView.animate(withDuration: 0) {
          self.collectionView?.performBatchUpdates({
            self.collectionView?.deleteSections(sectionsToDelete)
            self.collectionView?.insertSections(sectionsToInsert)
            self.collectionView?.deleteItems(at: deletions)
            self.collectionView?.insertItems(at: insertions)
            self.collectionView?.reloadItems(at: modifications)
          }, completion: nil)
        }
      }
    }
  }
  
  deinit {
    notificationToken?.invalidate()
  }
}

extension GalleryDataSource: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    sectionedGalleryPhotos?.allKeys.count ?? 0
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let section = sectionedGalleryPhotos?[section]
    return section?.count ?? 0
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.reuseIdentifier, for: indexPath) as? PhotoCell,
          let galleryPhoto = sectionedGalleryPhotos?[indexPath] else {
      fatalError("Unable to dequeue PhotoCell")
    }
    
    cell.configure(with: galleryPhoto)
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    guard kind == UICollectionView.elementKindSectionHeader else {
      fatalError("Unexpected supplementary view kind")
    }
    
    let headerView = collectionView
      .dequeueReusableSupplementaryView(
        ofKind: kind,
        withReuseIdentifier: CustomHeaderView.reuseIdentifier,
        for: indexPath
      ) as! CustomHeaderView
    
    let section: ResultsSection<Date, GalleryPhoto> = sectionedGalleryPhotos[indexPath.section]
    
    
    headerView.configure(with: section.key.toDDMMYYYY())
    return headerView
  }
}
