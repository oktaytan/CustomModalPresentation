//
//  HopiModalInPage.swift
//  HopiModal
//
//  Created by namik kaya on 22.07.2022.
//

import UIKit

protocol HopiModalInPageDelegate: AnyObject {
    func hopiModalInPageActivity(event: HopiInPageModalStateType)
}

protocol HopiModulateable {
    func createPage(content: UIViewController, gallery: BaseBackgroundViewController, target: UIViewController)
}

enum HopiInPageModalStateType {
    case didPresent, didDismiss
}

final class HopiModalInPage: HopiModulateable {
    weak var delegate: HopiModalInPageDelegate?
    weak var targetVC: UIViewController?
    
    init(delegate: HopiModalInPageDelegate?) {
        self.delegate = delegate
    }
    
    func createPage(content: UIViewController, gallery: BaseBackgroundViewController, target: UIViewController) {
        targetVC = target
        let rootVC = HopiContentContainerViewController()
        rootVC.setupContent(contentContainer: content, galleryContainer: gallery, sizes: [.fixed(411), .fullscreen])
        rootVC.modalPresentationStyle = .overFullScreen
        rootVC.delegate = self
        target.present(rootVC, animated: true) { [weak self] in
            self?.delegate?.hopiModalInPageActivity(event: .didPresent)
        }
    }
    
    deinit {
        print("XYZ: HopiModalInPage => deinit")
    }
}

extension HopiModalInPage: HopiContentContainerViewControllerDelegate {
    func activityEventListener(event: HopiModalInPageEventType) {
        switch event {
        case .close:
            DispatchQueue.main.async { [weak self] in
                self?.targetVC?.dismiss(animated: true, completion: {
                    self?.delegate?.hopiModalInPageActivity(event: .didDismiss)
                })
            }
        case .didChangeInModalPos(let y):
            print("XYZ: HopiModalInPage y pos=> \(y)")
        }
    }
}
