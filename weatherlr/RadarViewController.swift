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
        webView.loadRequest(URLRequest(url: URL(string: url)!))
        
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = UIColor(weatherColor: WeatherColor.defaultColor)
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        self.title = "Radar".localized()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        // wb-sm
        let js = "document.body.style.backgroundColor = '#1f4f74'; document.getElementById('wb-cont').style.color = 'white'; document.getElementById('wb-bc').remove(); document.getElementById('wb-glb-mn').remove(); document.getElementsByClassName('container hidden-print')[0].remove(); document.getElementById('links').remove(); document.getElementById('weather-topics').remove(); document.getElementsByClassName('row pagedetails')[0].remove(); document.getElementsByClassName('gc-nttvs container')[0].remove(); document.getElementById('wb-info').remove(); document.getElementById('wb-sm').remove(); document.getElementsByClassName('well')[0].remove(); document.getElementById('wb-srch').remove();document.getElementById('wxo-overlay-cities').parentNode.parentNode.parentNode.parentNode.style.display = 'none'; document.getElementsByClassName('gc-prtts')[0].remove();"
        webView.stringByEvaluatingJavaScript(from: js)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

}
