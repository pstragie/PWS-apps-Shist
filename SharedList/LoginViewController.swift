//
//  LoginViewController.swift
//  SharedList
//
//  Created by Pieter Stragier on 15/11/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import UIKit
import CloudKit

class LoginViewController: UIViewController {

    // MARK: - Variables
    let login_url = "http://"
    let checksession_url = "http://"
    var login_session:String = ""
    
    // MARK: - Outlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        if(loginButton.titleLabel?.text == "Logout") {
            let preferences = UserDefaults.standard
            preferences.removeObject(forKey: "session")
            
            LoginToDo()
        } else {
            login_now(username:usernameTextField.text!, password: passwordTextField.text!)
        }
    }
    
    @IBAction func createAccountTapped(_ sender: UIButton) {
    }
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        usernameTextField.text = "pstragier@mac.com"
        passwordTextField.text = "Isabelle25?"
        
        // Check whether iCloud is available
        
        CKContainer.default().accountStatus(completionHandler: { (accountStatus, Error) in
            switch accountStatus {
            case .available:
                print("iCloud available")
                self.loginButton.isEnabled = true
            case .noAccount:
                print("No iCloud account")
                self.loginButton.isEnabled = false
            case .restricted:
                print("iCloud restricted")
                self.loginButton.isEnabled = false
            case .couldNotDetermine:
                print("Unable to determine iCloud status")
                self.loginButton.isEnabled = false
            }
        })
        
        
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "session") != nil {
            login_session = preferences.object(forKey: "session") as! String
            check_session()
        } else {
            LoginToDo()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Functions
    func login_now(username:String, password:String) {
        let post_data: NSDictionary = NSMutableDictionary()
        
        post_data.setValue(username, forKey: "username")
        post_data.setValue(password, forKey: "password")
        
        let url:URL = URL(string: login_url)!
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        var paramString = ""
        
        for (key, value) in post_data {
            paramString = paramString + (key as! String) + "=" + (value as! String) + "&"
        }
        
        request.httpBody = paramString.data(using:String.Encoding.utf8)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            guard let _:Data = data, let _:URLResponse = response, error == nil else {
                return
            }
            let json: Any?
            do {
                json = try JSONSerialization.jsonObject(with: data!, options: [])
            } catch {
                return
            }
            
            guard let server_response = json as? NSDictionary else {
                return
            }
            if let data_block = server_response["data"] as? NSDictionary {
                if let session_data = data_block["session"] as? String {
                    self.login_session = session_data
                    let preferences = UserDefaults.standard
                    preferences.set(session_data, forKey: "session")
                    DispatchQueue.main.async(execute: self.LoginDone)
                }
            }
        })
        task.resume()
    }
    
    func LoginDone() {
        usernameTextField.isEnabled = false
        passwordTextField.isEnabled = false
        
        loginButton.isEnabled = true
        loginButton.setTitle("Logout", for: .normal)
    }
    
    func LoginToDo() {
        usernameTextField.isEnabled = true
        passwordTextField.isEnabled = true
        
        loginButton.isEnabled = true
        loginButton.setTitle("Login", for: .normal)
    }
    
    func check_session() {
        let post_data:NSDictionary = NSMutableDictionary()
        post_data.setValue(login_session, forKey: "session")
        let url:URL = URL(string: checksession_url)!
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        var paramString = ""
        
        for (key, value) in post_data {
            paramString = paramString + (key as! String) + "=" + (value as! String) + "&"
        }
        
        request.httpBody = paramString.data(using:String.Encoding.utf8)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            guard let _:Data = data, let _:URLResponse = response, error == nil else {
                return
            }
            let json: Any?
            do {
                json = try JSONSerialization.jsonObject(with: data!, options: [])
            } catch {
                return
            }
            
            guard let server_response = json as? NSDictionary else {
                return
            }
            if let response_code = server_response["response_code"] as? Int {
                if (response_code == 200) {
                    DispatchQueue.main.async(execute: self.LoginDone)
                } else {
                    DispatchQueue.main.async(execute: self.LoginToDo)
                }
            }
        })
        task.resume()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
