/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse

class SignUpLoginViewController: UIViewController {

    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var signUpLoginButton: UIButton!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var modeSwitchButton: UIButton!
    var isRider = true
    var signUpMode = true
    
    // switch between rider and driver
    @IBAction func switchRiderDriver(_ sender: Any) {
        isRider = !isRider
    }
    
    // sign up or login
    @IBAction func signUpLogin(_ sender: Any) {
        if usernameTextField.text == "" || passwordTextField.text == "" {
            // check if username or password is empty
            createAlert(message: "Username or password can not be empty.")
        } else {
            let username = usernameTextField.text
            let password = passwordTextField.text
            
            if signUpMode {
                // sign up
                let newUser = PFUser()
                newUser.username = username
                newUser.password = password
                newUser.signUpInBackground(block: { (success, error) in
                    if error != nil {
                        self.createAlert(message: (error?.localizedDescription)!)
                    } else {
                        self.signUpLoginSegue()
                    }
                })
            } else {
                //login
                PFUser.logInWithUsername(inBackground: username!, password: password!, block: { (user, error) in
                    if error != nil {
                        self.createAlert(message: (error?.localizedDescription)!)
                    } else {
                        self.signUpLoginSegue()
                    }
                })
            }
        }
    }
    
    // switch between sign up mode and login mode
    @IBAction func modeSwitch(_ sender: Any) {
        if signUpMode {
            signUpLoginButton.setTitle("Login", for: [])
            modeSwitchButton.setTitle("Sign Up", for: [])
            messageLabel.text = "Don't have an account?"
        } else {
            signUpLoginButton.setTitle("Sign Up", for: [])
            modeSwitchButton.setTitle("Login", for: [])
            messageLabel.text = "Already have an account?"
        }
        signUpMode = !signUpMode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // check if the user has already login
        if PFUser.current() != nil {
            signUpLoginSegue()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // create alert if error occurs
    func createAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // go to driver or rider screen after login or sign up
    func signUpLoginSegue() {
        if isRider {
            DispatchQueue.main.async(){
                self.performSegue(withIdentifier: "toRiderView", sender: self)
            }
        } else {
            DispatchQueue.main.async(){
                self.performSegue(withIdentifier: "toRequestsList", sender: self)
            }
        }
    }
}
