import UIKit
import AVFoundation

protocol SettingsViewControllerDelegate: AnyObject {
    func settingsViewController(_ controller: SettingsViewController, didUpdateSettings settings: RecordingController.RecordingSettings)
}

class SettingsViewController: UITableViewController {
    weak var delegate: SettingsViewControllerDelegate?
    private var settings: RecordingController.RecordingSettings
    
    init(settings: RecordingController.RecordingSettings) {
        self.settings = settings
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Settings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                          target: self,
                                                          action: #selector(doneTapped))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    @objc private func doneTapped() {
        delegate?.settingsViewController(self, didUpdateSettings: settings)
        dismiss(animated: true)
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4 // Recording Duration
        case 1: return 2 // Recording Quality
        case 2: return 3 // Max Recordings
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Recording Duration"
        case 1: return "Recording Quality"
        case 2: return "Maximum Recordings"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        switch indexPath.section {
        case 0:
            let durations = [60, 180, 300, 600] // 1min, 3min, 5min, 10min
            cell.textLabel?.text = formatDuration(durations[indexPath.row])
            if Int(settings.duration) == durations[indexPath.row] {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            
        case 1:
            let qualities: [AVAudioQuality] = [.high, .medium]
            cell.textLabel?.text = formatQuality(qualities[indexPath.row])
            if settings.quality == qualities[indexPath.row] {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            
        case 2:
            let maxFiles = [20, 50, 100]
            cell.textLabel?.text = "\(maxFiles[indexPath.row]) recordings"
            if settings.maxRecordings == maxFiles[indexPath.row] {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            
        default:
            break
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            let durations = [60, 180, 300, 600]
            settings.duration = TimeInterval(durations[indexPath.row])
            
        case 1:
            let qualities: [AVAudioQuality] = [.high, .medium]
            settings.quality = qualities[indexPath.row]
            
        case 2:
            let maxFiles = [20, 50, 100]
            settings.maxRecordings = maxFiles[indexPath.row]
            
        default:
            break
        }
        
        tableView.reloadData()
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes == 1 {
            return "1 minute"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    private func formatQuality(_ quality: AVAudioQuality) -> String {
        switch quality {
        case .high:
            return "High Quality"
        case .medium:
            return "Standard Quality"
        default:
            return "Unknown"
        }
    }
}
