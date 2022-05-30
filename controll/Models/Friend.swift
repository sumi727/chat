//
//  Friend.swift
//  controll
//
//  Created by 角友汰 on 2022/05/25.
//

import Foundation
import Firebase

class Friend {
    let receive :String
    let sent:String

    var friendId:String?
    
    init(dic: [String: Any]){
        self.receive = dic["receive"] as? String ?? ""
        self.sent = dic["sent"] as? String ?? ""
    }
}
