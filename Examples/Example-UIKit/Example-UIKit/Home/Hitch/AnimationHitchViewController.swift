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

    // Hitch Ratio % test control: a stepper to pick a target percentage, an "Exact" switch
    // (ON = hitch at exactly that percentage every tick; OFF = re-roll a random percentage in
    // [0, target] on every tick), and a start/stop button using whichever mode is selected.
    private let hitchRatioTestStack = UIStackView()
    private let hitchRatioStepper = UIStepper()
    private let hitchRatioValueLabel = UILabel()
    private let hitchRatioExactLabel = UILabel()
    private let hitchRatioExactSwitch = UISwitch()
    private let hitchRatioStartStopButton = UIButton(type: .system)

    // Hitch Frame % test control: two steppers driving hitchFramePercent directly —
    // durationStepper picks how many Ms each hitch blocks for, countStepper picks how many of
    // those hitches happen per second (hitchFramePercent = hitches/sec ÷ frames/sec × 100).
    private let hitchFrameTestStack = UIStackView()
    private let hitchFrameDurationStepper = UIStepper()
    private let hitchFrameDurationValueLabel = UILabel()
    private let hitchFrameCountStepper = UIStepper()
    private let hitchFrameCountValueLabel = UILabel()
    private let hitchFrameStartStopButton = UIButton(type: .system)

    private let hitchDurationsMs = [30, 50, 150, 250, 500]
    private let hangDurationsMs = [800, 900, 1000, 1100, 1200]

    private var buttonsByDuration: [Int: UIButton] = [:]
    private var hitchTimer: Timer?
    private var activeHitchButton: UIButton?

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
        let score = ResponsivenessGradeCalculator.grade(
            hitchesSeverity: stats.hitchesSeverity,
            hangCount: stats.hangCount,
            longestHang: stats.longestHang)
        let (color, label) = statusColorAndLabel(forScore: score)
        statusDotView.backgroundColor = color
        statusTextLabel.textColor = color
        statusTextLabel.text = "\(label) (\(score))"
    }

    private func statusColorAndLabel(forScore score: Int) -> (UIColor, String) {
        switch score {
        case 0...30:
            return (.systemGreen, "GOOD")
        case 31..<70:
            return (.systemOrange, "BAD")
        default:
            return (.systemRed, "WORST")
        }
    }

    // MARK: - Sections (Hitch / Hang)
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
        setupHitchRatioTestControl()
        setupHitchFrameTestControl()
        buttonsContainer.addArrangedSubview(hitchButtonStack)
        buttonsContainer.addArrangedSubview(hangButtonStack)
        buttonsContainer.addArrangedSubview(hitchRatioTestStack)
        buttonsContainer.addArrangedSubview(hitchFrameTestStack)
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

    // MARK: - Hitch Ratio % test control

    // Converts a target hitchTimePercent percentage into the hitch duration (ms) needed to produce
    // it when hitching once per second (excess ms and elapsed seconds grow at the same rate, so
    // hitchTimePercent == excess / 10): actual = target% * 10 + frame budget.
    private static func sleepMs(forTargetHitchRatioPercent percent: Int) -> Int {
        percent * 10 + 19
    }

    private func setupHitchRatioTestControl() {
        hitchRatioStepper.minimumValue = 0
        hitchRatioStepper.maximumValue = 100
        hitchRatioStepper.stepValue = 1
        hitchRatioStepper.value = 9
        hitchRatioStepper.addTarget(self, action: #selector(hitchRatioStepperChanged), for: .valueChanged)

        hitchRatioValueLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .medium)
        hitchRatioValueLabel.text = "9%"

        hitchRatioStartStopButton.setTitle("Start", for: .normal)
        hitchRatioStartStopButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        hitchRatioStartStopButton.backgroundColor = .secondarySystemBackground
        hitchRatioStartStopButton.layer.cornerRadius = 8
        hitchRatioStartStopButton.addTarget(self, action: #selector(hitchRatioStartStopTapped), for: .touchUpInside)
        hitchRatioStartStopButton.widthAnchor.constraint(equalToConstant: 64).isActive = true

        hitchRatioExactLabel.text = "Exact"
        hitchRatioExactLabel.font = .systemFont(ofSize: 13)
        hitchRatioExactSwitch.isOn = true

        // Flexible spacers on both sides of Start so it sits centered in the gap between the
        // value text and the Exact switch, rather than just adjacent to one side.
        let leftSpacer = UIView()
        let rightSpacer = UIView()
        for spacer in [leftSpacer, rightSpacer] {
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }

        // Single row — stepper, value, Start (centered), Exact switch — to save vertical space.
        let controlsRow = UIStackView(arrangedSubviews: [
            hitchRatioStepper, hitchRatioValueLabel, leftSpacer, hitchRatioStartStopButton, rightSpacer,
            hitchRatioExactLabel, hitchRatioExactSwitch
        ])
        controlsRow.axis = .horizontal
        controlsRow.spacing = 8
        controlsRow.alignment = .center

        hitchRatioTestStack.addArrangedSubview(controlsRow)
    }

    @objc
    private func hitchRatioStepperChanged() {
        hitchRatioValueLabel.text = "\(Int(hitchRatioStepper.value))%"
    }

    @objc
    private func hitchRatioStartStopTapped(_ sender: UIButton) {
        if activeHitchButton === sender {
            stopHitching()
            return
        }
        hitchTimer?.invalidate()
        activeHitchButton = sender
        updateButtonAppearance()
        // Reads the stepper/switch fresh on every tick (rather than capturing one fixed value at
        // start time) so moving the stepper or flipping "Exact" WHILE the test is running takes
        // effect on the very next hitch, instead of requiring a stop/restart.
        hitchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let targetPercent = Int(self.hitchRatioStepper.value)
            let percent = self.hitchRatioExactSwitch.isOn ? targetPercent : Int.random(in: 0...targetPercent)
            Thread.sleep(forTimeInterval: TimeInterval(Self.sleepMs(forTargetHitchRatioPercent: percent)) / 1000)
        }
    }

    // MARK: - Hitch Frame % test control

    private func setupHitchFrameTestControl() {
        hitchFrameDurationStepper.minimumValue = 0
        hitchFrameDurationStepper.maximumValue = 500
        hitchFrameDurationStepper.stepValue = 5
        hitchFrameDurationStepper.value = 30
        hitchFrameDurationStepper.addTarget(self, action: #selector(hitchFrameDurationStepperChanged), for: .valueChanged)

        hitchFrameDurationValueLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .medium)
        hitchFrameDurationValueLabel.text = "30Ms"

        hitchFrameStartStopButton.setTitle("Start", for: .normal)
        hitchFrameStartStopButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        hitchFrameStartStopButton.backgroundColor = .secondarySystemBackground
        hitchFrameStartStopButton.layer.cornerRadius = 8
        hitchFrameStartStopButton.addTarget(self, action: #selector(hitchFrameStartStopTapped), for: .touchUpInside)
        hitchFrameStartStopButton.widthAnchor.constraint(equalToConstant: 64).isActive = true

        hitchFrameCountStepper.minimumValue = 1
        hitchFrameCountStepper.maximumValue = 60
        hitchFrameCountStepper.stepValue = 1
        hitchFrameCountStepper.value = 5
        hitchFrameCountStepper.addTarget(self, action: #selector(hitchFrameCountStepperChanged), for: .valueChanged)

        hitchFrameCountValueLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .medium)
        hitchFrameCountValueLabel.text = "5/s"

        // Flexible spacers on both sides of Start so it sits centered between the two steppers.
        let leftSpacer = UIView()
        let rightSpacer = UIView()
        for spacer in [leftSpacer, rightSpacer] {
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }

        // Single row — duration stepper, Start (centered), count stepper — to save vertical space.
        let controlsRow = UIStackView(arrangedSubviews: [
            hitchFrameDurationStepper, hitchFrameDurationValueLabel, leftSpacer, hitchFrameStartStopButton, rightSpacer,
            hitchFrameCountValueLabel, hitchFrameCountStepper
        ])
        controlsRow.axis = .horizontal
        controlsRow.spacing = 8
        controlsRow.alignment = .center

        hitchFrameTestStack.addArrangedSubview(controlsRow)
    }

    @objc
    private func hitchFrameDurationStepperChanged() {
        hitchFrameDurationValueLabel.text = "\(Int(hitchFrameDurationStepper.value))Ms"
        restartHitchFrameTimerIfActive()
    }

    @objc
    private func hitchFrameCountStepperChanged() {
        hitchFrameCountValueLabel.text = "\(Int(hitchFrameCountStepper.value))/s"
        restartHitchFrameTimerIfActive()
    }

    @objc
    private func hitchFrameStartStopTapped(_ sender: UIButton) {
        if activeHitchButton === sender {
            stopHitching()
            return
        }
        activeHitchButton = sender
        updateButtonAppearance()
        startHitchFrameTimer()
    }

    // The timer's own fireInterval can't be changed once scheduled, so — unlike the Hitch Ratio
    // control, which can read its stepper live inside a fixed-interval timer — changing the count
    // stepper here requires tearing down and rescheduling a new Timer at the new interval.
    private func restartHitchFrameTimerIfActive() {
        guard activeHitchButton === hitchFrameStartStopButton else { return }
        startHitchFrameTimer()
    }

    private func startHitchFrameTimer() {
        hitchTimer?.invalidate()
        let count = max(Int(hitchFrameCountStepper.value), 1)
        let durationMs = Int(hitchFrameDurationStepper.value)
        hitchTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(count), repeats: true) { _ in
            Thread.sleep(forTimeInterval: TimeInterval(durationMs) / 1000)
        }
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
        Longest Hitch: \(stats.longestHitch)Ms
        """
        hangStatsLabel.text = """
        Hang Count: \(stats.hangCount)
        Total Hang Duration: \(secondsString(fromMs: stats.totalHangDuration))
        Longest Hang: \(secondsString(fromMs: stats.longestHang))
        Total Frame Count: \(stats.totalFrameCount)
        """
    }

    private func secondsString(fromMs ms: Millisecond) -> String {
        String(format: "%.2fSec", Double(ms) / 1000)
    }

    // MARK: - Hitch/hang buttons

    @objc
    private func durationButtonTapped(_ sender: UIButton) {
        toggleHitching(button: sender, intervalSeconds: 1.0, sleepMs: sender.tag)
    }

    // Shared by the fixed-duration buttons and the "Simulate %" buttons — only one hitch pattern
    // should run at a time, since running two concurrently would compound and make neither
    // calibration meaningful.
    private func toggleHitching(button: UIButton, intervalSeconds: TimeInterval, sleepMs: Int) {
        if activeHitchButton === button {
            stopHitching()
        } else {
            startHitching(button: button, intervalSeconds: intervalSeconds, sleepMs: sleepMs)
        }
    }

    private func startHitching(button: UIButton, intervalSeconds: TimeInterval, sleepMs: Int) {
        hitchTimer?.invalidate()
        activeHitchButton = button
        updateButtonAppearance()
        hitchTimer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { _ in
            Thread.sleep(forTimeInterval: TimeInterval(sleepMs) / 1000)
        }
    }

    // Same start/stop toggle as toggleHitching, but re-rolls a fresh random sleep duration on
    // every tick instead of using one fixed value for the whole run.
    private func toggleRandomHitching(button: UIButton, intervalSeconds: TimeInterval, targetPercentRange: ClosedRange<Int>) {
        if activeHitchButton === button {
            stopHitching()
        } else {
            hitchTimer?.invalidate()
            activeHitchButton = button
            updateButtonAppearance()
            hitchTimer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { _ in
                let targetPercent = Int.random(in: targetPercentRange)
                let sleepMs = Self.sleepMs(forTargetHitchRatioPercent: targetPercent)
                Thread.sleep(forTimeInterval: TimeInterval(sleepMs) / 1000)
            }
        }
    }

    private func stopHitching() {
        hitchTimer?.invalidate()
        hitchTimer = nil
        activeHitchButton = nil
        updateButtonAppearance()
    }

    private func updateButtonAppearance() {
        let allHitchButtons = Array(buttonsByDuration.values) + [hitchRatioStartStopButton, hitchFrameStartStopButton]
        for button in allHitchButtons {
            button.backgroundColor = (button === activeHitchButton)
                ? .systemRed.withAlphaComponent(0.3)
                : .secondarySystemBackground
        }
    }
}

#endif
