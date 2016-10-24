//
//  HttpServerConnection.swift
//  Vashen
//
//  Created by Alan on 8/3/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation

public class HttpServerConnection
{
    private static var dev = "192.168.0.9"
    private static var prod = "imanio.zone"
    
    public static func buildURL(location: String) -> String {
        let path = ("http://" + prod + "/Vashen/API/" + location + "/")
        return path
    }
    
    public static func sendHttpRequestPost(urlPath: String, withParams params: String) throws -> Dictionary<String,AnyObject>{
        do {
            let request = NSMutableURLRequest.init(url: NSURL.init(string: urlPath)! as URL)
            request.httpMethod = "POST"
            request.timeoutInterval = 5
            request.httpBody = params.data(using: String.Encoding.utf8, allowLossyConversion: true)
            
            let semaphore = DispatchSemaphore(value: 0)
            var data:Data!
            URLSession.shared.dataTask(with: request as URLRequest) { (responseData, _, _) -> Void in
                data = responseData
                semaphore.signal()
                }.resume()
            
            _ = semaphore.wait(timeout: .distantFuture)
            print(String(data: data, encoding: String.Encoding.utf8))
            let dataString = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
            return dataString as! Dictionary<String, AnyObject>
        } catch (let e) {
            print(e)
            throw HttpError.connectionException
        }
    }
    
    enum  HttpError: Error {
        case connectionException
    }
}
