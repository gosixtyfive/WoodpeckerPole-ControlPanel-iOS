//
//  DiscoveredPeripheralTableViewCell.swift
//  PoleControlPanel
//
//  Created by Steven Knodl on 4/9/17.
//  Copyright © 2017 Steve Knodl. All rights reserved.
//

import UIKit

struct PeripheralCellData {
    let identifer: String
    let name: String?
    let rssi: String?
}

class DiscoveredPeripheralTableViewCell: UITableViewCell {

    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        identifierLabel.font = UIFont.boldSystemFontWithMonospacedNumbers(size: 12.0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureCell(withData data: PeripheralCellData) {
        identifierLabel.text = data.identifer
        nameLabel.text = data.name
        rssiLabel.text = data.rssi
    }
    
}
