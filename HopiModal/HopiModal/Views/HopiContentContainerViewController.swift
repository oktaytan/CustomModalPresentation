//  HopiContentContainerViewController.swift
//  HopiModal
//
//  Created by namik kaya on 24.07.2022.
//

import UIKit

protocol HopiContentContainerViewControllerDelegate: AnyObject {
    func activityEventListener(event: HopiModalInPageEventType)
}

extension HopiContentContainerViewControllerDelegate {
    func activityEventListener(event: HopiModalInPageEventType) {}
}

enum HopiContentSizeType {
    case fullSize, minumumSize, openingHeight, fullSizeContent
}

enum HopiModalInPageEventType {
    case close, didChangeInModalPos(y: CGFloat)
}

protocol HopiControllerSlidable {
    func setupContent(contentContainer: UIViewController, galleryContainer: BaseBackgroundViewController)
}

final class HopiContentContainerViewController: UIViewController, HopiControllerSlidable {
    enum ScrollDirection {
        case up, down
    }
    
    weak var delegate: HopiContentContainerViewControllerDelegate?
    
    private var panGesture = UIPanGestureRecognizer()
    // content olarak yüklenen view hareketi için bu view özelinde tutulur.
    private var contentVCHolder: UIViewController?
    private var galleryVCHolder: BaseBackgroundViewController?
    
    private weak var dragView: UIView?
    private var beginningPosition: CGPoint = .zero
    
    private var timer: Timer?
    
    
    private weak var childScrollView: UIScrollView?
    /// If true you can pull using UIControls (so you can grab and drag a button to control the sheet)
    public var shouldRecognizePanGestureWithUIControls: Bool = true
    
    private var scrollDirection:ScrollDirection = .up
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .blue
    }
    
    @IBAction func closeButtonEvent(_ sender: Any) {
        delegate?.activityEventListener(event: .close)
    }
    
    deinit {
        print("XYZ: HopiContentContainerViewController => Deinit")
    }
}

// MARK: - sheet common logic
extension HopiContentContainerViewController {
    func setupContent(contentContainer: UIViewController, galleryContainer: BaseBackgroundViewController) {
        setupGalleryContainer(galleryContainer)
        setupContentContainer(contentContainer)
        
        if let content = contentContainer as? ProductDetailVC {
            handleScrollView(content.tableView)
        }
    }
}

// MARK: - Dragable Contanier
extension HopiContentContainerViewController {
    private func setupContentContainer(_ targetController: UIViewController) {
        contentVCHolder = targetController
        var newBounds = self.view.bounds
        newBounds.origin.y = self.view.frame.size.height
        newBounds.size.height -= 120
        
        targetController.view.frame = newBounds
        view.addSubview(targetController.view)
        targetController.didMove(toParent: self)
        
        targetController.view.layer.masksToBounds = true
        targetController.view.clipsToBounds = true
        
        targetController.view.layer.cornerRadius = 10
        targetController.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        dragView = targetController.view
        
        firstOpenAnimation(dragView)
        panGestureSetup()
    }
    
    private func panGestureSetup() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.draggedView(_:)))
        panGesture.delegate = self
        dragView?.addGestureRecognizer(panGesture)
    }
    
    private func firstOpenAnimation(_ contentView: UIView? ) {
        guard let contentView = contentView else {
            return
        }
        contentView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            contentView.frame.origin.y = 120
            contentView.alpha = 1
        }
    }
    
    func handleScrollView(_ scrollView: UIScrollView) {
        scrollView.panGestureRecognizer.require(toFail: panGesture)
        self.childScrollView = scrollView
    }
     
}

extension HopiContentContainerViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Allowing gesture recognition on a UIControl seems to prevent its events from firing properly sometimes
        if !shouldRecognizePanGestureWithUIControls {
            if let view = touch.view {
                return !(view is UIControl)
            }
        }
        return true
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        print("XYZ scroll Direction: \(scrollDirection)")
        if (self.childScrollView?.contentOffset.y ?? 0) <= 0 {
            return true
        }else {
            return false
        }
    }
}

extension HopiContentContainerViewController {
    @objc private func draggedView(_ gestureRecognizer: UIGestureRecognizer) {
        if let touchedView = gestureRecognizer.view {
            if gestureRecognizer.state == .began {
                beginningPosition = gestureRecognizer.location(in: touchedView)
            } else if gestureRecognizer.state == .changed {
                let locationInView = gestureRecognizer.location(in: touchedView)
                let yPos = touchedView.frame.origin.y + locationInView.y - beginningPosition.y
                if 120 <= yPos {
                    touchedView.frame.origin = CGPoint(x: 0, y: yPos)
                    if self.view.frame.size.height - yPos > 280 {
                        touchedView.frame.size.height = self.view.frame.size.height - yPos
                    }
                    print("XYZ: \(self.className) height: \(self.view.frame.size.height - yPos)")
                    galleryVCHolder?.areaOfViewable(height: yPos)
                    touchedView.layoutIfNeeded()
                }else {
                    touchedView.frame.origin = CGPoint(x: 0, y: 120)
                    touchedView.frame.size.height = self.view.frame.size.height - 120
                    touchedView.layoutIfNeeded()
                }
                
                if self.view.frame.size.height - 120 < touchedView.frame.origin.y {
                    let firstPos = self.view.frame.size.height - 120
                    let diff = firstPos - touchedView.frame.origin.y
                    let alphaRatio = firstPos / diff
                    //touchedView.alpha = alphaRatio
                    print("XYZ: Position: \(firstPos) : \(touchedView.frame.origin.y)")
                    //print("XYZ alpha: \(alphaRatio)")
                }
                print("XYZ: Position: final => beginningPosition: \(self.beginningPosition.y) : \(gestureRecognizer.location(in: touchedView).y)")
                scrollDirection = yPos < 0 ? .up : .down
                delegate?.activityEventListener(event: .didChangeInModalPos(y: yPos))
            } else if gestureRecognizer.state == .ended { // alanların check işleri bir döngü ile yapılacak
                print("XYZ touchEnded")
                if self.view.frame.size.height - touchedView.frame.origin.y <= 120 {
                    galleryVCHolder?.setAnimation(height: self.view.frame.size.height, duration: 0.3)
                    UIView.animate(withDuration: 0.3) {
                        touchedView.frame.origin.y = self.view.frame.size.height
                        touchedView.frame.size.height = self.view.frame.size.height - touchedView.frame.origin.y
                        touchedView.alpha = 0
                        self.delegate?.activityEventListener(event: .didChangeInModalPos(y: touchedView.frame.origin.y))
                    } completion: { act in
                        self.delegate?.activityEventListener(event: .didChangeInModalPos(y: touchedView.frame.origin.y))
                    }
                    
                }else {
                    galleryVCHolder?.setAnimation(height: 120, duration: 0.3)
                    UIView.animate(withDuration: 0.3) {
                        touchedView.frame.origin.y = 120
                        touchedView.frame.size.height = self.view.frame.size.height - touchedView.frame.origin.y
                        touchedView.alpha = 1
                        touchedView.layoutIfNeeded()
                        self.delegate?.activityEventListener(event: .didChangeInModalPos(y: touchedView.frame.origin.y))
                    } completion: { act in
                        self.delegate?.activityEventListener(event: .didChangeInModalPos(y: touchedView.frame.origin.y))
                    }

                }
            }
        }
    }
}

// MARK: - Gallery Container
extension HopiContentContainerViewController {
    private func setupGalleryContainer(_ galleryContainer: BaseBackgroundViewController) {
        galleryVCHolder = galleryContainer
        
        let newBounds = self.view.bounds
        //newBounds.size.height = 120
        galleryContainer.view.frame = newBounds
        view.addSubview(galleryContainer.view)
        galleryContainer.didMove(toParent: self)
        
        galleryContainer.view.layer.masksToBounds = true
        galleryContainer.view.clipsToBounds = true
    }
}
