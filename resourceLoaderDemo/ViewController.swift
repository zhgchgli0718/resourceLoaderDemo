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
        let url = URL(string: "http://www.hochmuth.com/mp3/Haydn_Cello_Concerto_D-1.mp3")!
        self.avPlayer = AVPlayer(playerItem: AVPlayerItem(asset: CachingAVURLAsset(url: url)))
        self.avPlayer?.play()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}
