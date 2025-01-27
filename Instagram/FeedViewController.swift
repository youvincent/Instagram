//
//  FeedViewController.swift
//  Instagram
//
//  Created by suiyan he on 2/26/21.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {

    var posts = [PFObject]()
    var showsCommentBar = false
    @IBOutlet weak var tableView: UITableView!
    let commentBar = MessageInputBar()
    var selectedPost: PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(hidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        // Do any additional setup after loading the view.
    }
    @objc func hidden(note: Notification){
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
    }
    override var inputAccessoryView: UIView?{
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool{
        return showsCommentBar
        //return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let query = PFQuery(className:"Posts")
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = 30
        
        query.findObjectsInBackground{(posts,error) in
            if posts != nil{
                self.posts = posts!
                self.tableView.reloadData()
            }
            
        }
    }
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        let comment = PFObject(className: "Comments")
        comment["text"] = text
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()!
        selectedPost.add(comment, forKey: "comments")
        selectedPost.saveInBackground{(success, error) in
        if success{
                print("Comment Save")
        }else{
                print("error")
            }
        }
        
        tableView.reloadData()
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        return comments.count + 2;
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count;
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell") as! PostTableViewCell
            let user = post["author"] as! PFUser
            cell.username.text = user.username
            cell.caption.text = (post["caption"] as! String)
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)!
            cell.photoView.af_setImage(withURL: url)
            return cell
        }else if indexPath.row <= comments.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            let comment = comments[indexPath.row-1]
            cell.comment.text = comment["text"] as! String
            
            let user = comment["author"] as! PFUser
            cell.user.text = user.username
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let comment = (post["comments"] as? [PFObject]) ?? []
        if indexPath.row == comment.count+1{
            showsCommentBar = true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            selectedPost = post
        }
    }
    
    @IBAction func onLogout(_ sender: Any) {
        PFUser.logOut()
        let main = UIStoryboard(name: "Main", bundle: nil)
        let login = main.instantiateViewController(identifier: "LoginController")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
             let delegate = windowScene.delegate as? SceneDelegate        else{
            return
            
        }
        delegate.window?.rootViewController = LoginViewController()
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
