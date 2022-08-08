//
//  GalleryVC.swift
//  HopiModal
//
//  Created by namik kaya on 24.07.2022.
//

import UIKit

protocol GalleryVCDelegate: AnyObject {
    func closeFullsize()
}

final class GalleryVC: BaseBackgroundViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    let imageList = [UIImage(named: "steveUncle"), UIImage(named: "steveUncle") ,UIImage(named: "steveUncle")]
    
    private var heightHolder: CGFloat = 0
    weak var delegate: GalleryVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupColletionView()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.heightHolder = self.view.frame.size.height
        }
    }
    
    private func setupColletionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(cellType: ImageCell.self)
       
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = collectionView.frame.size
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        collectionView.setCollectionViewLayout(layout, animated: false)
        collectionView.isPagingEnabled = true
        collectionView.alwaysBounceVertical = false
    }
    
    override func setAnimation(height: CGFloat, duration: TimeInterval) {
        super.setAnimation(height: height, duration: duration)
        self.heightHolder = height
        self.collectionView.visibleCells.forEach { itemCell in
            if let cell = itemCell as? ImageCell {
                cell.setHeightOfAnimation(height: height)
            }
        }
    }
    
    override func areaOfViewable(height: CGFloat) {
        super.areaOfViewable(height: height)
        self.heightHolder = height
        self.collectionView.visibleCells.forEach { itemCell in
            if let cell = itemCell as? ImageCell {
                cell.setHeight(height: height)
            }
        }
    }
    
    @IBAction func closeAction(_ sender: Any) {
        delegate?.closeFullsize()
    }
}

extension GalleryVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ImageCell {
            cell.setHeight(height: self.heightHolder)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(with: ImageCell.self, for: indexPath)
        cell.setup(image: imageList[indexPath.row] ?? UIImage(named: "steveUncle")!, heigth: self.view.frame.height)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.view.frame.size
    }
    
}

// projeye aktarıldığında silincek
public extension UICollectionView {
    func register<T: UICollectionViewCell>(cellType: T.Type, bundle: Bundle? = nil) {
        let className = cellType.className
        let nib = UINib(nibName: className, bundle: bundle)
        register(nib, forCellWithReuseIdentifier: className)
    }
    
    func register<T: UICollectionViewCell>(cellTypes: [T.Type], bundle: Bundle? = nil) {
        cellTypes.forEach { register(cellType: $0, bundle: bundle) }
    }
    
    func register<T: UICollectionReusableView>(reusableViewType: T.Type,
                                                      ofKind kind: String = UICollectionView.elementKindSectionHeader,
                                                      bundle: Bundle? = nil) {
        let className = reusableViewType.className
        let nib = UINib(nibName: className, bundle: bundle)
        register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: className)
    }
    
    func register<T: UICollectionReusableView>(reusableViewTypes: [T.Type],
                                                      ofKind kind: String = UICollectionView.elementKindSectionHeader,
                                                      bundle: Bundle? = nil) {
        reusableViewTypes.forEach { register(reusableViewType: $0, ofKind: kind, bundle: bundle) }
    }
    
    func dequeueReusableCell<T: UICollectionViewCell>(with type: T.Type,
                                                             for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withReuseIdentifier: type.className, for: indexPath) as! T
    }
    
    func dequeueReusableView<T: UICollectionReusableView>(with type: T.Type,
                                                                 for indexPath: IndexPath,
                                                                 ofKind kind: String = UICollectionView.elementKindSectionHeader) -> T {
        return dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: type.className, for: indexPath) as! T
    }
    
    func validate(indexPath: IndexPath) -> Bool {
        if indexPath.section >= numberOfSections {
            return false
        }
        if indexPath.row >= numberOfItems(inSection: indexPath.section) {
            return false
        }
        return true
    }
}

public protocol ClassNameProtocol {
    static var className: String { get }
    var className: String { get }
}

public extension ClassNameProtocol {
    static var className: String {
        return String(describing: self)
    }
    
    var className: String {
        return type(of: self).className
    }
}

extension NSObject: ClassNameProtocol {
    public static var className: String { return String(describing: self) }
}
