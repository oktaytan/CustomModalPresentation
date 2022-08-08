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

//enum HopiContentSizeType {
//    case fullSize, minumumSize, openingHeight, fullSizeContent
//}

enum HopiContentSizeType {
    case fixed(CGFloat), percent(Float), fullscreen
}

enum HopiModalInPageEventType {
    case close, didChangeInModalPos(y: CGFloat)
}

protocol HopiControllerSlidable {
    func setupContent(contentContainer: UIViewController, galleryContainer: BaseBackgroundViewController, sizes: [HopiContentSizeType])
}

final class HopiContentContainerViewController: UIViewController, HopiControllerSlidable {
    enum ScrollDirection {
        case up, down
    }
    
    weak var delegate: HopiContentContainerViewControllerDelegate?
    
    @IBOutlet weak var closeButton: UIButton!
    private var panGesture = UIPanGestureRecognizer()
    // content olarak yüklenen view hareketi için bu view özelinde tutulur.
    private var contentVCHolder: UIViewController?
    private var galleryVCHolder: BaseBackgroundViewController?
    private var galleryCellHeight: CGFloat = .zero
    private var negativeSpace: CGFloat = 120
    
    private weak var dragView: UIView?
    private var beginningPosition: CGPoint = .zero
    
    private var timer: Timer?
    
    public var orderedSizes: [HopiContentSizeType] = []
    public var sizes: [HopiContentSizeType] = [.percent(0.5)] {
        didSet {
            self.updateOrderedSizes()
        }
    }
    
    private weak var childScrollView: UIScrollView?
    /// If true you can pull using UIControls (so you can grab and drag a button to control the sheet)
    public var shouldRecognizePanGestureWithUIControls: Bool = true
    public var shouldRecognizeTapGestureForGallery: Bool = true
    
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
    func setupContent(contentContainer: UIViewController, galleryContainer: BaseBackgroundViewController, sizes: [HopiContentSizeType]) {
        self.sizes = sizes
        self.closeButton.layer.zPosition = 10
        setupGalleryContainer(galleryContainer)
        setupContentContainer(contentContainer)
        
        if let content = contentContainer as? ProductDetailVC {
            handleScrollView(content.tableView)
        }
    }
    
    private func updateOrderedSizes() {
        var concreteSizes: [(HopiContentSizeType, CGFloat)] = self.sizes.map {
            return ($0, self.height(for: $0))
        }
        concreteSizes.sort { $0.1 < $1.1 }
        self.orderedSizes = concreteSizes.map({ size, _ in size })
        self.galleryCellHeight = self.view.bounds.height - self.height(for: self.orderedSizes.first) + negativeSpace
    }
        
    private func height(for size: HopiContentSizeType?) -> CGFloat {
        guard let size = size else { return 0 }
        let contentHeight: CGFloat
        let fullscreenHeight: CGFloat = self.view.bounds.height - 150
        switch (size) {
            case .fixed(let height):
                contentHeight = height
            case .fullscreen:
                contentHeight = fullscreenHeight
            case .percent(let percent):
                contentHeight = (self.view.bounds.height) * CGFloat(percent)
        }
        return min(fullscreenHeight, contentHeight)
    }
}

// MARK: - Dragable Contanier
extension HopiContentContainerViewController {
    private func setupContentContainer(_ targetController: UIViewController) {
        contentVCHolder = targetController
        
        let firstHeight = self.height(for: self.orderedSizes.first)
        var newBounds = self.view.bounds
        newBounds.origin.y = self.view.frame.size.height - firstHeight + negativeSpace
        newBounds.size.height = firstHeight 
        
        targetController.view.frame = newBounds
        targetController.view.layer.zPosition = 2
        view.addSubview(targetController.view)
        targetController.didMove(toParent: self)
        
        targetController.view.layer.masksToBounds = true
        targetController.view.clipsToBounds = true
        
        targetController.view.layer.cornerRadius = 10
        targetController.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        dragView = targetController.view
        
        firstOpenAnimation(dragView, height: firstHeight)
        panGestureSetup()
    }
    
    private func panGestureSetup() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.draggedView(_:)))
        panGesture.delegate = self
        dragView?.addGestureRecognizer(panGesture)
    }
    
    private func firstOpenAnimation(_ contentView: UIView?, height: CGFloat) {
        guard let contentView = contentView else {
            return
        }
        contentView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            contentView.frame.origin.y = self.view.frame.height - height
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
        
        let minHeight: CGFloat = self.height(for: self.orderedSizes.first)
        let maxHeight: CGFloat = self.height(for: self.orderedSizes.last)

        if let touchedView = gestureRecognizer.view {
            let locationInView = gestureRecognizer.location(in: touchedView)
            let yPos = touchedView.frame.origin.y + locationInView.y - beginningPosition.y
            let galleryHeight = (yPos >= minHeight ? self.view.frame.height - minHeight : self.view.frame.height - maxHeight) + negativeSpace
            
            if gestureRecognizer.state == .began {
                beginningPosition = gestureRecognizer.location(in: touchedView)
            } else if gestureRecognizer.state == .changed {
                if 120 <= yPos {
                    touchedView.frame.origin = CGPoint(x: 0, y: yPos)
                    if self.view.frame.size.height - yPos > 280 {
                        touchedView.frame.size.height = self.view.frame.size.height - yPos
                    }
                    print("XYZ: \(self.className) height: \(self.view.frame.size.height - yPos)")
                    galleryVCHolder?.areaOfViewable(height: yPos + negativeSpace)
                    touchedView.layoutIfNeeded()
                }else {
                    touchedView.frame.origin = CGPoint(x: 0, y: 120)
                    touchedView.frame.size.height = self.view.frame.size.height - 120
                    touchedView.layoutIfNeeded()
                }
                
                if self.view.frame.size.height - 120 < touchedView.frame.origin.y {
                    let firstPos = self.view.frame.size.height - 120
//                    let diff = firstPos - touchedView.frame.origin.y
//                    let alphaRatio = firstPos / diff
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
                    galleryVCHolder?.setAnimation(height: galleryHeight, duration: 0.3)
                    UIView.animate(withDuration: 0.3) {
                        touchedView.frame.origin.y = yPos >= minHeight ? self.view.frame.size.height - minHeight : self.view.frame.size.height - maxHeight
                        touchedView.frame.size.height = yPos >= minHeight ? minHeight : maxHeight
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
extension HopiContentContainerViewController: GalleryVCDelegate {
    private func setupGalleryContainer(_ galleryContainer: BaseBackgroundViewController) {
        galleryVCHolder = galleryContainer
        
        let newBounds = self.view.bounds
        //newBounds.size.height = 120
        galleryContainer.view.frame = newBounds
        galleryContainer.view.layer.zPosition = 1
        view.addSubview(galleryContainer.view)
        galleryContainer.didMove(toParent: self)
        
        galleryContainer.view.layer.masksToBounds = true
        galleryContainer.view.clipsToBounds = true
        
        if let gallery = galleryVCHolder as? GalleryVC {
            gallery.delegate = self
        }
        
        DispatchQueue.main.async {
            galleryContainer.areaOfViewable(height: self.galleryCellHeight)
        }
        
        if shouldRecognizeTapGestureForGallery {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(fullScreenGallery))
            galleryContainer.view.addGestureRecognizer(tapGesture)
        }
    }
    
    @objc func fullScreenGallery() {
        guard let contentVC = self.contentVCHolder else { return }
        UIView.animate(withDuration: 0.3) {
            contentVC.view.frame.origin.y = self.view.frame.size.height
            contentVC.view.frame.size.height = self.view.frame.size.height - (contentVC.view.frame.origin.y)
            contentVC.view.alpha = 0
            self.delegate?.activityEventListener(event: .didChangeInModalPos(y: contentVC.view.frame.origin.y))
        } completion: { act in
            self.delegate?.activityEventListener(event: .didChangeInModalPos(y: contentVC.view.frame.origin.y))
        }
        galleryVCHolder?.setAnimation(height: self.view.frame.size.height, duration: 0.3)
    }
    
    func closeFullsize() {
        guard let contentVC = self.contentVCHolder else { return }
        let firstHeight: CGFloat = self.height(for: self.orderedSizes.first)
        UIView.animate(withDuration: 0.3) {
            contentVC.view.frame.origin.y = self.view.frame.size.height - firstHeight
            contentVC.view.frame.size.height = firstHeight
            contentVC.view.alpha = 1
            contentVC.view.layoutIfNeeded()
            self.delegate?.activityEventListener(event: .didChangeInModalPos(y: contentVC.view.frame.origin.y))
        } completion: { act in
            self.delegate?.activityEventListener(event: .didChangeInModalPos(y: contentVC.view.frame.origin.y))
        }
        galleryVCHolder?.setAnimation(height: galleryCellHeight, duration: 0.3)
    }
}
