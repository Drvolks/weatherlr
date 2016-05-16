//
//  AlertDetailViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-05-16.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class AlertDetailViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var webView: UIWebView!
    
    var alert:AlertInformation?

    override func viewDidLoad() {
        webView.delegate = self
        
        webView.loadRequest(NSURLRequest(URL: NSURL(string: alert!.url)!))
        
        super.viewDidLoad()
        
        self.title = "Warning".localized()
        
        
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
}
