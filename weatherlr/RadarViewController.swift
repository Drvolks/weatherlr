//
//  RadarViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-05-16.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class RadarViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var webView: UIWebView!
    
    var city:City?

    override func viewDidLoad() {
        webView.delegate = self
        
        let url = UrlHelper.getRadarUrl(city!)
        webView.loadRequest(NSURLRequest(URL: NSURL(string: url)!))
        
        super.viewDidLoad()

        self.title = "Radar".localized()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        let js = "document.getElementById('wb-bc').remove(); document.getElementById('wb-glb-mn').remove(); document.getElementsByClassName('container hidden-print')[0].remove(); document.getElementById('links').remove(); document.getElementById('weather-topics').remove(); document.getElementsByClassName('row pagedetails')[0].remove(); document.getElementsByClassName('gc-nttvs container')[0].remove(); document.getElementById('wb-info').remove();"
        webView.stringByEvaluatingJavaScriptFromString(js)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func done(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

}
