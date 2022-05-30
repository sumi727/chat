//  ChatRoom.swift
//  controll
//
//  Created by 角友汰 on 2022/03/09.
//

import Foundation
import Firebase

class ChatRoom {
    let latestMassageId: String
    let members: [String]
    let createdAt: Timestamp

    var latestMessage: Message?
    var documentID: String? 
    var partnerUser: User?

    init(dic: [String: Any]) {
        self.latestMassageId = dic["latestMessageId"] as? String ?? ""
        self.members = dic["members"] as? [String] ?? [String]()
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()

    }
}
