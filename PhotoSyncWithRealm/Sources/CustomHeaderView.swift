//
//  CustomHeaderView.swift
//  PhotoSyncAppWithDB
//
//  Created by Mohshinsha Shahmadar on 2024-03-14.
//

import Foundation
import UIKit

class CustomHeaderView: UICollectionReusableView {
  static let reuseIdentifier = "CustomHeaderView"
  
  let label: UILabel = {
    let label = UILabel()
    // Customize label properties as needed
    label.textColor = .black
    label.font = UIFont.systemFont(ofSize: 22, weight: .regular)
    return label
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func commonInit() {
    addSubview(label)
    // Add constraints to position the label as desired
    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      label.topAnchor.constraint(equalTo: topAnchor),
      label.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
  }
  
  func configure(with date: String?) {
    label.text = date
  }
}
