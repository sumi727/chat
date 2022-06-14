//
//  ChatRoomViewController.swift
//  controll
//
//  Created by 角友汰 on 2021/10/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class ChatRoomViewController: UIViewController{

    var chatroom: ChatRoom?
    var user: User?


    private let cellId = "cellId"
    private let accessoryHeight: CGFloat = 100
    private let tableViewContentInset: UIEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
    private let tableViewIndicatorInset: UIEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
    private var messages = [Message]()



    private lazy var chatInputAccessoryView: ChatInputAccessoryView = {
        let view = ChatInputAccessoryView()
        view.frame = .init(x: 0, y: 0, width: view.frame.width, height: accessoryHeight)
        view.delegate = self
        return view
    }()


    @IBOutlet weak var ChatRoomTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNotification()
        setupChatRoomTableView()
        fetchMessage()
    }

    private func setupNotification(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification){


        guard let userInfo = notification.userInfo else { return }

        if let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue {

            if keyboardFrame.height <= accessoryHeight { return }
            print("keyboardFrame: ", keyboardFrame)

            let top = keyboardFrame.height - 70
            let moveY = -(top - ChatRoomTableView.contentOffset.y)
            let contentInset = UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)

            ChatRoomTableView.contentInset = contentInset
            ChatRoomTableView.scrollIndicatorInsets = contentInset
            ChatRoomTableView.contentOffset = CGPoint(x: 0, y: moveY)

        }
    }
    @objc func keyboardWillHide(){
        print("keyboardWillHide")
        ChatRoomTableView.contentInset = tableViewContentInset
        ChatRoomTableView.scrollIndicatorInsets = tableViewIndicatorInset

    }

    private func setupChatRoomTableView(){
        ChatRoomTableView.delegate = self
        ChatRoomTableView.dataSource = self
        ChatRoomTableView.register(UINib(nibName: "ChatRoomTableViewCell", bundle: nil), forCellReuseIdentifier: cellId)
        ChatRoomTableView.backgroundColor = UIColor{_ in return #colorLiteral(red: 0.9568627451, green: 0.9490196078, blue: 0.9411764706, alpha: 1)}
        ChatRoomTableView.contentInset = .init(top: 0, left: 0, bottom: 0, right: 0)
        ChatRoomTableView.scrollIndicatorInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
        ChatRoomTableView.keyboardDismissMode = .interactive
        ChatRoomTableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
    }


    override var inputAccessoryView: UIView? {
        get{
            return chatInputAccessoryView
        }
    }
    override var canBecomeFirstResponder: Bool {
        return true
    }
    private func fetchMessage(){
        guard let chatroomDocId = chatroom?.documentID else { return }

        Firestore.firestore().collection("chatRooms").document(chatroomDocId).collection("message").addSnapshotListener { snapshots, error in
            guard let snapshot = snapshots else {
                print("error")
                return
            }

            snapshot.documentChanges.forEach({ documentChange in
                if (documentChange.type == .added){

                    let dic = documentChange.document.data()
                    let message = Message(dic: dic)

                    message.partnerUser = self.chatroom?.partnerUser
                    self.messages.append(message)
                    self.messages.sort { m1, m2 in
                        let m1Date = m1.createdAt.dateValue()
                        let m2Date = m2.createdAt.dateValue()
                        return m1Date > m2Date
                    }

                    self.ChatRoomTableView.reloadData()
//                    self.ChatRoomTableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: true)
                }
            })
        }
    }
}

extension ChatRoomViewController: ChatInputAccessoryViewdelegate{
    func tappedSendButtun(text: String) {
        addMessageToFirestore(text: text)
    }
    private func addMessageToFirestore(text: String){
        guard let chatroomDocId = chatroom?.documentID else { return }
        guard let name = user?.username else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }

        chatInputAccessoryView.removeText()

        let messageID = randomString(length: 20)
        let docData = [
            "name": name,
            "createdAt": Timestamp(),
            "uid": uid,
            "message": text
        ] as [String : Any]

        Firestore.firestore().collection("chatRooms").document(chatroomDocId).collection("message").document(messageID).setData(docData) { (err) in
            if err != nil{
                print("message情報の保存に失敗しました。")
                return
            }

            let latestMessageData = [
                "latestMessageId": messageID
            ]

            Firestore.firestore().collection("chatRooms").document(chatroomDocId)
                .updateData(latestMessageData) { err in
                    if err != nil{
                        print("最新メッセージの保存に失敗しました。")
                        return
                    }
                    print("最新メッセージの保存に成功しました。")
                }
        }
    }
    func randomString(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)

        var randomString = ""
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
}


extension ChatRoomViewController: UITableViewDelegate, UITableViewDataSource{

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        ChatRoomTableView.estimatedRowHeight = 20
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ChatRoomTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatRoomTableViewCell
        cell.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        cell.message = messages[indexPath.row]
        
        return cell
    }


}
