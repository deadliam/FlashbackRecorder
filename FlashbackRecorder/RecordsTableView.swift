//
//  RecordsTableView.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 26.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class RecordingCell: UITableViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitalFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        button.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .systemGreen
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        [titleLabel, dateLabel, durationLabel, playButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -8),
            
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            durationLabel.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            durationLabel.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 12),
            
            playButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func configure(with recording: Record, onPlay: @escaping () -> Void) {
        titleLabel.text = recording.title
        dateLabel.text = recording.date.toString(dateFormat: "MMM d, yyyy HH:mm")
        
        // Get audio duration
        let url = recording.url
        let asset = AVURLAsset(url: url)
        let duration = asset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        let minutes = Int(durationInSeconds) / 60
        let seconds = Int(durationInSeconds) % 60
        durationLabel.text = String(format: "%d:%02d", minutes, seconds)
        
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        self.onPlay = onPlay
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playButton.removeTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        onPlay = nil
    }
    
    private var onPlay: (() -> Void)?
    
    @objc private func playButtonTapped() {
        onPlay?()
    }
}

class RecordsTableViewController: UITableViewController {
    private var recordings: [Record] = []
    private let storage = RecordingStorage()
    private var player: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadRecordings()
    }
    
    private func setupUI() {
        title = "Recordings"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.register(RecordingCell.self, forCellReuseIdentifier: "RecordingCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshRecordings), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func refreshRecordings() {
        loadRecordings()
        tableView.refreshControl?.endRefreshing()
    }
    
    private func loadRecordings() {
        recordings = storage.getExistingRecordsArray().sorted { $0.date > $1.date }
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordingCell", for: indexPath) as! RecordingCell
        let recording = recordings[indexPath.row]
        
        cell.configure(with: recording) { [weak self] in
            self?.playRecording(recording)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let recording = recordings[indexPath.row]
            storage.removeRecord(name: recording.title)
            recordings.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    private func playRecording(_ recording: Record) {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            player = try AVAudioPlayer(contentsOf: recording.url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Error playing recording: \(error.localizedDescription)")
        }
    }
}
