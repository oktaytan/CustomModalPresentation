//
//  ViewController.swift
//  HopiModal
//
//  Created by namik kaya on 22.07.2022.
//

import UIKit

class ViewController: UIViewController {
    
    // kullanılacağı class için de referans bırakılmalı aksi durumda arc temizler
    var bottomSheetControl: HopiModulateable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        openProductDetail()
    }
    
    private func openProductDetail() {
        let productContainer = ProductDetailVC(nibName: "ProductDetailVC", bundle: nil)
        let galleyrContainer = GalleryVC(nibName: "GalleryVC", bundle: nil)
        bottomSheetControl = HopiModalInPage(delegate: self)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.bottomSheetControl?.createPage(content: productContainer, gallery: galleyrContainer, target: self)
        }
    }
    
    deinit {
        print("XYZ ViewController deinit")
    }
}

extension ViewController: HopiModalInPageDelegate {
    func hopiModalInPageActivity(event: HopiInPageModalStateType) {
        switch event {
        case .didPresent:
            print("XYZ: Page did present")
        case .didDismiss:
            bottomSheetControl = nil
        }
    }
}

