//
//  ContextTableViewCell.swift
//  ADEduKit
//
//  Created by Schwarze on 02.01.22.
//

import UIKit

class ContextTableViewCell: UITableViewCell {
    @IBOutlet weak var titleTabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var extraLabel: UILabel!
    
    static let folderImage = UIImage(named: "folder.circle", in: Bundle(for: ContextTableViewCell.self), compatibleWith: nil)
    static let checkmarkImage = UIImage(named: "checkmark.circle.fill", in: Bundle(for: ContextTableViewCell.self), compatibleWith: nil)

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func updateFor(node: ModelNode?) {
        if let m = node {
            titleTabel.text = m.localizedTitle()
            detailLabel.text = m.type()
            if m.type() == "task" {
                statusImageView.image = Self.checkmarkImage
            } else {
                statusImageView.image = Self.folderImage
            }
            extraLabel.text = m.identifier()
        } else {
            titleTabel.text = ""
            detailLabel.text = ""
            extraLabel.text = ""
            statusImageView.image = nil
        }
    }
}
