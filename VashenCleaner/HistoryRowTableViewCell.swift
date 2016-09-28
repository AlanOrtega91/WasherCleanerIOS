//
//  HistoryRowTableViewCell.swift
//  Vashen
//
//  Created by Alan on 8/10/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import UIKit

public class HistoryRowTableViewCell: UITableViewCell {
    @IBOutlet weak public var cleanerImage: UIImageView!
    @IBOutlet weak public var date: UILabel!
    @IBOutlet weak public var serviceType: UILabel!
    @IBOutlet weak public var locationImage: UIImageView!

    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
