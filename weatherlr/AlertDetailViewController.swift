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
        
        webView.loadRequest(URLRequest(url: URL(string: alert!.url)!))
        
        super.viewDidLoad()
        
        self.title = "Warning".localized()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        // followus hidden-print
        let js = "document.getElementById('wb-bc').remove(); document.getElementById('wb-glb-mn').remove(); document.getElementsByClassName('followus hidden-print')[0].remove(); document.getElementsByClassName('container hidden-print')[0].remove(); document.getElementById('weather-topics').remove(); document.getElementsByClassName('row pagedetails')[0].remove(); document.getElementsByClassName('gc-nttvs container')[0].remove(); document.getElementById('wb-info').remove(); document.getElementById('wb-sm').remove(); document.getElementById('wb-srch').remove();" 
        webView.stringByEvaluatingJavaScript(from: js)
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: {()->Void in
                self.popOver?.dismiss(animated: true, completion: nil)
            })
    }
    
    override var preferredStatusBarStyle:UIStatusBarStyle {
        return .default
    }
}
