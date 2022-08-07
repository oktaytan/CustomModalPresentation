//
//  BaseBackgroundController.swift
//  HopiModal
//
//  Created by namik kaya on 30.07.2022.
//

import UIKit

protocol Scrollable {
    func areaOfViewable(height: CGFloat)
    func setAnimation(height: CGFloat, duration: TimeInterval)
}

extension Scrollable {
    func areaOfViewable(height: CGFloat) {}
    func setAnimation(height: CGFloat, duration: TimeInterval) {}
}

class BaseBackgroundViewController: UIViewController, Scrollable {
    func areaOfViewable(height: CGFloat) {}
    func setAnimation(height: CGFloat, duration: TimeInterval) {}
}
