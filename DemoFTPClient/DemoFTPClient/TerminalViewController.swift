//
//  TerminalViewController.swift
//  PKDFTPClient
//
//  Created by Prabin K Datta on 16/03/17.
//  Copyright © 2017 Prabin K Datta. All rights reserved.
//

import UIKit

public extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    public class func once(token: String, block:(Void)->Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
}

class TerminalViewController: UIViewController,NMSSHSessionDelegate,NMSSHChannelDelegate,UITableViewDelegate,UITableViewDataSource {

    var host:String!
    var username:String!
    var password:String!
    var sshQueue:DispatchQueue!
    var session:NMSSHSession!
    var ftpSession:NMSFTP!
    
    var keyboardInteractive:Bool = false
    var filenames:NSArray!
    
    let ftpServerRootDirectoryPath:String = "/Distribution/Automation/profitcalc/PMMY_DEV/Download"
    
    @IBOutlet weak var m_textView: UITextView!
    @IBOutlet weak var m_tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        keyboardInteractive = self.password == nil
        self.m_textView.isEditable = false
        self.m_textView.isSelectable = false
        
        self.sshQueue = DispatchQueue(label: "PKDSSH.queue")
        
        self.filenames = NSArray.init()
        
        self.navigationController?.navigationItem.backBarButtonItem?.isEnabled = false
        self.m_tableView.tableHeaderView=nil
        self.m_tableView.tableFooterView=nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(TerminalViewController.keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TerminalViewController.keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
        
        DispatchQueue.once(token: "com.pkd.pkdftpclient") {
            self.connect(self)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.m_textView.resignFirstResponder()
    }

    
    //MARK: IBAction
    @IBAction func connect(_ sender: Any) {
        self.sshQueue.async {
            
            self.session = NMSSHSession.connect(toHost: self.host, withUsername: self.username)
            self.session.delegate = self as NMSSHSessionDelegate
            
            if !self.session.isConnected {
                DispatchQueue.main.async {
                    self.appendToTextView("Connection error")
                }
                
                return
            }
            
            DispatchQueue.main.async {
                self.appendToTextView("> ftp \(self.host!) \(self.username!) \n")
            }
            
            if self.keyboardInteractive {
                self.session.authenticateByKeyboardInteractive()
            }else{
                self.session.authenticate(byPassword: self.password)
            }
            
            if !self.session.isAuthorized {
                DispatchQueue.main.async {
                    self.appendToTextView("> Authentication error\n")
                    self.m_textView.isEditable = false;
                }
            }else{
                self.navigationController?.navigationItem.backBarButtonItem?.isEnabled = true
                self.navigationController?.navigationItem.rightBarButtonItem?.isEnabled = false
                // FTP Session
//                DispatchQueue.main.async {
//                    self.m_textView.isEditable = true
//                }
                self.ftpSession = NMSFTP.connect(with: self.session)
                self.filenames = self.ftpSession!.contentsOfDirectory(atPath: self.ftpServerRootDirectoryPath) as NSArray
                DispatchQueue.main.async {
                    self.appendToTextView("> Loaded Files from FTP Server\n")
                    self.m_tableView.reloadData()
//                    for filename in filenames {
//                        if let file: NMSFTPFile = filename as? NMSFTPFile {
//                            self.appendToTextView("\(file.filename!) \(file.fileSize!)\n")
//                        }
//                    }
                }
            }
        }
    }
    
    @IBAction func disconnect(_ sender: Any) {
        self.sshQueue.async {
            self.session.disconnect()
            self.navigationController?.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    
    //MARK: Methods
    func appendToTextView(_ text: String)  {
        self.m_textView.text = self.m_textView.text + text
        self.m_textView.scrollRangeToVisible(NSMakeRange(self.m_textView.text.characters.count-1, 1))
    }
    
    func keyboardWillShow(_ notification:Notification) {
//        let userInfo: NSDictionary = notification.userInfo as! [String: Any] as NSDictionary
//        let keyboardFrame:CGRect = userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect
//        
//        let ownFrame: CGRect = UIApplication.shared.delegate?.window.
    }

    func keyboardWillHide(_ notification:Notification) {}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    //MARK: UITableViewDelegate,UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filenames.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        if cell==nil {
            cell = UITableViewCell.init(style: .value1, reuseIdentifier: "Cell")
        }
        
        let file:NMSFTPFile = filenames[indexPath.row] as! NMSFTPFile
        cell.textLabel?.text = file.filename
        cell.detailTextLabel?.text = file.fileSize.stringValue
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file:NMSFTPFile = filenames[indexPath.row] as! NMSFTPFile
        self.appendToTextView("> Download File \(file.filename!) from FTP Server\n")
        
        let filePath:String = "\(self.ftpServerRootDirectoryPath)/\(file.filename!)"
        let exist = self.ftpSession.fileExists(atPath: filePath)
        
        if exist {
            self.appendToTextView("> File \(file.filename!) exists in FTP Server\n")
//            let file:NSData! = self.ftpSession.contents(atPath: filePath, progress: { (got:UInt, totalSize:UInt) -> Bool in
//                self.appendToTextView("> Downloading File \(file.filename!) \(got) of \(totalSize)\n")
//                return true
//            }) as NSData!
            
            let fileData:NSData! = self.ftpSession.contents(atPath: filePath) as NSData
            
            if fileData==nil {
                self.appendToTextView("> File \(file.filename!) failed to Download\n")
            }else{
                
            }
            
        }
    }
}
