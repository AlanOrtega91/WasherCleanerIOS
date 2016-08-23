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
            let request = NSMutableURLRequest.init(URL: NSURL.init(string: urlPath)!)
            request.HTTPMethod = "POST"
            request.timeoutInterval = 10
            request.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
            var response : NSURLResponse?
        
            let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
            let dataString = try NSJSONSerialization.JSONObjectWithData(data, options: [])
            return dataString as! Dictionary<String, AnyObject>
        } catch (let e) {
            print(e)
            throw HttpServerConnectionError.connectionException
        }
    }
    enum  HttpServerConnectionError: ErrorType {
        case connectionException
    }
}