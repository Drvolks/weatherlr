//
//  AlertDetailViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-05-16.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit
import WebKit

class AlertDetailViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet weak var webView: WKWebView!
    var alert:AlertInformation?
    var popOver:AlertViewController?

    override func viewDidLoad() {
        webView.navigationDelegate = self
        
        var url = alert!.url
        // Problème de certificat ssl avec www.meteo.gc.ca!
        url = url.replacingOccurrences(of: "www.meteo.gc.ca", with: "meteo.gc.ca")
        webView.load(URLRequest(url: URL(string: url)!))
        
        super.viewDidLoad()
        
        self.title = "Warning".localized()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let js = "document.getElementById('wb-bc').remove(); document.getElementById('wb-glb-mn').remove(); document.getElementsByClassName('followus hidden-print')[0].remove(); document.getElementsByClassName('container hidden-print')[0].remove(); document.getElementById('weather-topics').remove(); document.getElementsByClassName('row pagedetails')[0].remove();  document.getElementById('wb-info').remove(); document.getElementById('wb-sm').remove(); document.getElementById('wb-srch').remove();"
        webView.evaluateJavaScript(js, completionHandler: { (_, _) in })
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
