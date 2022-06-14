//
//  NavigationController.swift
//  controll
//
//  Created by 角友汰 on 2022/06/08.
//

import UIKit

class NavigationController: UINavigationController, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        // Do any additional setup after loading the view.
    }
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool){
        self.navigationBar.frame = CGRect.init(x: 0, y: 0, width: self.navigationBar.frame.width, height: 20)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
