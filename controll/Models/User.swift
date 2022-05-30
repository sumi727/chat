//
//  User.swift
//  controll
//
//  Created by 角友汰 on 2021/12/27.
//

import Foundation
import Firebase
import FirebaseStorage

class User {
    let username: String
    let profileImageUrl: String
    let createdAt: Timestamp
    let email: String
    var uid: String?


    init(dic: [String: Any]) {
        self.username = dic["username"] as? String ?? ""
        self.profileImageUrl = dic["profileImageUrl"] as? String ?? ""
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
        self.email = dic["email"] as? String ?? ""
        
    }

}


