//
//  PersonalListsViewController.swift
//  SharedList
//
//  Created by Pieter Stragier on 30/10/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import UIKit
import Speech

class PersonalListsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SFSpeechRecognizerDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var listop: String = "List"
    var selectedSection: Int = 0
    
    @IBOutlet weak var topLabel: UILabel!
    
    @IBOutlet weak var spokenTextView: UITextView!
    var segAttr = NSDictionary(object: UIFont(name: "Helvetica", size: 20.0)!, forKey: NSFontAttributeName as NSCopying)
    
    var itemdict: Dictionary<String, Array<String>> = ["shop 1": ["milk", "chocolate", "eggs"], "shop 2": ["dog food"]]
    var latestaddedHeader: String = ""
    let localdata = UserDefaults.standard
    
    @IBOutlet weak var subview: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputview: UIView!
    @IBOutlet weak var addItem: UIButton!
    @IBOutlet weak var input: UITextField!
    
    @IBOutlet weak var addHeader: UIButton!
    @IBAction func addHeader(_ sender: UIButton) {
        if (input.text != "") {
            itemdict[input.text!] = []
            latestaddedHeader = input.text!
            input.text = ""
        }
        tableView.reloadData()
    }
    @IBAction func addItem(_ sender: UIButton) {
        if (input.text != "") {
            if latestaddedHeader != "" {
                itemdict[latestaddedHeader]?.append(input.text!)
            } else {
                if Array(itemdict.keys).count > 0 {
                    let key = Array(itemdict.keys)[0]
                    itemdict[key]?.append(input.text!)
                } else {
                    itemdict["Header 1"] = [input.text!]
                }
            }
            input.text = ""
        }
        tableView.reloadData()
    }
    
    @IBOutlet weak var micButton: UIButton!
    
    @IBAction func micButton(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            micButton.isEnabled = false
            micButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            micButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    // MARK: - Load cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupLayout()
        allowSpeech()
        self.updateView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // MARK: - Speech Recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func allowSpeech() {
        micButton.isEnabled = false
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
        var isButtonEnabled = false
        switch authStatus {
        case .authorized:
            isButtonEnabled = true
        case .denied:
            isButtonEnabled = false
            print("User denied access to speech recognition")
        case .restricted:
            isButtonEnabled = false
            print("Speech recognition restricted on this device")
        case .notDetermined:
            isButtonEnabled = false
            print("Speech recognition not yet authorized")
        }
        OperationQueue.main.addOperation() {
            self.micButton.isEnabled = isButtonEnabled
        }
        }
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest.")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            if result != nil {
                self.input.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.micButton.isEnabled = true
            }
        })
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        input.text = "Say something, I'm listening!"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            micButton.isEnabled = true
        } else {
            micButton.isEnabled = false
        }
    }
    // MARK: - Layout
    func setupLayout() {
        addHeader.titleLabel?.text = "+H"
        input.layer.borderColor = UIColor.orange.cgColor
        input.layer.borderWidth = 2
        createGradient()
        
    }
   
    // MARK: - Create gradient
    func createGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.brown.cgColor, UIColor.white.cgColor]
        gradient.locations = [0.0, 0.8]
        self.view.layer.insertSublayer(gradient, at: 0)
        
        let gradientInputView = CAGradientLayer()
        gradientInputView.frame = inputview.bounds
        gradientInputView.colors = [UIColor.brown.cgColor, UIColor.brown.cgColor, UIColor.white.cgColor]
        gradientInputView.locations = [0.0, 0.8, 0.99]
        self.inputview.layer.insertSublayer(gradientInputView, at: 0)
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return itemdict.keys.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let headerCell = tableView.dequeueReusableCell(withIdentifier: "UserHeader") as? UserHeaderTableViewCell else {
            fatalError("found nil")
        }
        headerCell.delegate = self as? UserHeaderTableViewCellDelegate
        
        headerCell.textLabel?.text = Array(itemdict.keys)[section]
        headerCell.headerCellSection = section
        
        
        return headerCell
    }
    
    func headerTapAction(sender: UIGestureRecognizer) {
        // Get the view
        let senderView = sender.view as! UserHeaderTableViewCell
        //didSelectUserHeaderTableViewCell(Selected: true, UserHeader: senderView)
        // Get the section
        let section = senderView.headerCellSection
        
        print(section!)
    }

    func delButtonTapped(_ header: Int) {
        // Delete selected header
        let headerTitle = tableView(tableView, titleForHeaderInSection: header)
        let keyIndex = itemdict.keys.index(of: headerTitle!)
        itemdict.remove(at: keyIndex!)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let header = Array(itemdict.keys)[section]
        return header
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var number: Int = 0
        let sectionheader = Array(itemdict.keys)[section]
        for (key, value) in itemdict {
            if key == sectionheader {
                number = value.count
            }
        }
        return number
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "ListsCell")
        //let cell = tableView.dequeueReusableCell(withIdentifier: CellModel.reuseIdentifier, for: indexPath)
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellModel.reuseIdentifier, for: indexPath) as? CellModel else {
            fatalError("Unexpected Index Path")
        }
        // Configure Cell
        cell.layer.cornerRadius = 3
        cell.layer.masksToBounds = true
        cell.layer.borderWidth = 0
        cell.showsReorderControl = true
        
        cell.listitem?.text = (itemdict[Array(itemdict.keys)[indexPath.section]]?[indexPath.row])!
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            let header = Array(itemdict.keys)[indexPath.section]
            //let item = itemdict[header]?[indexPath.row]
            self.itemdict[header]?.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    
    private func updateView() {
        
    }
}

