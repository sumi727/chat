//
//  ViewController.swift
//  controll
//
//  Created by 角友汰 on 2021/09/29.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PKHUD

class SignUpViewController: UIViewController{

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var profileImageButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var alreadyHaveAccountButton: UIButton!



    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

   
    private func setUpViews(){
        profileImageButton.layer.cornerRadius = 85
        profileImageButton.layer.borderWidth = 1
        profileImageButton.layer.borderColor = .init(red: 240, green: 240, blue: 240, alpha: 0)

        registerButton.layer.cornerRadius = 12

        profileImageButton.addTarget(self, action: #selector(tappedProfileImageButton), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(tappedRegisterImageButton), for: .touchUpInside)
        alreadyHaveAccountButton.addTarget(self, action: #selector(tappedAlreadyHaveAccountButton), for: .touchUpInside)

        emailTextField.delegate = self
        passwordTextField.delegate = self
        usernameTextField.delegate = self
        registerButton.isEnabled = false
        registerButton.backgroundColor = UIColor{_ in return #colorLiteral(red: 0.9117578223, green: 0.7644432625, blue: 1, alpha: 1)}
    }

    @objc private func tappedAlreadyHaveAccountButton(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        self.navigationController?.pushViewController(loginViewController, animated: true)
    }

    @objc private func tappedProfileImageButton(){
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        self.present(imagePickerController, animated: true, completion: nil)
    }

    @objc private func tappedRegisterImageButton(){
        let image = profileImageButton.imageView?.image ?? UIImage(named: "RoSe")
        guard let uploadImage = image?.jpegData(compressionQuality: 0.3) else { return }

        HUD.show(.progress)

        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_image").child(fileName)
        storageRef.putData(uploadImage, metadata: nil){(metadata,err) in
            if err != nil {
                print("storageError")
                HUD.hide()
                return
            }
            print("storageYes")
            storageRef.downloadURL{ (url, err) in
                if err != nil {
                    print("firestorageからのダウンロードに失敗")
                    HUD.hide()
                    return
                }
                guard let urlString = url?.absoluteString else { return }
                print("urlString: ", urlString)
                self.createUsersToFirebase(profileImageUrl: urlString)
            }
        }
    }

    private func createUsersToFirebase(profileImageUrl: String){
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        Auth.auth().createUser(withEmail: email, password: password){
            (res, err) in
            if err != nil {
                HUD.hide()
                return
            }
            guard let uid = res?.user.uid else { return }
            guard let username = self.usernameTextField.text else { return }
            let docData = [
                "email": email,
                "username": username,
                "createdAt": Timestamp(),
                "profileImageUrl": profileImageUrl
            ] as [String : Any]
            Firestore.firestore().collection("users").document(uid).setData(docData){
                (err) in
                if err != nil{
                    print("error")
                    HUD.hide()
                    return
                }
                print("succes")
                HUD.hide()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension SignUpViewController: UITextFieldDelegate{
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let emailIsEmpty = emailTextField.text?.isEmpty ?? false
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? false
        let usernameIsEmpty = usernameTextField.text?.isEmpty ?? false

        if emailIsEmpty || passwordIsEmpty || usernameIsEmpty{
            registerButton.isEnabled = false
            registerButton.backgroundColor = UIColor{_ in return #colorLiteral(red: 0.9117578223, green: 0.7644432625, blue: 1, alpha: 1)}
        }else{
            registerButton.isEnabled = true
            registerButton.backgroundColor = UIColor{_ in return #colorLiteral(red: 0.7822921872, green: 0.5444465053, blue: 1, alpha: 1)}
        }
    }
}




extension SignUpViewController:UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage{
            profileImageButton.setImage(editedImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }else if let orignalImage = info[.originalImage] as? UIImage{
            profileImageButton.setImage(orignalImage.withRenderingMode(.alwaysOriginal), for: .normal)

        }
        profileImageButton.setTitle("", for: .normal)
        profileImageButton.imageView?.contentMode = .scaleAspectFill
        profileImageButton.contentVerticalAlignment = .fill
        profileImageButton.contentHorizontalAlignment = .fill
        profileImageButton.clipsToBounds = true

        dismiss(animated: true, completion: nil)
    }
}
