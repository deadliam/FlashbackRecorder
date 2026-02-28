import UIKit

final class TimelineViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let storage: RecordingStorage
    private let onSelectRecord: (Record, Bool) -> Void

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        return picker
    }()

    private let hourSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 24 * 60 * 60
        return slider
    }()

    private let markerOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()

    private let selectedTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = "00:00:00"
        return label
    }()

    private let markerCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()

    private let jumpButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Jump & Play"
        config.image = UIImage(systemName: "play.circle.fill")
        config.imagePadding = 8
        let button = UIButton(type: .system)
        button.configuration = config
        return button
    }()

    private let markersTableView = UITableView(frame: .zero, style: .insetGrouped)
    private var markers: [MarkerRecord] = []

    init(storage: RecordingStorage, onSelectRecord: @escaping (Record, Bool) -> Void) {
        self.storage = storage
        self.onSelectRecord = onSelectRecord
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        refreshTimeline()
    }

    private func setupUI() {
        title = "Timeline"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        [datePicker, hourSlider, markerOverlayView, selectedTimeLabel, markerCountLabel, jumpButton, markersTableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        hourSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        jumpButton.addTarget(self, action: #selector(jumpTapped), for: .touchUpInside)

        markersTableView.dataSource = self
        markersTableView.delegate = self
        markersTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MarkerCell")

        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            selectedTimeLabel.centerYAnchor.constraint(equalTo: datePicker.centerYAnchor),
            selectedTimeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            hourSlider.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 16),
            hourSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            hourSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            markerOverlayView.leadingAnchor.constraint(equalTo: hourSlider.leadingAnchor),
            markerOverlayView.trailingAnchor.constraint(equalTo: hourSlider.trailingAnchor),
            markerOverlayView.centerYAnchor.constraint(equalTo: hourSlider.centerYAnchor),
            markerOverlayView.heightAnchor.constraint(equalToConstant: 20),

            markerCountLabel.topAnchor.constraint(equalTo: hourSlider.bottomAnchor, constant: 8),
            markerCountLabel.leadingAnchor.constraint(equalTo: hourSlider.leadingAnchor),
            markerCountLabel.trailingAnchor.constraint(equalTo: hourSlider.trailingAnchor),

            jumpButton.topAnchor.constraint(equalTo: markerCountLabel.bottomAnchor, constant: 12),
            jumpButton.leadingAnchor.constraint(equalTo: hourSlider.leadingAnchor),
            jumpButton.trailingAnchor.constraint(equalTo: hourSlider.trailingAnchor),
            jumpButton.heightAnchor.constraint(equalToConstant: 44),

            markersTableView.topAnchor.constraint(equalTo: jumpButton.bottomAnchor, constant: 12),
            markersTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            markersTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            markersTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func dateChanged() {
        refreshTimeline()
    }

    @objc private func sliderChanged() {
        updateSelectedTimeLabel()
    }

    @objc private func jumpTapped() {
        guard let record = storage.findRecord(at: selectedDateTime) else { return }
        onSelectRecord(record, true)
        dismiss(animated: true)
    }

    private func refreshTimeline() {
        let dayStart = Calendar.current.startOfDay(for: datePicker.date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        markers = storage.fetchMarkers(from: dayStart, to: dayEnd, limit: 500)
        markerCountLabel.text = "Markers today: \(markers.count)"
        markersTableView.reloadData()
        updateSelectedTimeLabel()
        renderMarkerTicks()
    }

    private func updateSelectedTimeLabel() {
        selectedTimeLabel.text = Self.timeFormatter.string(from: selectedDateTime)
    }

    private var selectedDateTime: Date {
        let dayStart = Calendar.current.startOfDay(for: datePicker.date)
        return dayStart.addingTimeInterval(TimeInterval(hourSlider.value))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        renderMarkerTicks()
    }

    private func renderMarkerTicks() {
        markerOverlayView.subviews.forEach { $0.removeFromSuperview() }
        guard markerOverlayView.bounds.width > 0 else { return }

        let dayStart = Calendar.current.startOfDay(for: datePicker.date)
        let secondsInDay: TimeInterval = 24 * 60 * 60

        markers.forEach { marker in
            let offset = marker.timestamp.timeIntervalSince(dayStart)
            guard offset >= 0, offset <= secondsInDay else { return }

            let xPosition = CGFloat(offset / secondsInDay) * markerOverlayView.bounds.width
            let tick = UIView(frame: CGRect(x: xPosition - 1, y: 2, width: 2, height: 16))
            tick.backgroundColor = .systemOrange
            tick.layer.cornerRadius = 1
            markerOverlayView.addSubview(tick)
        }
    }

    // MARK: - Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        markers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MarkerCell", for: indexPath)
        let marker = markers[indexPath.row]
        let time = Self.timeFormatter.string(from: marker.timestamp)
        let note = marker.note?.isEmpty == false ? " - \(marker.note!)" : ""
        cell.textLabel?.text = "\(time)\(note)"
        cell.textLabel?.numberOfLines = 2
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let marker = markers[indexPath.row]
        if let record = storage.findRecord(at: marker.timestamp) {
            onSelectRecord(record, true)
            dismiss(animated: true)
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
