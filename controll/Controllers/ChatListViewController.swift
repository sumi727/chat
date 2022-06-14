//
//  ChatListViewController.swift
//  controll
//
//  Created by 角友汰 on 2021/09/29.
//

import UIKit
import Firebase
import FirebaseFirestore
import Nuke
import SideMenu

protocol ChatListViewDeligate:AnyObject{
    func handleAddedDocumentChange(documentChange: DocumentChange )
}

class ChatListViewController: UIViewController{
    private let cellId = "cellId"
    private var chatrooms = [ChatRoom]()
    private var chatRoomListener: ListenerRegistration?


    private var user: User? {
        didSet{
            navigationItem.title = user?.username
        }
    }
    // Define the menu
//    let menu = SideMenuNavigationController(rootViewController: ChatListViewController)
    // SideMenuNavigationController is a subclass of UINavigationController, so do any additional configuration
    // of it here like setting its viewControllers. If you're using storyboards, you'll want to do something like:
    // let menu = storyboard!.instantiateViewController(withIdentifier: "RightMenu") as! SideMenuNavigationController
//    present(menu, animated: true, completion: nil)




    func fetchChatroomsInfoFromFirestore(){
        chatRoomListener?.remove()
        chatrooms.removeAll()
        ChatListTableView.reloadData()

        chatRoomListener = Firestore.firestore().collection("chatRooms").addSnapshotListener({ (snapshots, err) in
            if err != nil{
                print("だめ")
                return
            }
            snapshots?.documentChanges.forEach({ (documentChange) in
                switch documentChange.type{
                case .added:
                    self.handleAddedDocumentChange(documentChange: documentChange)
                case .modified:
                    print("nothing to do")
                case .removed:
                    print("nao")
                }
            })
        })
    }


    @IBOutlet weak var ChatListTableView: UITableView!


    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        confirmLoggedInUser()
        fetchChatroomsInfoFromFirestore()
        for item in(self.tabBarController?.tabBar.items)! {
            item.imageInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchLoginUserInfo()

    }


    

    private func handleAddedDocumentChange(documentChange: DocumentChange ){
        let dic = documentChange.document.data()
        let chatRoom = ChatRoom(dic: dic)
        chatRoom.documentID = documentChange.document.documentID

        guard let uid = Auth.auth().currentUser?.uid else { return }
        let isContain = chatRoom.members.contains(uid)

        if !isContain{ return }

        chatRoom.members.forEach { (memberUid) in
            if memberUid != uid{
                Firestore.firestore().collection("users").document(memberUid).getDocument { (userSnapshot,err) in
                    if err != nil{
                        print("ユーザー情報の取得に失敗")
                        return
                    }
                    guard let dic = userSnapshot?.data() else { return }
                    let user = User(dic: dic)
                    user.uid = documentChange.document.documentID
                    chatRoom.partnerUser = user

                    guard let chatroomId = chatRoom.documentID else { return }

                    let latestMessageId = chatRoom.latestMassageId

                    if latestMessageId == "" {
                        self.chatrooms.append(chatRoom)
                        self.ChatListTableView.reloadData()
                        return
                    }

                    Firestore.firestore().collection("chatRooms").document(chatroomId).collection("message").document(latestMessageId).getDocument { (messageSnapshot, err) in
                        if err != nil{
                            print("最新情報の取得に失敗しました。")
                            return
                        }

                        guard let dic = messageSnapshot?.data() else { return }
                        let message = Message(dic: dic)
                        chatRoom.latestMessage = message

                        self.chatrooms.append(chatRoom)
                        self.ChatListTableView.reloadData()

                    }
                }
            }
        }
    }

    private func setupView(){
        ChatListTableView.tableFooterView = UIView()
        ChatListTableView.delegate = self
        ChatListTableView.dataSource = self
        navigationController?.navigationBar.barTintColor = UIColor{_ in return #colorLiteral(red: 0.6642242074, green: 0.6642400622, blue: 0.6642315388, alpha: 0.7019962538)}
        navigationItem.title = "Message"
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor{_ in return #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)}]
    }

    private func confirmLoggedInUser(){
        if Auth.auth().currentUser?.uid == nil{
            let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
            let signUpViewController = storyboard.instantiateViewController(withIdentifier: "SignUpViewController") as! SignUpViewController
            let nav = UINavigationController(rootViewController: signUpViewController)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        }
    }

    private func fetchLoginUserInfo(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, err) in
            if  err != nil{
                print("ユーザー情報の取得に失敗しました")
                return
            }
            guard let snapshot = snapshot ,let dic = snapshot.data() else { return }
            let user = User(dic: dic)
            self.user = user
        }

    }

}
extension ChatListViewController: UITableViewDelegate,UITableViewDataSource{

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatrooms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ChatListTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatListTableViewCell
        cell.chatroom = chatrooms[indexPath.row]
        cell.layer.cornerRadius = 40
        cell.layer.borderColor = CGColor(red: 159, green: 158, blue: 158, alpha: 0)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
        let ChatRoomViewController = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as! ChatRoomViewController
        ChatRoomViewController.user = user
        navigationController?.pushViewController(ChatRoomViewController, animated: true)
        ChatRoomViewController.chatroom = chatrooms[indexPath.row]
    }

}



class ChatListTableViewCell: UITableViewCell{

    var chatroom: ChatRoom? {
        didSet{
            if let chatroom = chatroom {
                partnerLabel.text = chatroom.partnerUser?.username
                guard let url = URL(string: chatroom.partnerUser?.profileImageUrl ?? "") else { return }
                Nuke.loadImage(with: url, into: userimageView)
                dateLabel.text = dataFormatterForDateLabel(date: chatroom.latestMessage?.createdAt.dateValue() ?? Date())
                latestMessageLabel.text = chatroom.latestMessage?.message

            }
        }
    }

    @IBOutlet weak var userimageView: UIImageView!
    @IBOutlet weak var partnerLabel: UILabel!
    @IBOutlet weak var latestMessageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!


    override  func awakeFromNib() {
        super.awakeFromNib()
        userimageView.layer.cornerRadius = 25
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    private func dataFormatterForDateLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMdd")
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
