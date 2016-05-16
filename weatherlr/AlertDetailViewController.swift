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
    var popOver:AlertViewController?

    override func viewDidLoad() {
        webView.delegate = self
        
        webView.loadRequest(NSURLRequest(URL: NSURL(string: alert!.url)!))
        
        super.viewDidLoad()
        
        self.title = "Warning".localized()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        // followus hidden-print
        let js = "document.getElementById('wb-bc').remove(); document.getElementById('wb-glb-mn').remove(); document.getElementsByClassName('followus hidden-print')[0].remove(); document.getElementsByClassName('container hidden-print')[0].remove(); document.getElementById('weather-topics').remove(); document.getElementsByClassName('row pagedetails')[0].remove(); document.getElementsByClassName('gc-nttvs container')[0].remove(); document.getElementById('wb-info').remove();"
        webView.stringByEvaluatingJavaScriptFromString(js)
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: {()->Void in
                self.popOver?.dismissViewControllerAnimated(true, completion: nil)
            })
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
}
