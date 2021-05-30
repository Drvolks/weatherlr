//
//  RadarViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-05-16.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit
import WebKit
import WeatherFramework

class RadarViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    var city:City?

    override func viewDidLoad() {
        webView.navigationDelegate = self
        
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        
        let url = UrlHelper.getRadarUrl(city!)
        webView.load(URLRequest(url: URL(string: url)!))
        
        super.viewDidLoad()
        
        self.title = "Radar".localized()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // document.getElementsByClassName('gc-nttvs container')[0].remove();
        let js = "document.body.style.backgroundColor = '#1f4f74'; document.body.style.color = 'white'; document.getElementsByClassName('container hidden-print')[0].remove(); document.getElementById('weather-topics').remove();  document.getElementById('wb-info').remove(); document.getElementById('wb-srch').remove(); document.getElementsByClassName('gcweb-menu')[0].remove(); document.getElementsByClassName('pagedetails')[0].remove(); document.getElementById('wb-lng').remove(); document.getElementById('wb-bc').remove(); "
        webView.evaluateJavaScript(js, completionHandler: { (html: AnyObject?, error: NSError?) in } as? (Any?, Error?) -> Void)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

}
