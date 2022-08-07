//
//  ImageCell.swift
//  HopiModal
//
//  Created by namik kaya on 24.07.2022.
//

import UIKit

class ImageCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet private weak var posterImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setup(image: UIImage, heigth: CGFloat) {
        posterImage.image = image
        imageHeight.constant = heigth
        posterImage.contentMode = .scaleAspectFill
    }
    
    func setHeightOfAnimation(height: CGFloat) {
        UIView.animate(withDuration: 0.3) {
            self.imageHeight.constant = height
            self.layoutIfNeeded()
        }
    }
    
    func setHeight(height: CGFloat) {
        self.imageHeight.constant = height
    }
}
