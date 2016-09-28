//
//  ProductsController.swift
//  VashenCleaner
//
//  Created by Alan on 8/23/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation

class ProductsController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate  {
    
    var token:String!
    var products = Array<Product>()
    @IBOutlet weak var userIdText: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        initValues()
        initView()
        initThreads()
    }
    
    func initValues(){
        token = AppData.readToken()
    }
    
    func initView(){
        userIdText.text = "ID = " + DataBase.readUser().id
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    func initThreads(){
        DispatchQueue.global().async {
            self.readProducts()
        }
    }
    
    func readProducts(){
        do {
            products = try Product.getProducts(token: token)!
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        } catch Product.ProductError.noSessionFound{
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "main")
            DispatchQueue.main.async {
                _ = self.present(nextViewController, animated: true, completion: nil)
            }
        } catch {
            
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "product_row", for: indexPath) as! ProductCell
        let product = products[indexPath.row]
        cell.amount.text = product.cantidad + "%"
        cell.name.text = product.name
        checkForImage(cell: cell, forProduct: product)
        return cell
    }
    
    func checkForImage(cell: ProductCell, forProduct product: Product){
        var image:UIImage!
        switch product.id {
        case "1":
            image = UIImage(named: "Product01")
            cell.traditional.isHidden = true
            cell.eco.isHidden = false
            break
        case "2":
            image = UIImage(named: "Product02")
            cell.traditional.isHidden = false
            cell.eco.isHidden = true
            break
        case "3":
            image = UIImage(named: "Product03")
            cell.traditional.isHidden = false
            cell.eco.isHidden = false
            break
        case "4":
            image = UIImage(named: "Product03")
            cell.traditional.isHidden = false
            cell.eco.isHidden = false
            break
        case "5":
            image = UIImage(named: "Product03")
            cell.traditional.isHidden = false
            cell.eco.isHidden = false
            break
        case "6":
            image = UIImage(named: "Product03")
            cell.traditional.isHidden = false
            cell.eco.isHidden = false
            break
        case "7":
            image = UIImage(named: "Product04")
            cell.traditional.isHidden = false
            cell.eco.isHidden = false
            break
        default:
            break
        }
        cell.product.image = image
    }
    
    
    @IBAction func clickedClose(_ sender: AnyObject) {
        _ = self.navigationController?.popViewController(animated: true)
    }
}
