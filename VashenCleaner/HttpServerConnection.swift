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
    
    public static func buildURL(location: String) -> String {
        return ("http://54.218.50.2/api/1.0.0/interfaz/" + location + "/")
    }
    
    public static func sendHttpRequestPost(urlPath: String, withParams params: String) throws -> Dictionary<String,AnyObject>{
        do {
            let request = NSMutableURLRequest.init(url: URL.init(string: urlPath)!)
            request.httpMethod = "POST"
            request.timeoutInterval = 10
            request.httpBody = params.data(using: String.Encoding.utf8, allowLossyConversion: true)
            
            let semaphore = DispatchSemaphore(value: 0)
            var data:Data!
            URLSession.shared.dataTask(with: request as URLRequest) { (responseData, _, _) -> Void in
                data = responseData
                semaphore.signal()
                }.resume()
            _ = semaphore.wait(timeout: .distantFuture)
            if data != nil {
                let dataString = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                return dataString as! Dictionary<String, AnyObject>
            } else {
                throw HttpError.connectionException
            }
        } catch {
            throw HttpError.connectionException
        }
    }
    
    enum  HttpError: Error {
        case connectionException
    }
}
