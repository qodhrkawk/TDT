//
//  SettingViewController+Backup.swift
//  TDT
//

import UIKit
import UniformTypeIdentifiers

extension SettingViewController {
    private static func dayString(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }

    private func loadedStore() -> TodoStore {
        let store = TodoStore(userDefaults: .grouped)
        store.load()
        return store
    }

    @objc func exportDataTapped() {
        let content = FlickBackup.sanitized(
            loadedStore().backupContent(),
            today: Self.dayString()
        )
        guard !content.isEmpty else {
            showToast(text: "내보낼 항목이 없어요", withDelay: 0.3)
            return
        }

        let alert = UIAlertController(
            title: "파일은 암호화되지 않아요",
            message: "공유할 곳을 확인한 뒤 보내주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "계속", style: .default) { [weak self] _ in
            self?.shareBackup(content)
        })
        present(alert, animated: true)
    }

    private func shareBackup(_ content: BackupContent) {
        let now = Date()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        do {
            let data = try FlickBackup.exportData(content: content, appVersion: appVersion, now: now)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(FlickBackup.fileName(now: now))
            try data.write(to: url, options: .atomic)

            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activity.popoverPresentationController?.sourceView = view
            activity.popoverPresentationController?.sourceRect = CGRect(
                x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0
            )
            activity.popoverPresentationController?.permittedArrowDirections = []
            present(activity, animated: true)
        } catch {
            showToast(text: "내보내지 못했어요", withDelay: 0.3)
        }
    }

    @objc func importDataTapped() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    private func showSimpleAlert(_ title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    fileprivate func handlePicked(url: URL) {
        let incoming: BackupContent
        do {
            let data = try Data(contentsOf: url)
            incoming = try FlickBackup.parse(data)
        } catch BackupError.newerVersion {
            showSimpleAlert("앱을 업데이트한 뒤 다시 가져와 주세요")
            return
        } catch {
            showSimpleAlert("Flick 데이터 파일이 아니에요")
            return
        }

        let store = loadedStore()
        let result = BackupMerger.merge(
            current: store.backupContent(),
            incoming: incoming,
            today: Self.dayString()
        )
        guard result.added > 0 else {
            showToast(text: "이미 모두 들어 있어요", withDelay: 0.3)
            return
        }

        let alert = UIAlertController(
            title: "새 항목 \(result.added)개를 추가할게요. 이미 있는 \(result.skipped)개는 건너뛰어요.",
            message: nil,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "가져오기", style: .default) { [weak self] _ in
            store.replaceAll(with: result.merged)
            WidgetDataManager.shared.updateData()
            NotificationCenter.default.post(name: .flickDataDidImport, object: nil)
            self?.showToast(text: "\(result.added)개를 추가했어요", withDelay: 0.3)
        })
        present(alert, animated: true)
    }
}

extension SettingViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        handlePicked(url: url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
}
