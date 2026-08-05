//
//  AnimationHitchViewController.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import UIKit

#if DEBUG
@testable import BlueTriangle

final class AnimationHitchViewController: UIViewController {

    private let circleTrack = UIView()
    private let movingDot = UIView()
    private let centerTimeLabel = UILabel()
    private let statusStack = UIStackView()
    private let statusDotView = UIView()
    private let statusTextLabel = UILabel()
    private let sectionsScrollView = UIScrollView()
    private let sectionsContainer = UIStackView()
    private let buttonsContainer = UIStackView()

    private let hitchTitleLabel = UILabel()
    private let hitchStatsLabel = UILabel()
    private let hitchButtonStack = UIStackView()

    private let hangTitleLabel = UILabel()
    private let hangStatsLabel = UILabel()
    private let hangButtonStack = UIStackView()

    // Duration (ms) options, mirroring HitchViewController's schedule. Tapping a button starts
    // a repeating timer that blocks the main thread for that duration once every second.
    private let hitchDurationsMs = [30, 50, 150, 250, 500]

    // "Hang" row: durations above Constants.Responsiveness.hangFloorMs, so tapping one of these trips
    // the "hang" classification rather than just a regular hitch.
    private let hangDurationsMs = [800, 900, 1000, 1100, 1200]

    private var buttonsByDuration: [Int: UIButton] = [:]
    private var hitchTimer: Timer?
    private var activeDurationMs: Int?

    private var circleTimer: Timer?
    private var circleStartTime: CFTimeInterval = 0
    private let circleDuration: CFTimeInterval = 3.0
    private var didStartCircle = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Animation Hitch"
        view.backgroundColor = .systemBackground
        setupCircle()
        setupSections()
        setupButtons()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didStartCircle, circleTrack.bounds.width > 0 else { return }
        didStartCircle = true
        startCircleAnimation()
    }

    deinit {
        circleTimer?.invalidate()
        hitchTimer?.invalidate()
    }

    // MARK: - Circle animation

    private func setupCircle() {
        circleTrack.translatesAutoresizingMaskIntoConstraints = false
        circleTrack.layer.borderWidth = 5
        circleTrack.layer.borderColor = UIColor.systemGray4.cgColor
        view.addSubview(circleTrack)

        movingDot.backgroundColor = .systemBlue
        movingDot.frame.size = CGSize(width: 40, height: 40)
        movingDot.layer.cornerRadius = 20
        view.addSubview(movingDot)

        NSLayoutConstraint.activate([
            circleTrack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            circleTrack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circleTrack.widthAnchor.constraint(equalToConstant: 300),
            circleTrack.heightAnchor.constraint(equalToConstant: 300)
        ])

        setupCenterOverlay()
    }

    // Elapsed time + a green/orange/red health sign, both centered inside the circle track —
    // the moving dot stays on the perimeter (radius = track width / 2), so the center stays clear.
    private func setupCenterOverlay() {
        centerTimeLabel.font = .monospacedDigitSystemFont(ofSize: 32, weight: .bold)
        centerTimeLabel.textAlignment = .center
        centerTimeLabel.textColor = .label
        centerTimeLabel.text = "00:00"
        centerTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        circleTrack.addSubview(centerTimeLabel)

        statusDotView.layer.cornerRadius = 6
        statusDotView.backgroundColor = .systemGreen
        statusDotView.translatesAutoresizingMaskIntoConstraints = false

        statusTextLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        statusTextLabel.textColor = .systemGreen
        statusTextLabel.text = "GOOD"

        statusStack.axis = .horizontal
        statusStack.spacing = 6
        statusStack.alignment = .center
        statusStack.translatesAutoresizingMaskIntoConstraints = false
        statusStack.addArrangedSubview(statusDotView)
        statusStack.addArrangedSubview(statusTextLabel)
        circleTrack.addSubview(statusStack)

        NSLayoutConstraint.activate([
            statusDotView.widthAnchor.constraint(equalToConstant: 12),
            statusDotView.heightAnchor.constraint(equalToConstant: 12),
            centerTimeLabel.centerXAnchor.constraint(equalTo: circleTrack.centerXAnchor),
            centerTimeLabel.centerYAnchor.constraint(equalTo: circleTrack.centerYAnchor, constant: -14),
            statusStack.centerXAnchor.constraint(equalTo: circleTrack.centerXAnchor),
            statusStack.topAnchor.constraint(equalTo: centerTimeLabel.bottomAnchor, constant: 10)
        ])
    }

    // Manually drives the dot's position on a ~60fps repeating Timer (rather than handing a
    // CAAnimation to Core Animation's render server, which would keep interpolating smoothly
    // even while the main thread is blocked). A Timer only fires when the main run loop is
    // free, so blocking the main thread (the hitch) makes the dot visibly freeze in place
    // until it unblocks, then jump ahead to the correct position for elapsed time.
    private func startCircleAnimation() {
        circleTrack.layer.cornerRadius = circleTrack.bounds.width / 2
        circleStartTime = CACurrentMediaTime()

        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateCirclePosition()
        }
        RunLoop.main.add(timer, forMode: .common)
        circleTimer = timer
    }

    private func updateCirclePosition() {
        let elapsed = CACurrentMediaTime() - circleStartTime
        let progress = elapsed.truncatingRemainder(dividingBy: circleDuration) / circleDuration
        let angle: Double = progress * 2 * Double.pi
        let center = circleTrack.center
        let radius = circleTrack.bounds.width / 2
        movingDot.center = CGPoint(
            x: center.x + radius * CGFloat(cos(angle)),
            y: center.y + radius * CGFloat(sin(angle))
        )
        updateStatsLabels()
        updateCenterOverlay(elapsed: elapsed)
    }

    private func updateCenterOverlay(elapsed: CFTimeInterval) {
        let totalSeconds = Int(elapsed)
        centerTimeLabel.text = String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)

        let stats = BlueTriangle.currentResponsivenessStats()
        // stats.hitchTimeRatio and stats.hitchFramePercent are already percentages (0-100).
        let score = ResponsivenessGrade.grade(
            hitchRatio: stats.hitchTimeRatio,
            hitchFramePercent: stats.hitchFramePercent,
            hangCount: stats.hangCount,
            longestHang: stats.longestHang)
        let (color, label): (UIColor, String)
        switch score {
        case 0...30:
            (color, label) = (.systemGreen, "GOOD")
        case 31...70:
            (color, label) = (.systemOrange, "BAD")
        default:
            (color, label) = (.systemRed, "WORST")
        }
        statusDotView.backgroundColor = color
        statusTextLabel.textColor = color
        statusTextLabel.text = "\(label) (\(score))"
    }

    // MARK: - Sections (Hitch / Hang)

    // Two visually separated sections below the circle — title + live stats only. Buttons live
    // in their own container pinned to the bottom of the screen (see setupButtons()). The stats
    // sit inside a scroll view (bounded between the circle and the buttons) so that if content
    // is ever taller than the available space, it scrolls instead of being silently compressed
    // or clipped by Auto Layout — every line of every stat stays reachable/visible.
    private func setupSections() {
        sectionsScrollView.translatesAutoresizingMaskIntoConstraints = false
        sectionsScrollView.showsVerticalScrollIndicator = false
        view.addSubview(sectionsScrollView)

        NSLayoutConstraint.activate([
            sectionsScrollView.topAnchor.constraint(equalTo: circleTrack.bottomAnchor, constant: 12),
            sectionsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sectionsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        sectionsContainer.axis = .vertical
        sectionsContainer.spacing = 16
        sectionsContainer.translatesAutoresizingMaskIntoConstraints = false
        sectionsScrollView.addSubview(sectionsContainer)

        NSLayoutConstraint.activate([
            sectionsContainer.topAnchor.constraint(equalTo: sectionsScrollView.contentLayoutGuide.topAnchor, constant: 8),
            sectionsContainer.bottomAnchor.constraint(equalTo: sectionsScrollView.contentLayoutGuide.bottomAnchor, constant: -8),
            sectionsContainer.leadingAnchor.constraint(equalTo: sectionsScrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            sectionsContainer.trailingAnchor.constraint(equalTo: sectionsScrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            sectionsContainer.widthAnchor.constraint(equalTo: sectionsScrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        let hitchSection = makeSection(
            titleLabel: hitchTitleLabel,
            titleText: "Hitch",
            titleColor: .systemOrange,
            statsLabel: hitchStatsLabel)

        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let hangSection = makeSection(
            titleLabel: hangTitleLabel,
            titleText: "Hang",
            titleColor: .systemRed,
            statsLabel: hangStatsLabel)

        sectionsContainer.addArrangedSubview(hitchSection)
        sectionsContainer.addArrangedSubview(divider)
        sectionsContainer.addArrangedSubview(hangSection)

        updateStatsLabels()
    }

    private func makeSection(
        titleLabel: UILabel,
        titleText: String,
        titleColor: UIColor,
        statsLabel: UILabel
    ) -> UIStackView {
        titleLabel.text = titleText
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = titleColor
        titleLabel.textAlignment = .center

        statsLabel.numberOfLines = 0
        statsLabel.textAlignment = .center
        statsLabel.font = .monospacedSystemFont(ofSize: 17, weight: .regular)
        statsLabel.textColor = .secondaryLabel

        let section = UIStackView(arrangedSubviews: [titleLabel, statsLabel])
        section.axis = .vertical
        section.spacing = 5
        return section
    }

    // MARK: - Buttons (all pinned to the bottom of the screen)

    private func setupButtons() {
        buttonsContainer.axis = .vertical
        buttonsContainer.spacing = 12
        buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonsContainer)

        NSLayoutConstraint.activate([
            buttonsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            sectionsScrollView.bottomAnchor.constraint(equalTo: buttonsContainer.topAnchor, constant: -8)
        ])

        populateButtonRow(hitchButtonStack, durationsMs: hitchDurationsMs)
        populateButtonRow(hangButtonStack, durationsMs: hangDurationsMs)
        buttonsContainer.addArrangedSubview(hitchButtonStack)
        buttonsContainer.addArrangedSubview(hangButtonStack)
    }

    private func populateButtonRow(_ row: UIStackView, durationsMs: [Int]) {
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 12

        for ms in durationsMs {
            let button = UIButton(type: .system)
            button.setTitle(durationButtonTitle(forMs: ms), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            button.backgroundColor = .secondarySystemBackground
            button.layer.cornerRadius = 8
            button.tag = ms
            button.addTarget(self, action: #selector(durationButtonTapped(_:)), for: .touchUpInside)
            buttonsByDuration[ms] = button
            row.addArrangedSubview(button)
        }
        row.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    // Durations over 1000Ms read more naturally in seconds (e.g. "1.2Sec" instead of "1200Ms").
    private func durationButtonTitle(forMs ms: Int) -> String {
        if ms > 1000 {
            return String(format: "%.1fSec", Double(ms) / 1000)
        }
        return "\(ms)Ms"
    }

    // MARK: - Live hitch/hang stats

    private func updateStatsLabels() {
        let stats = BlueTriangle.currentResponsivenessStats()
        hitchStatsLabel.text = """
        Hitch Count: \(stats.hitchCount)
        Total Hitch Duration: \(stats.totalHitchDuration)Ms
        Hitch Frame %: \(percentString(stats.hitchFramePercent))
        Hitch Time Ratio: \(percentString(stats.hitchTimeRatio))
        """
        hangStatsLabel.text = """
        Hang Count: \(stats.hangCount)
        Total Hang Duration: \(secondsString(fromMs: stats.totalHangDuration))
        Longest Hang: \(secondsString(fromMs: stats.longestHang))
        Hang Time Ratio: \(percentString(stats.hangTimeRatio))
        """
    }

    private func percentString(_ percent: Float) -> String {
        String(format: "%.2f%%", percent)
    }

    private func secondsString(fromMs ms: Millisecond) -> String {
        String(format: "%.2fSec", Double(ms) / 1000)
    }

    // MARK: - Hitch/hang buttons

    @objc
    private func durationButtonTapped(_ sender: UIButton) {
        let ms = sender.tag
        if activeDurationMs == ms {
            stopHitching()
        } else {
            startHitching(ms: ms)
        }
    }

    private func startHitching(ms: Int) {
        hitchTimer?.invalidate()
        activeDurationMs = ms
        updateButtonAppearance()
        hitchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Thread.sleep(forTimeInterval: TimeInterval(ms) / 1000)
        }
    }

    private func stopHitching() {
        hitchTimer?.invalidate()
        hitchTimer = nil
        activeDurationMs = nil
        updateButtonAppearance()
    }

    private func updateButtonAppearance() {
        for (ms, button) in buttonsByDuration {
            button.backgroundColor = (ms == activeDurationMs)
                ? .systemRed.withAlphaComponent(0.3)
                : .secondarySystemBackground
        }
    }
}

// Continuous 1-100 responsiveness score (0 = best, 100 = worst) derived from hitch ratio, hitch
private enum ResponsivenessGrade {

    /// Explicit banded severity/badness curve: 0=best, 100=worst.
    private static func severity(_ value: Float, good: Float, bad: Float, cap: Float) -> Float {
        guard value > 0 else { return 0 }
        if value <= good {
            return (value / good) * 30
        }
        if value <= bad {
            let t = (value - good) / (bad - good)
            return 30 + t * 40
        }
        if value <= cap {
            let t = (value - bad) / (cap - bad)
            return 70 + t * 30
        }
        return 100
    }

    // MARK: - Hitch Score
    static func hitchScore(hitchRatio: Float, hitchFramePercent: Float) -> Float {
        let ratioScore = severity(hitchRatio, good: 10, bad: 20, cap: 100)
        let framePercentScore = severity(hitchFramePercent, good: 10, bad: 20, cap: 100)
        return max(ratioScore, framePercentScore)   // worse of the two wins
    }

    // MARK: - Hang Score
    static func hangScore(hangCount: Int, longestHang: Millisecond) -> Float {
        let countScore = severity(Float(hangCount), good: 2, bad: 5, cap: 100)
        let durationScore = severity(Float(longestHang), good: 1500, bad: 2500, cap: 5000)
        return max(countScore, durationScore)
    }

    // MARK: - Final combined score

    /// - Parameter hitchRatio: a PERCENTAGE — see `hitchScore`'s doc for the Ms/s conversion callers must do first.
    static func grade(
        hitchRatio: Float,
        hitchFramePercent: Float,
        hangCount: Int,
        longestHang: Millisecond
    ) -> Int {
        let hScore = hitchScore(hitchRatio: hitchRatio, hitchFramePercent: hitchFramePercent)
        let gScore = hangScore(hangCount: hangCount, longestHang: longestHang)
        let badness = max(hScore, gScore)      // 0=best, 100=worst
        return Int(badness.rounded()).clamped(to: 0...100)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
#endif
