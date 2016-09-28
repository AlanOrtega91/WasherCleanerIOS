//
//  MenuVC.swift
//  Vashen
//
//  Created by Alan on 7/31/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation

class MenuVC: UITableViewController {
    
    var TableArray = ["SERVICIOS RECIENTES","ESTATUS DE PRODUCTOS","CERRAR SESION"]
    //var ImageMenuArray = [UIImage(named: "hist_icon")!,UIImage(named: "config_icon")!]
    var user:User!
    
    override func viewDidLoad() {
        let imageView = UIImageView(frame: self.tableView.frame)
        let image = UIImage(named: "background_menu")!
        imageView.image = image
        self.tableView.backgroundView = imageView
        user = DataBase.readUser()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell") as! HeaderCell
        if user.encodedImage != nil {
            let dataDecoded = Data(base64Encoded: user.encodedImage, options: .ignoreUnknownCharacters)
            cell.userImage.image = UIImage(data: dataDecoded!)!
        }
        cell.userName.text = user.name + " " + user.lastName
        switch user.rating.rounded() {
        case 0:
            cell.rating.image = UIImage(named: "rating0")
        case 1:
            cell.rating.image = UIImage(named: "rating1")
        case 2:
            cell.rating.image = UIImage(named: "rating2")
        case 3:
            cell.rating.image = UIImage(named: "rating3")
        case 4:
            cell.rating.image = UIImage(named: "rating4")
        case 5:
            cell.rating.image = UIImage(named: "rating5")
        default:
            cell.rating.image = UIImage(named: "rating0")
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Map", bundle:nil)
        //TODO: Add navigation controller
        switch TableArray[indexPath.row] {
        case TableArray[0]:
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "history") as! HistoryController
            self.navigationController?.pushViewController(nextViewController, animated: true)
            break
        case TableArray[1]:
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "products") as! ProductsController
            self.navigationController?.pushViewController(nextViewController, animated: true)
            break
        case TableArray[2]:
            sendLogout()
            break
        default:
            return
        }
    }
    
    func sendLogout(){
        do{
            ProfileReader.delete()
            try user.sendLogout()
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "main")
            self.navigationController?.setViewControllers([nextViewController], animated: true)
            _ = self.navigationController?.popToRootViewController(animated: true)
        } catch {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "main")
            self.navigationController?.setViewControllers([nextViewController], animated: true)
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TableArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath) as! MenuCell
        cell.menuLabel.text = TableArray[indexPath.row]
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 120
    }
    
}
