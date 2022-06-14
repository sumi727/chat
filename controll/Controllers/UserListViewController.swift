//
//  UserListViewController.swift
//  controll
//
//  Created by 角友汰 on 2022/01/30.
//

import UIKit
import FirebaseFirestore
import Nuke
import FirebaseAuth

class UserListViewController: UIViewController {

    private let cellId = "cellId"
    private var users = [User]()
    private var selectedUser: User?
    private var chatrooms = [ChatRoom]()
    private var user: User?

    @IBOutlet weak var userListTableView: UITableView!

    override func viewDidLoad(){
        super.viewDidLoad()
        confirmLoggedInUser()
        fetchLoginUserInfo()
        userListTableView.delegate = self
        userListTableView.dataSource = self
        for item in(self.tabBarController?.tabBar.items)! {
            item.imageInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserInfoFromFirestore()
        
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

    private func tappedCell(){

        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let partnerUid = self.selectedUser?.uid else { return }

        var A = 0

        let members = [uid, partnerUid]
        let docData = [
            "members": members,
            "latestMessageId": "",
            "createdAt": Timestamp()
        ] as [String : Any]

        Firestore.firestore().collection("chatRooms").getDocuments{(snapshots, err) in
            if err != nil{
                print("err")
                return
            }

            snapshots?.documents.forEach({ (snapshot) in

                let dic = snapshot.data()
//                let chatroom = ChatRoom.init(dic: dic)
//                chatroom.partnerUser = self.selectedUser
//                chatroom.documentID = snapshot.documentID

                let chatroomMember: [String] = (dic["members"] as? [String])!
                let newMembers = members.sorted()
                let newChatroomMember = chatroomMember.sorted()
                if newMembers == newChatroomMember{
                    A += 1
//                    self.chatrooms.append(chatroom)
                }


            })
            if A == 0{
                Firestore.firestore().collection("chatRooms").addDocument(data: docData) { (err) in
                    if err != nil{
                        return
                    }
                }
            }
        }
        
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

    private func fetchUserInfoFromFirestore(){
        users.removeAll()
        userListTableView.reloadData()


        Firestore.firestore().collection("users").getDocuments { snapshot, err in
            if err != nil{
                print("firestoreErr")
                return
            }
            snapshot?.documents.forEach({ snapshot in
                let dic = snapshot.data()
                let user = User.init(dic: dic)
                user.uid = snapshot.documentID
                guard let uid = Auth.auth().currentUser?.uid else { return }

                

                Firestore.firestore().collection("users").document(user.uid ?? "").collection("friend").getDocuments { snapshot, err in
                    if err != nil {
                        print("firestoreErr")
                        return
                    }
                    snapshot?.documents.forEach({ snapshot in
                        let dic = snapshot.data()
                        let friend = Friend.init(dic: dic)
                        friend.friendId = snapshot.documentID
                        if uid != friend.sent{
                            return
                        }

                        Firestore.firestore().collection("users").getDocuments { snapshot, err in
                            if err != nil{
                                print("err")
                                return
                            }
                            snapshot?.documents.forEach({ snapshot in
                                let dic = snapshot.data()
                                let user = User.init(dic: dic)
                                user.uid = snapshot.documentID
                                if friend.receive == user.uid{
                                    self.users.append(user)
                                    self.userListTableView.reloadData()
                                }
                            })
                        }

                    })

                }
            })
        }


//
//        Firestore.firestore().collection("users").getDocuments { (snapshots, err) in
//            if err != nil{
//                print("user情報の取得に失敗した。")
//                return
//            }
//            snapshots?.documents.forEach({ (snapshot) in
//                let dic = snapshot.data()
//                let user = User.init(dic: dic)
//                user.uid = snapshot.documentID
//                guard let uid = Auth.auth().currentUser?.uid else { return }
//                if uid == snapshot.documentID {
//                    return
//                }
//                self.users.append(user)
//                self.userListTableView.reloadData()
//            })
//        }
    }
}

extension UserListViewController: UITableViewDelegate, UITableViewDataSource{

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = userListTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserListTableViewCell
        cell.user = users[indexPath.row]
        cell.layer.cornerRadius = 40
        cell.layer.masksToBounds = true

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        self.selectedUser = user
        tappedCell()


//        let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
//        let ChatRoomViewController = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as! ChatRoomViewController
//        ChatRoomViewController.user = user
//        ChatRoomViewController.chatroom = chatrooms[indexPath.row]
//        navigationController?.pushViewController(ChatRoomViewController, animated: true)

        }
}

class UserListTableViewCell: UITableViewCell {
    
    
    var user: User? {
        didSet{
            userLabel.text = user?.username
            if let url = URL(string: user!.profileImageUrl){
                Nuke.loadImage(with: url, into: userimage)
            }
        }
    }

    @IBOutlet weak var userimage: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        userimage.layer.cornerRadius = 25
    }
}
