//
//  EditToolView.swift
//  VideoCat
//
//  Created by Vito on 2018/7/7.
//  Copyright © 2018 Vito. All rights reserved.
//

import UIKit
import TinyConstraints

protocol ItemsProvider: class {
    var items: [EditItem] { get }
}

class EditToolView: UIView {
    private var collectionView: UICollectionView!
    private var backButton: UIButton!
    var itemsProvider: ItemsProvider! {
        didSet {
            collectionView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        backButton = UIButton(type: .custom)
        addSubview(backButton)
        backButton.setTitle("<", for: .normal)
        backButton.backgroundColor = UIColor.darkGray
        backButton.setTitleColor(UIColor.white, for: .normal)
        
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
        flowLayout.itemSize = CGSize.init(width: 60, height: 60)
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
        addSubview(collectionView)
        
        backButton.left(to: self)
        backButton.top(to: self)
        backButton.bottom(to: self)
        backButton.width(40)
        
        collectionView.leftToRight(of: backButton)
        collectionView.top(to: self)
        collectionView.right(to: self)
        collectionView.bottom(to: self)
        
        collectionView.register(BasicEditItemCell.self, forCellWithReuseIdentifier: BasicEditItemCell.reuseIdentifier)
    }
    
}

extension EditToolView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsProvider.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = itemsProvider.items[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.editInfo.cellIdentifier, for: indexPath)
        if let cell = cell as? BasicEditItemCell {
            cell.titleLabel.text = item.editInfo.title
            cell.iconImageView.image = item.editInfo.thumb
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = itemsProvider.items[indexPath.item]
        item.editAction()
    }
}

class BasicEditItemCell: UICollectionViewCell {
    var titleLabel: UILabel!
    var iconImageView: UIImageView!
    
    static let reuseIdentifier = "BasicCellIdentifier"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        titleLabel = UILabel(frame: CGRect.zero)
        contentView.addSubview(titleLabel)
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textAlignment = .center
        
        iconImageView = UIImageView(image: nil)
        contentView.addSubview(iconImageView)
        iconImageView.backgroundColor = UIColor.lightGray
        
        iconImageView.topToSuperview().constant = 10
        iconImageView.centerXToSuperview()
        iconImageView.size(CGSize(width: 44, height: 44))
        
        titleLabel.topToBottom(of: iconImageView)
        titleLabel.leftToSuperview()
        titleLabel.rightToSuperview()
    }
    
}
