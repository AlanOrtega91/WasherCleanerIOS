//
//  ProductsController.swift
//  VashenCleaner
//
//  Created by Alan on 8/23/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation

class ProductsController: UIViewController,UITableViewDataSource,UITableViewDelegate  {
    
    var token:String!
    var products = Array<Product>()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userIdText: UILabel!

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
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    func initThreads(){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            // do some task
            self.readProducts()
        });
    }
    
    func readProducts(){
        do {
            products = try Product.getProducts(token)!
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
                
            })
        } catch Product.Error.noSessionFound{
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("main")
            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(nextViewController, animated: true, completion: nil)
            })
        } catch {
            
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let product = self.products[indexPath.row]
        let cell = self.tableView.dequeueReusableCellWithIdentifier("productCell") as! ProductCell
        cell.amount.text = product.cantidad + "%"
        cell.brand.text = product.name
        cell.productDescription.text = product.description
        return cell
    }
    
    @IBAction func clickedClose(sender: AnyObject) {
//        let storyBoard: UIStoryboard = UIStoryboard(name: "Map", bundle:nil)
//        let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("menu") as! MenuController
//        self.presentViewController(nextViewController, animated:true, completion:nil)
        self.navigationController?.popViewControllerAnimated(true)
    }
}
