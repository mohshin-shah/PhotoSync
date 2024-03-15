//
//  ViewController.swift
//  PhotoSyncApp
//
//  Created by Mohshinsha Shahmadar on 2024-03-12.
//

import UIKit
import Photos
import RealmSwift

class GalleryVC: UIViewController {
  private var galleryPhotos = [GalleryPhoto]()
  private var currentOffset = 0
  private let pageSize = 200
  
  lazy var dataSource: GalleryDataSource = GalleryDataSource(collectionView: collectionView)
  var isApplyingChanges = false
  
  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.alwaysBounceVertical = true
    collectionView.delegate = self
    collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.reuseIdentifier)
    collectionView
      .register(
        CustomHeaderView.self,
        forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
        withReuseIdentifier: CustomHeaderView.reuseIdentifier
      )
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    return collectionView
  }()
  
  var isLoadingPage = false
  let mockGalleryPhotoGenerator = MockGalleryPhotoGenerator()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(collectionView)
    setupNavigationBar()
    setupConstraints()
    checkPhotoLibraryPermission()
    collectionView.dataSource = dataSource
    
    mockGalleryPhotoGenerator.startGenerating()
    SyncManager.shared.startSyncing()
  }
  
  private func setupConstraints() {
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
  
  private func checkPhotoLibraryPermission() {
    let status = PHPhotoLibrary.authorizationStatus()
    switch status {
    case .authorized:
      startLoadingPhotos()
      
    case .denied, .restricted:
      print("Permission Error")
      
    case .notDetermined:
      // Request photo library access
      PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
        if newStatus == .authorized {
          DispatchQueue.main.async {
            self?.startLoadingPhotos()
          }
        } else {
          // Display an alert or UI indicating that the user needs to enable photo access in settings
          print("Permission Error")
        }
      }
    default:
      fatalError("Unknown")
    }
  }
  
  private func startLoadingPhotos() {
    currentOffset = 0
    loadNextPage()
  }
}

extension GalleryVC: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let collectionViewWidth = collectionView.bounds.width
    let itemWidth = (collectionViewWidth - 16) / 5
    return CGSize(width: itemWidth, height: itemWidth)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    .init(width: view.frame.size.width, height: 60)
  }
}

extension GalleryVC {
  private func  loadNextPage() {
    guard !isLoadingPage else { return }
    
    self.isLoadingPage = true
    
    GalleryManager
      .shared
      .loadLocalGalleryPhotos(
        offset: currentOffset,
        pageSize: pageSize,
        completion: { [weak self] phAssetsCount in
          guard let self = self else { return }
          self.isLoadingPage = false
          if phAssetsCount > 0 {
            self.currentOffset += phAssetsCount + 1
          }
        }
      )
  }
}

extension GalleryVC: UICollectionViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let offset = scrollView.contentOffset.y
    let contentHeight = scrollView.contentSize.height
    let height = scrollView.frame.size.height
    
    if offset > (contentHeight - height) * 0.5 {
      loadNextPage()
    }
  }
}

extension GalleryVC {
  private func setupNavigationBar() {
    // Add button to update sync status to "Local"
    let updateToLocalButton = UIBarButtonItem(title: "Make All Local", style: .plain, target: self, action: #selector(updateSyncStatusToLocal))
    navigationItem.leftBarButtonItem = updateToLocalButton
    
    // Add button to clean database
    let cleanDatabaseButton = UIBarButtonItem(title: "Stop Mock", style: .plain, target: self, action: #selector(cleanDatabase))
    navigationItem.rightBarButtonItem = cleanDatabaseButton
  }
  
  @objc private func updateSyncStatusToLocal() {
    DispatchQueue.main.async {
      let realm = try! Realm()
      let allPhotos = realm.objects(GalleryPhoto.self)
      realm.writeAsync {
        allPhotos.forEach { $0.syncStatus = "Local" }
      }
    }
    
    SyncManager.shared.startSyncing()
  }
  
  @objc private func cleanDatabase() {
    mockGalleryPhotoGenerator.stopGenerating()
  }
}
