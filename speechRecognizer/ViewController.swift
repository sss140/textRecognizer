//
//  ViewController.swift
//  speechRecognizer
//
//  Created by 佐藤一成 on 2020/06/05.
//  Copyright © 2020 s140. All rights reserved.
//
import UIKit
import Speech
import AVFoundation

class ViewController: UIViewController {

  var isRecording = false
  var w: CGFloat = 0
  var h: CGFloat = 0
  let d: CGFloat = 50
  let l: CGFloat = 28

  let recognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ja_JP"))!
  var audioEngine: AVAudioEngine!
  var recognitionReq: SFSpeechAudioBufferRecognitionRequest?
  var recognitionTask: SFSpeechRecognitionTask?
  
  @IBOutlet weak var recordButton: UIButton!
  @IBOutlet weak var baseView: UIView!
  @IBOutlet weak var outerCircle: UIView!
  @IBOutlet weak var innerCircle: UIView!
  @IBOutlet weak var textView: UITextView!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    audioEngine = AVAudioEngine()
    textView.text = ""
  }
  
  override func viewDidAppear(_ animated: Bool) {
    
    w = baseView.frame.size.width
    h = baseView.frame.size.height

    initRoundCorners()
    showStartButton()

    SFSpeechRecognizer.requestAuthorization { (authStatus) in
      DispatchQueue.main.async {
        if authStatus != SFSpeechRecognizerAuthorizationStatus.authorized {
          self.recordButton.isEnabled = false
          self.recordButton.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        }
      }
    }
  }
  
  func stopLiveTranscription() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionReq?.endAudio()
  }
  
  func startLiveTranscription() throws {

    // もし前回の音声認識タスクが実行中ならキャンセル
    if let recognitionTask = self.recognitionTask {
      recognitionTask.cancel()
      self.recognitionTask = nil
    }
    textView.text = ""

    // 音声認識リクエストの作成
    recognitionReq = SFSpeechAudioBufferRecognitionRequest()
    guard let recognitionReq = recognitionReq else {
      return
    }
    recognitionReq.shouldReportPartialResults = true

    // オーディオセッションの設定
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    let inputNode = audioEngine.inputNode

    // マイク入力の設定
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { (buffer, time) in
      recognitionReq.append(buffer)
    }
    audioEngine.prepare()
    try audioEngine.start()

    recognitionTask = recognizer.recognitionTask(with: recognitionReq, resultHandler: { (result, error) in
      if let error = error {
        print("\(error)")
      } else {
        DispatchQueue.main.async {
          self.textView.text = result?.bestTranscription.formattedString
        }
      }
    })
  }
  
  @IBAction func recordButtonTapped(_ sender: Any) {
    if isRecording {
      UIView.animate(withDuration: 0.2) {
        self.showStartButton()
      }
      stopLiveTranscription()
    } else {
      UIView.animate(withDuration: 0.2) {
        self.showStopButton()
      }
      try! startLiveTranscription()
    }
    isRecording = !isRecording
  }

  func initRoundCorners(){
    recordButton.layer.masksToBounds = true

    baseView.layer.masksToBounds = true
    baseView.layer.cornerRadius = 10
    baseView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

    outerCircle.layer.masksToBounds = true
    outerCircle.layer.cornerRadius = 31
    outerCircle.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)

    innerCircle.layer.masksToBounds = true
    innerCircle.layer.cornerRadius = 29
    innerCircle.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
  }
  
  func showStartButton() {
    recordButton.frame = CGRect(x:(w-d)/2,y:(h-d)/2,width:d,height:d)
    recordButton.layer.cornerRadius = d/2
  }
  
  func showStopButton() {
    recordButton.frame = CGRect(x:(w-l)/2,y:(h-l)/2,width:l,height:l)
    recordButton.layer.cornerRadius = 3.0
  }
}
