//
//  ProductDetailVC.swift
//  HopiModal
//
//  Created by namik kaya on 24.07.2022.
//

import UIKit

class ProductDetailVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var panGesture = UIPanGestureRecognizer()
    
    private var isInteractive: Bool = true
    private var isEndScroll: Bool = true
    private var isBeginScroll: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("XYZ: ProductDetailVC => viewDidAppear")
    }

    deinit {
        print("XYZ: ProductDetailVC => Deinit")
    }
}

extension ProductDetailVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        cell.textLabel?.text = "HEllooooooooo \(indexPath.row)"
        return cell
    }
}
