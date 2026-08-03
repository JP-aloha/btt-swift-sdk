//
//  HitchViewController.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import UIKit
import BlueTriangle

final class HitchCell: UITableViewCell {
    static let reuseIdentifier = "HitchCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

final class HitchViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let rowCount = 100

    // Row index -> deliberate main-thread block duration (ms) fired both when that row
    // scrolls into view and when it's tapped, so a specific, repeatable row can be used to
    // reproduce a known-size hitch either way.
    private let hitchScheduleMs: [Int: Int] = [
        10: 50,
        30: 150,
        50: 250,
        70: 500,
        80: 800
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hitch"
        view.backgroundColor = .systemBackground

        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HitchCell.self, forCellReuseIdentifier: HitchCell.reuseIdentifier)
        view.addSubview(tableView)
    }
}

extension HitchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HitchCell.reuseIdentifier, for: indexPath)
        if let hitchMs = hitchScheduleMs[indexPath.row] {
            cell.textLabel?.text = "Hitch Cell \(indexPath.row + 1) — Hitch \(hitchMs)ms"
        } else {
            cell.textLabel?.text = "Hitch Cell \(indexPath.row + 1)"
        }
        return cell
    }

    // Fires the row's scheduled hitch as soon as it scrolls into view, so simply scrolling
    // past a labeled row reproduces its known-size hitch.
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        triggerScheduledHitch(for: indexPath)
    }

    // Also fires the row's scheduled hitch on tap, for reproducing it without scrolling.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        triggerScheduledHitch(for: indexPath)
    }

    private func triggerScheduledHitch(for indexPath: IndexPath) {
        guard let hitchMs = hitchScheduleMs[indexPath.row] else { return }
        Thread.sleep(forTimeInterval: TimeInterval(hitchMs) / 1000)
    }
}
