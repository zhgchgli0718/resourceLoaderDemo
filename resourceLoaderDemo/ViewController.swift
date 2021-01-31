//
//  ViewController.swift
//  resourceLoaderDemo
//
//  Created by Zhong Cheng Li on 2021/1/31.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var playButton: UIButton!
    private var avPlayer: AVPlayer?
    
    @IBAction func playButtonClicked(_ sender: Any) {
        let url = URL(string: "")!
        self.avPlayer = AVPlayer(playerItem: AVPlayerItem(asset: CachingAVURLAsset(url: url)))
        self.avPlayer?.play()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}
