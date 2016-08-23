//
//  Product.swift
//  VashenCleaner
//
//  Created by Alan on 8/20/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation

public class Product {
    public static let HTTP_LOCATION = "Cleaner/Product/"
    var id:String!
    var cantidad:String!
    var name:String!
    var description:String!
    
    public static func getProducts(token:String) throws -> Array<Product>?{
        let url = HttpServerConnection.buildURL(HTTP_LOCATION + "ReadProducts")
        let params = "token=\(token)"
        var products = Array<Product>()
        do{
            var response = try HttpServerConnection.sendHttpRequestPost(url, withParams: params)
            if response["Status"] as! String == "SESSION ERROR" {
                throw Error.noSessionFound
            }
            if response["Status"] as! String != "OK" {
                throw Error.errorGettingProducts
            }
            if let json = response["Products"] as? Array<NSDictionary> {
                for productJson in json {
                    let product = Product()
                    product.id = productJson["idProducto"] as! String
                    product.cantidad = productJson["Cantidad"] as! String
                    product.name = productJson["Producto"] as! String
                    product.description = productJson["Descripcion"] as! String
                    products.append(product)
                }
            }
            
            return products
        } catch (let e) {
            print(e)
            throw Error.errorGettingProducts
        }
    }
    
    public enum Error: ErrorType{
        case noSessionFound
        case errorGettingProducts
    }
}