//
//  ProfileViewController.swift
//  controll
//
//  Created by 角友汰 on 2022/04/13.
//

import UIKit
import Firebase
import Nuke

class UserSerchViewController: UIViewController{

    private let cellId = "cellId"
    private var users = [User]()
    private var selectedUser: User?
    private var recievedUser: User?

    @IBOutlet weak var usernameForSerch: UITextField!
    @IBOutlet weak var serchButton: UIButton!
    @IBOutlet weak var userSerchTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!


    override func viewDidLoad(){
        super.viewDidLoad()

        userSerchTableView.delegate = self
        userSerchTableView.dataSource = self
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //        fetchUserInfoFromFirestore()
    }


    private func addFriends(){
        guard let sentUid = Auth.auth().currentUser?.uid else { return }
        guard let receivedUid = self.selectedUser?.uid else { return }
        let friendId = randomString(length: 20)
        print("addfriend!!!!!!!!!!!!!!!!!")
        var B = 0
        let docData = [
            "sent":sentUid,
            "receive":receivedUid
        ]

        Firestore.firestore().collection("users").document(sentUid).collection("friend").getDocuments { snapshot, err in
            if err != nil{
                print("err")
                return
            }
            snapshot?.documents.forEach({ snapshot in
                let dic = snapshot.data()
                let friend = Friend.init(dic: dic)
                if friend.receive == receivedUid{
                    B += 1
                }
            })
            if B == 0{
                Firestore.firestore().collection("users").document(sentUid).collection("friend").document(friendId).setData(docData) { err in
                    if err != nil{
                        print("friend追加時のerr")
                        return
                    }
                }
            }
        }
    }

    //    private func fetchUserInfoFromFirestore(){
    //        Firestore.firestore().collection("users").getDocuments { (snapshots, err) in
    //            if err != nil{
    //                print("user情報の取得に失敗した。")
    //                return
    //            }
    //            snapshots?.documents.forEach({ (snapshot) in
    //
    //                let dic = snapshot.data()
    //                let user = User.init(dic: dic)
    //                self.users.append(user)
    //                self.userSerchTableView.reloadData()
    //            })
    //        }
    //    }

    private func serch(){
        users.removeAll()
        userSerchTableView.reloadData()

        let usernameforSerch = usernameForSerch.text
        Firestore.firestore().collection("users").getDocuments { snapshot, err in
            if err != nil{
                print("err")
                return
            }

            snapshot?.documents.forEach({ snapshot in
                let dic = snapshot.data()
                let user = User.init(dic: dic)
                let username: String = dic["username"] as! String
                user.uid = snapshot.documentID
                guard let uid = Auth.auth().currentUser?.uid else { return }
                if uid == snapshot.documentID {
                    return
                }
                if usernameforSerch != username {
                    return
                }

                self.users.append(user)
                self.userSerchTableView.reloadData()
            })
        }
    }

    @IBAction func pushSerchButton(_ sender: Any) {
        serch()
    }
    @IBAction func pushedBackButton(_ sender: Any) {
        dismiss(animated: true)
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

extension UserSerchViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = userSerchTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! userSerchTableViewCell
        cell.user = users[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        self.selectedUser = user
        addFriends()
        dismiss(animated: true)
    }
}

class userSerchTableViewCell: UITableViewCell {
    var user: User? {
        didSet{
            userLabel.text = user?.username
            if let url = URL(string: user!.profileImageUrl){
                Nuke.loadImage(with: url, into: userImage)
            }
        }
    }
    private lazy var userLabel = self.viewWithTag(1) as! UILabel
    private lazy var userImage = self.viewWithTag(2) as! UIImageView

    override func awakeFromNib() {
        super.awakeFromNib()
        userImage.layer.cornerRadius = 25
    }
}
