//
//  ViewController.swift
//  FlashbackRecorder
//
//  Created by Anatolii Kasianov on 23.03.2020.
//  Copyright © 2020 Anatolii Kasianov. All rights reserved.
//

import UIKit

final class ViewController: UIViewController, RecordingControllerDelegate, SettingsViewControllerDelegate {
    // MARK: - Properties
    private var recordButton: UIButton!
    private var playButton: UIButton!
    private var cleanButton: UIButton!
    private var listFilesButton: UIButton!
    private var markerButton: UIButton!
    private var recordingController: RecordingController!
    private var recordingStorage: RecordingStorage!
    private var timerLabel: UILabel!
    private var recordingVisualizer: UIView!
    private var buttonStackView: UIStackView!
    private var feedbackView: FeedbackView!

    private var timerDisplayLink: CADisplayLink?
    private var startTime: Date?

    private var visualizerDisplayLink: CADisplayLink?
    private var visualizerLayers: [CALayer] = []
    private var currentMeteringLevel: Float = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupRecordingComponents()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !visualizerLayers.isEmpty {
            stopVisualizerAnimation()
            if recordingController.state == .recording || recordingController.state == .playing {
                startVisualizerAnimation()
            }
        }
    }

    // MARK: - UI Setup
    private func setupNavigationBar() {
        overrideUserInterfaceStyle = .dark
        navigationItem.title = "Voice Recorder"
        navigationController?.navigationBar.prefersLargeTitles = true

        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(openSettings)
        )
        navigationItem.rightBarButtonItem = settingsButton
    }

    private func setupRecordingComponents() {
        recordingStorage = RecordingStorage()
        recordingController = RecordingController()
        recordingController.delegate = self
        recordingController.setupRecordingSession()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        timerLabel = UILabel()
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.font = .monospacedDigitalFont(ofSize: 48)
        timerLabel.text = "00:00"
        timerLabel.textAlignment = .center
        view.addSubview(timerLabel)

        recordingVisualizer = UIView()
        recordingVisualizer.translatesAutoresizingMaskIntoConstraints = false
        recordingVisualizer.backgroundColor = .systemGray6
        recordingVisualizer.layer.cornerRadius = 8
        view.addSubview(recordingVisualizer)

        feedbackView = FeedbackView()
        feedbackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(feedbackView)

        recordButton = createModernButton(
            title: "Record",
            symbol: "record.circle",
            color: .systemRed,
            action: #selector(toggleRecording)
        )

        playButton = createModernButton(
            title: "Play",
            symbol: "play.circle",
            color: .systemGreen,
            action: #selector(togglePlaying)
        )

        cleanButton = createModernButton(
            title: "Clean",
            symbol: "trash",
            color: .systemOrange,
            action: #selector(toggleCleaning)
        )

        listFilesButton = createModernButton(
            title: "Recordings",
            symbol: "list.bullet",
            color: .systemBlue,
            action: #selector(toggleListing)
        )

        markerButton = createModernButton(
            title: "Add Marker",
            symbol: "bookmark.fill",
            color: .systemIndigo,
            action: #selector(addMarker)
        )

        buttonStackView = UIStackView(arrangedSubviews: [recordButton, playButton, markerButton, cleanButton, listFilesButton])
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 16
        buttonStackView.distribution = .fillEqually
        view.addSubview(buttonStackView)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            recordingVisualizer.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 32),
            recordingVisualizer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            recordingVisualizer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            recordingVisualizer.heightAnchor.constraint(equalToConstant: 120),

            buttonStackView.topAnchor.constraint(equalTo: recordingVisualizer.bottomAnchor, constant: 32),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            feedbackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            feedbackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            feedbackView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.9)
        ])
    }

    private func createModernButton(title: String, symbol: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.image = UIImage(systemName: symbol)
        configuration.imagePadding = 8
        configuration.cornerStyle = .medium
        configuration.baseBackgroundColor = color
        configuration.baseForegroundColor = .white

        button.configuration = configuration
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)

        return button
    }

    private func setButtonTitle(_ button: UIButton, title: String) {
        guard var config = button.configuration else { return }
        config.title = title
        button.configuration = config
    }

    // MARK: - RecordingControllerDelegate
    func recordingController(_ controller: RecordingController, didChangeStateTo state: RecordingController.State) {
        updateUIButtons(state: state)
        updateTimerAndVisualizer(state: state)

        switch state {
        case .recording:
            feedbackView.show(icon: "mic.fill", message: "Recording started", style: .success)
        case .playing:
            feedbackView.show(icon: "play.fill", message: "Playing recording", style: .info)
        case .readyToRecord:
            feedbackView.show(icon: "checkmark.circle.fill", message: "Recording saved", style: .success)
        case .readyToPlay:
            feedbackView.show(icon: "checkmark.circle.fill", message: "Playback finished", style: .info)
        case .failed:
            feedbackView.show(icon: "exclamationmark.triangle.fill", message: "Operation failed", style: .error)
        case .initial:
            break
        }
    }

    func recordingController(_ controller: RecordingController, didUpdateMeteringLevel level: Float) {
        currentMeteringLevel = level
    }

    // MARK: - SettingsViewControllerDelegate
    func settingsViewController(_ controller: SettingsViewController, didUpdateSettings settings: RecordingController.RecordingSettings) {
        recordingController.settings = settings
        feedbackView.show(icon: "checkmark.circle.fill", message: "Settings updated", style: .success)
    }

    // MARK: - UI Updates
    private func updateTimerAndVisualizer(state: RecordingController.State) {
        switch state {
        case .recording:
            startTimerAnimation()
            startVisualizerAnimation()
        case .playing:
            stopTimerAnimation()
            startVisualizerAnimation()
        case .readyToRecord, .readyToPlay, .initial, .failed:
            stopTimerAnimation()
            stopVisualizerAnimation()
        }
    }

    private func startTimerAnimation() {
        guard timerDisplayLink == nil else { return }
        startTime = Date()
        timerDisplayLink = CADisplayLink(target: self, selector: #selector(updateTimer))
        timerDisplayLink?.add(to: .main, forMode: .common)
    }

    private func stopTimerAnimation() {
        timerDisplayLink?.invalidate()
        timerDisplayLink = nil
        timerLabel.text = "00:00"
    }

    @objc private func updateTimer() {
        guard let startTime = startTime else { return }
        let timeInterval = Date().timeIntervalSince(startTime)
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }

    private func startVisualizerAnimation() {
        guard visualizerDisplayLink == nil else { return }
        setupVisualizerLayers()

        visualizerDisplayLink = CADisplayLink(target: self, selector: #selector(updateVisualizer))
        visualizerDisplayLink?.add(to: .main, forMode: .common)
    }

    private func stopVisualizerAnimation() {
        visualizerDisplayLink?.invalidate()
        visualizerDisplayLink = nil
        visualizerLayers.forEach { $0.removeFromSuperlayer() }
        visualizerLayers.removeAll()
    }

    private func setupVisualizerLayers() {
        guard recordingVisualizer.bounds.width > 0 else { return }

        let numberOfBars = 20
        let totalSpacing = CGFloat(numberOfBars - 1) * 4
        let barWidth = (recordingVisualizer.bounds.width - totalSpacing) / CGFloat(numberOfBars)

        for index in 0..<numberOfBars {
            let layer = CALayer()
            layer.frame = CGRect(
                x: CGFloat(index) * (barWidth + 4),
                y: recordingVisualizer.bounds.height,
                width: barWidth,
                height: 0
            )
            layer.backgroundColor = UIColor.systemBlue.cgColor
            layer.cornerRadius = 2
            recordingVisualizer.layer.addSublayer(layer)
            visualizerLayers.append(layer)
        }
    }

    @objc private func updateVisualizer() {
        for layer in visualizerLayers {
            let baseHeight = recordingVisualizer.bounds.height * CGFloat(currentMeteringLevel)
            let randomVariation = CGFloat.random(in: -5...5)
            let height = max(10, min(baseHeight + randomVariation, recordingVisualizer.bounds.height))

            CATransaction.begin()
            CATransaction.setAnimationDuration(0.1)
            layer.frame = CGRect(
                x: layer.frame.origin.x,
                y: recordingVisualizer.bounds.height - height,
                width: layer.frame.width,
                height: height
            )
            CATransaction.commit()
        }
    }

    private func updateUIButtons(state: RecordingController.State) {
        switch state {
        case .recording:
            setButtonTitle(recordButton, title: "Stop")
            playButton.isEnabled = false
        case .readyToRecord, .initial:
            setButtonTitle(recordButton, title: "Record")
            playButton.isEnabled = true
        case .playing:
            setButtonTitle(playButton, title: "Stop")
            recordButton.isEnabled = false
        case .readyToPlay:
            setButtonTitle(playButton, title: "Play")
            recordButton.isEnabled = true
        case .failed:
            setButtonTitle(recordButton, title: "Record")
            setButtonTitle(playButton, title: "Play")
            recordButton.isEnabled = true
            playButton.isEnabled = true
        }
    }

    // MARK: - Actions
    @objc private func openSettings() {
        let settingsVC = SettingsViewController(settings: recordingController.settings)
        settingsVC.delegate = self
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }

    @objc private func toggleRecording() {
        recordingController.toggleRecording()
    }

    @objc private func togglePlaying() {
        recordingController.togglePlaying()
    }

    @objc private func toggleCleaning() {
        let alert = UIAlertController(
            title: "Clean Recordings",
            message: "Are you sure you want to delete all recordings?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive) { [weak self] _ in
            self?.recordingStorage.deleteAllRecords()
            self?.feedbackView.show(icon: "trash.fill", message: "All recordings deleted", style: .info)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    @objc private func toggleListing() {
        let recordsVC = RecordsTableViewController()
        let navController = UINavigationController(rootViewController: recordsVC)
        present(navController, animated: true)
    }

    @objc private func addMarker() {
        let alert = UIAlertController(title: "New Marker", message: "Optional note", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Marker note"
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let note = alert.textFields?.first?.text
            self?.recordingController.addMarker(note: note)
            self?.feedbackView.show(icon: "bookmark.fill", message: "Marker saved", style: .success)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

private final class FeedbackView: UIView {
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.tintColor = .white
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        layer.cornerRadius = 12

        [iconView, messageLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            messageLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])

        alpha = 0
    }

    func show(icon: String, message: String, style: Style = .info) {
        iconView.image = UIImage(systemName: icon)?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        )
        messageLabel.text = message

        switch style {
        case .success:
            backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
        case .error:
            backgroundColor = UIColor.systemRed.withAlphaComponent(0.9)
        case .info:
            backgroundColor = UIColor.black.withAlphaComponent(0.8)
        }

        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.hide()
        }
    }

    private func hide() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        }
    }

    enum Style {
        case success
        case error
        case info
    }
}
