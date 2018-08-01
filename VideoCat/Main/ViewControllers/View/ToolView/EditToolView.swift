//
//  EditToolView.swift
//  VideoCat
//
//  Created by Vito on 2018/7/7.
//  Copyright © 2018 Vito. All rights reserved.
//

import UIKit
import TinyConstraints
import VFCabbage

protocol ItemsProvider: class {
    var items: [EditItem] { get }
}

class EditToolView: UIView {
    private var collectionView: UICollectionView!
    private(set) var backButton: UIButton!
    private var backButtonWidth: NSLayoutConstraint!
    
    var backHandler: (() -> ())?
    
    // MARK: - Data
    var itemsProvider: ItemsProvider! {
        didSet {
            collectionView.reloadData()
        }
    }
    
    // MARK: - Life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = UIColor.init(white: 0.2, alpha: 1)
        
        backButton = UIButton(type: .custom)
        addSubview(backButton)
        backButton.setTitle("<", for: .normal)
        backButton.backgroundColor = UIColor.darkGray
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.addTarget(self, action: #selector(backAction(sender:)), for: .touchUpInside)
        
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
        backButtonWidth = backButton.width(40)
        
        collectionView.leftToRight(of: backButton)
        collectionView.top(to: self)
        collectionView.right(to: self)
        collectionView.bottom(to: self)
        
        collectionView.register(BasicEditItemCell.self, forCellWithReuseIdentifier: BasicEditItemCell.reuseIdentifier)
    }
    
    @objc fileprivate func backAction(sender: UIButton) {
        backHandler?()
    }
    
    // MARK: - Logic method
    
    func hideBackButton() {
        backButtonWidth.constant = 0
    }
    
    func showBackButton() {
        backButtonWidth.constant = 40
    }
    
    
    // MARK: - Container
    var presentedEditToolView: EditToolView? {
        return superview as? EditToolView
    }
    var presentingEditToolView: EditToolView? {
        didSet {
            if presentedEditToolView == self {
                assert(false, "Can't present self")
            }
        }
    }
    weak var parentToolView: EditToolView?
    var childToolViews: [EditToolView] = []
    
    func present(_ toolView: EditToolView, animated: Bool, completion: (()-> Void)? = nil) {
        if self.presentingEditToolView != nil {
            Log.warning("Already presented tool view")
            assert(false, "Already presented tool view")
            return
        }
        addSubview(toolView)
        toolView.frame = bounds
        self.presentingEditToolView = toolView
        if animated {
            toolView.alpha = 0.0
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                toolView.alpha = 1.0
            }) { (finished) in
                completion?()
            }
        }
    }
    
    func dismiss(animated: Bool, completion: (()-> Void)? = nil) {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.alpha = 0.0
            }) { (finished) in
                if let superview = self.superview as? EditToolView {
                    superview.presentingEditToolView = nil
                }
                self.removeFromSuperview()
                completion?()
            }
        } else {
            if let superview = superview as? EditToolView {
                superview.presentingEditToolView = nil
            }
            removeFromSuperview()
        }
    }
    
    func push(_ toolView: EditToolView, animated: Bool, completion: (()-> Void)? = nil) {
        addSubview(toolView)
        toolView.frame = bounds
        childToolViews.append(toolView)
        toolView.parentToolView = self
        if animated {
            toolView.alpha = 0.0
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                toolView.alpha = 1.0
            }) { (finished) in
                completion?()
            }
        }
    }
    
    func pop(animated: Bool, completion: (()-> Void)? = nil) {
        func removeAction() {
            if let parentToolView = self.parentToolView {
                if let index = parentToolView.childToolViews.index(where: { $0 == self }) {
                    self.parentToolView?.childToolViews.remove(at: index)
                }
            }
            self.removeFromSuperview()
            completion?()
        }
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.alpha = 0.0
            }) { (finished) in
                removeAction()
            }
        } else {
            removeAction()
        }
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
