//
//  SideMenuViewController.swift
//  controll
//
//  Created by 角友汰 on 2022/03/23.
//

import Foundation
import UIKit
import Firebase
import Nuke

protocol ResetDataDelegate: AnyObject{
    func chatListResetData()
    func userResetData()
}

class SideMenuViewController: UIViewController {
    weak var delegate: ResetDataDelegate?

    private var users = [User]()
    
    @IBOutlet weak var myProfileImageView: UIImageView!
    @IBOutlet weak var logoutButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        myProfileImageView.layer.cornerRadius = 25
        imagetoru()

    }
    private func imagetoru(){
        Firestore.firestore().collection("users").getDocuments { (snapshots, err) in
            if err != nil{
                return
            }
            snapshots?.documents.forEach({ snapshot in
                let dic = snapshot.data()
                let user = User.init(dic: dic)
                user.uid = snapshot.documentID
                guard let uid = Auth.auth().currentUser?.uid else { return }
                if uid == snapshot.documentID {
                    let url = URL(string: user.profileImageUrl)
                    Nuke.loadImage(with: url, into: self.myProfileImageView)
                    return
                }
            })
        }
    }

    @IBAction func tappedLogoutButton(_ sender: UIButton) {
        do{
            delegate?.chatListResetData()
            delegate?.userResetData()
            try Auth.auth().signOut()
            let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
            let SignUpViewController  = storyboard.instantiateViewController(withIdentifier: "SignUpViewController")
            let nav = UINavigationController(rootViewController: SignUpViewController)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        } catch {
            print("logout失敗")
            return
        }

    }

}
