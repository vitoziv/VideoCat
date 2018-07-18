//
//  EditItem.swift
//  VideoCat
//
//  Created by Vito on 2018/7/11.
//  Copyright © 2018 Vito. All rights reserved.
//

import UIKit

class EditItem {
    var editInfo: EditInfo
    var editAction: () -> Void
    init(info: EditInfo, action: @escaping () -> Void) {
        self.editInfo = info
        self.editAction = action
    }
}

class EditInfo {
    var title: String = ""
    var thumb: UIImage?
    var cellIdentifier: String = ""
}
