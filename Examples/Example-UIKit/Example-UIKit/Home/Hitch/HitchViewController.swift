//
//  HitchViewController.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import UIKit
import QuartzCore
import BlueTriangle

final class HitchCell: UITableViewCell {
    static let reuseIdentifier = "HitchCell"

    // Target time (ms) the next redraw should actually occupy. The draw loop below keeps doing
    // real CoreGraphics work until that much wall-clock time has genuinely elapsed, so the
    // hitch duration comes from real rendering cost, not a Thread.sleep block.
    var drawWorkloadDurationMs = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard drawWorkloadDurationMs > 0, let context = UIGraphicsGetCurrentContext() else { return }
        let deadline = CACurrentMediaTime() + TimeInterval(drawWorkloadDurationMs) / 1000
        while CACurrentMediaTime() < deadline {
            drawRandomBlob(in: context, rect: rect)
        }
    }

    // One unit of real drawing work: a filled, shadowed polygon with randomized points, so the
    // cost (and the CPU time it takes) is genuine rather than an artificial fixed delay.
    private func drawRandomBlob(in context: CGContext, rect: CGRect) {
        context.saveGState()
        let path = UIBezierPath()
        let pointCount = 24
        for i in 0..<pointCount {
            let angle = CGFloat(i) / CGFloat(pointCount) * 2 * .pi
            let radius = min(rect.width, rect.height) / 2 * CGFloat.random(in: 0.3...1.0)
            let point = CGPoint(x: rect.midX + radius * cos(angle), y: rect.midY + radius * sin(angle))
            i == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.close()
        context.setShadow(offset: .zero, blur: 6, color: UIColor.black.withAlphaComponent(0.25).cgColor)
        UIColor(hue: CGFloat.random(in: 0...1), saturation: 0.6, brightness: 0.9, alpha: 0.35).setFill()
        path.fill()
        context.restoreGState()
    }
}

final class HitchViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let rowCount = 100

    // The SDK classifies any stall over 750ms as a hang rather than a hitch
    // (Constants.Responsiveness.hangFloorMs) — kept in sync here since that constant isn't
    // public.
    private static let hangFloorMs = 750

    // Row index -> deliberate main-thread block duration (ms) fired both when that row scrolls
    // into view and when it's tapped, so a specific, repeatable row can be used to reproduce a
    // known-size hitch or hang either way. Durations below hangFloorMs land as hitches, at or
    // above it land as hangs. Weighted toward small hitches (many barely-noticeable rows) with
    // only a handful of long hang rows, so scrolling the list isn't dominated by big stalls.
    private let hitchScheduleMs: [Int: Int] = [
        5: 16,
        10: 50,
        15: 20,
        20: 150,
        25: 30,
        30: 300,
        35: 40,
        40: 450,
        45: 25,
        50: 700,
        55: 35,
        60: 800,
        65: 20,
        70: 1000,
        75: 45,
        80: 1500,
        85: 30,
        90: 2500
    ]

    // Natural Hitch: simulates a rendering loop getting stuck irregularly by forcing a visible
    // cell to do a real, expensive CoreGraphics redraw — both the gap between hitches and each
    // hitch's duration are re-rolled every cycle instead of following a fixed schedule.
    private let naturalHitchButton = UIBarButtonItem()
    private var isNaturalHitchingActive = false
    private static let naturalHitchDurationRangeMs = 10...150
    private static let naturalHitchIntervalRangeSeconds: ClosedRange<Double> = 0.2...2.0

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

        setupNaturalHitchButton()
    }

    deinit {
        isNaturalHitchingActive = false
    }

    private func setupNaturalHitchButton() {
        naturalHitchButton.title = "Natural Hitch: Off"
        naturalHitchButton.target = self
        naturalHitchButton.action = #selector(naturalHitchButtonTapped)
        navigationItem.rightBarButtonItem = naturalHitchButton
    }

    @objc
    private func naturalHitchButtonTapped() {
        isNaturalHitchingActive.toggle()
        naturalHitchButton.title = isNaturalHitchingActive ? "Natural Hitch: On" : "Natural Hitch: Off"
        if isNaturalHitchingActive {
            scheduleNextNaturalHitch()
        }
    }

    // Recursive random-delay scheduling (rather than a fixed-interval Timer) so the gap between
    // hitches varies every cycle, mimicking an irregularly stalling render loop.
    private func scheduleNextNaturalHitch() {
        guard isNaturalHitchingActive else { return }
        let delay = Double.random(in: Self.naturalHitchIntervalRangeSeconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, self.isNaturalHitchingActive else { return }
            self.performNaturalRenderHitch()
            self.scheduleNextNaturalHitch()
        }
    }

    // Picks a single visible cell to absorb the hitch — spreading the same duration across
    // every visible cell would multiply the total stall by the cell count instead of producing
    // one hitch of that length.
    private func performNaturalRenderHitch() {
        guard let cell = tableView.visibleCells.compactMap({ $0 as? HitchCell }).randomElement() else { return }
        let durationMs = Int.random(in: Self.naturalHitchDurationRangeMs)
        forceRealRenderHitch(on: cell, durationMs: durationMs)
    }

    // layer.displayIfNeeded() runs draw(_:) immediately on the main thread (unlike
    // setNeedsDisplay alone, which just schedules it for the next run-loop pass), so the block
    // below is real rendering cost, not a simulated delay.
    private func forceRealRenderHitch(on cell: HitchCell, durationMs: Int) {
        cell.drawWorkloadDurationMs = durationMs
        cell.layer.setNeedsDisplay()
        cell.layer.displayIfNeeded()
        cell.drawWorkloadDurationMs = 0
    }
}

extension HitchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HitchCell.reuseIdentifier, for: indexPath)
        if let hitchMs = hitchScheduleMs[indexPath.row] {
            let kind = hitchMs >= Self.hangFloorMs ? "Hang" : "Hitch"
            cell.textLabel?.text = "Hitch Cell \(indexPath.row + 1) — \(kind) \(hitchMs)ms"
        } else {
            cell.textLabel?.text = "Hitch Cell \(indexPath.row + 1)"
        }
        return cell
    }

    // Fires the row's scheduled hitch as soon as it scrolls into view, so simply scrolling
    // past a labeled row reproduces its known-size hitch.
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        triggerScheduledHitch(for: indexPath, cell: cell)
    }

    // Also fires the row's scheduled hitch on tap, for reproducing it without scrolling.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) {
            triggerScheduledHitch(for: indexPath, cell: cell)
        }
    }

    private func triggerScheduledHitch(for indexPath: IndexPath, cell: UITableViewCell) {
        guard let hitchMs = hitchScheduleMs[indexPath.row], let hitchCell = cell as? HitchCell else { return }
        forceRealRenderHitch(on: hitchCell, durationMs: hitchMs)
    }
}
