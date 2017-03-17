//
//  ViewController.swift
//  PKDFTPClient
//
//  Created by Prabin K Datta on 16/03/17.
//  Copyright © 2017 Prabin K Datta. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var m_hostField: UITextField!
    @IBOutlet weak var m_usernameField: UITextField!
    @IBOutlet weak var m_passwordField: UITextField!
    @IBOutlet weak var m_authenticationControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        self.m_hostField.text = UserDefaults.standard.string(forKey: "host")
//        self.m_usernameField.text = UserDefaults.standard.string(forKey: "username")
//        self.m_authenticationControl.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "auth")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loginSegue" {
            UserDefaults.standard.set(self.m_hostField.text, forKey: "host")
            UserDefaults.standard.set(self.m_usernameField.text, forKey: "username")
            UserDefaults.standard.set(self.m_authenticationControl.selectedSegmentIndex, forKey: "auth")
            
            let terminal: TerminalViewController = segue.destination as! TerminalViewController
            terminal.host = self.m_hostField.text
            terminal.username = self.m_usernameField.text
            if self.m_authenticationControl.selectedSegmentIndex == 0 {
                terminal.password = self.m_passwordField.text
            }else{
                terminal.password = nil
            }
        }
    }
 
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.m_hostField.resignFirstResponder()
        self.m_usernameField.resignFirstResponder()
        self.m_passwordField.resignFirstResponder()
    }

    //MARK: IBAction
    @IBAction func hostend(_ sender: Any) {
        self.m_hostField.resignFirstResponder()
    }
    
    @IBAction func usernameend(_ sender: Any) {
        self.m_usernameField.resignFirstResponder()
    }
    
    @IBAction func passwordend(_ sender: Any) {
        self.m_passwordField.resignFirstResponder()
    }
    
    @IBAction func authentication(_ sender:Any){
        self.m_passwordField.isEnabled = self.m_authenticationControl.selectedSegmentIndex == 0;
    }
    
    @IBAction func submit(_ sender: Any) {
        if self.m_hostField.text?.characters.count == 0 || self.m_usernameField.text?.characters.count == 0 || (self.m_authenticationControl.selectedSegmentIndex == 0 && self.m_passwordField.text?.characters.count == 0) {
            let alertController: UIAlertController = UIAlertController(title: "Error", message: "All fields are required!", preferredStyle: .alert)
            let cancelAction: UIAlertAction  = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        }else{
            self.performSegue(withIdentifier: "loginSegue", sender: self)
        }
    }
}

