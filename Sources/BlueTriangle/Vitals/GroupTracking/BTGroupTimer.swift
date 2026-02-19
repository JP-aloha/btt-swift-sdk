//
//  BTGroupTimer.swift
//  blue-triangle
//
//  Created by Ashok Singh on 28/05/25.
//

import Foundation

enum GroupingCause {
    case manual
    case timeout
    case tap

    var description: String {
        switch self {
        case .manual:  return "manual"
        case .timeout: return "timeout"
        case .tap:     return "tap"
        }
    }
}

final class BTTimerGroup {
    private var timers: Set<BTTimer> = []
    private var idleTimer: Timer?
    private var groupTimer: BTTimer
    private let logger: Logging
    private var isGroupClosed = false
    private var hasSubmitted = false
    private var hasForcedGroup = false
    private var groupName: String?
    private let lock = NSLock()
    private let onGroupCompleted: (BTTimerGroup) -> Void
    private let actionTracker = BTActionTracker()
    private var groupingCause: GroupingCause?
    private var causeInterval: Millisecond = 0
    private let groupingIdleTime = BlueTriangle.configuration.groupingIdleTime

    var isClosed: Bool { lock.sync { isGroupClosed } }
    var hasGroupSubmitted: Bool { lock.sync { hasSubmitted } }

    init(
        logger: Logging,
        groupName: String,
        hasForcedGroup: Bool = false,
        cause: GroupingCause? = nil,
        causeInterval: Millisecond = 0,
        onGroupCompleted: @escaping (BTTimerGroup) -> Void
    ) {
        self.logger = logger
        self.hasForcedGroup = hasForcedGroup
        self.onGroupCompleted = onGroupCompleted
        self.groupingCause = cause
        self.causeInterval = causeInterval
        self.groupName = hasForcedGroup ? groupName : nil
        let trafficSegment = BlueTriangle.trafficSegmentName == Constants.defaultTraficSegment ? Constants.SCREEN_TRACKING_TRAFFIC_SEGMENT : BlueTriangle.trafficSegmentName
        let pageType = BlueTriangle.pageType == Constants.defaultPageType ? Constants.SCREEN_TRACKING_PAGE_TYPE : BlueTriangle.pageType
        self.groupTimer = BlueTriangle.startTimer(page: Page(pageName: groupName, pageType: pageType, trafficSegment: trafficSegment), isGroupedTimer: true)

        updatePageNameFromSnapshot()
        scheduleIdleTimer()
    }

    deinit { invalidateIdleTimerOnMain() }

    // MARK: Public API

    func add(_ timer: BTTimer) {
        observe(timer)

        let shouldUpdateNameAndReset: Bool = lock.sync {
            guard !isGroupClosed else { return false }
            timers.insert(timer)
            return true
        }

        if shouldUpdateNameAndReset {
            updatePageNameFromSnapshot()
            scheduleIdleTimer()
        }
    }

    func setGroupCause(_ cause: GroupingCause) {
        lock.sync { self.groupingCause = cause }
    }

    func setGroupName(_ groupName: String) {
        lock.sync { self.groupName = groupName }
        updatePageNameFromSnapshot()
    }

    func refreshGroupName() { updatePageNameFromSnapshot() }

    func recordActions(_ action: UserAction) {
        // actionTracker assumed thread-safe or queue-backed
        actionTracker.recordAction(action)
    }

    func submit() {
        // Snapshot all data needed for submission
        let snap = lock.sync { SubmissionSnapshot.make(from: self) }

        guard !snap.timers.isEmpty else {
            snap.groupTimer.end()
            return
        }

        var pgtm: Millisecond = 0
        var pages = [String]()
        var screenType: ScreenType?
        var intervals = [(Millisecond, Millisecond)]()
        let hasSampleRate =  BlueTriangle.sessionData()?.shouldNetworkCapture ?? false

        for timer in snap.timers {
            let maxLoadTime = max(timer.nativeAppProperties.loadTime, Constants.minPgTm)
            pgtm += maxLoadTime
            pages.append(timer.getPageName())
            if screenType == nil { screenType = timer.nativeAppProperties.screenType }
            intervals.append((timer.nativeAppProperties.loadStartTime, timer.nativeAppProperties.loadEndTime))
        }

        let unionPgTm = max(totalPgTmUnion(intervals), Constants.minPgTm)
        logger.info("Union pgTm of intervals \(intervals): \(unionPgTm), Sum of pgTm : \(pgtm)")

        let native = NativeAppProperties(
            fullTime: snap.fullTime,
            loadTime: pgtm,
            loadStartTime: 0,
            loadEndTime: 0,
            maxMainThreadUsage: snap.maxMainThreadTask,
            screenType: screenType,
            offline: snap.networkReport?.offline ?? 0,
            wifi: snap.networkReport?.wifi ?? 0,
            cellular: snap.networkReport?.cellular ?? 0,
            ethernet: snap.networkReport?.ethernet ?? 0,
            other: snap.networkReport?.other ?? 0,
            grouped: true,
            groupingCause: snap.groupingCause?.description,
            groupingCauseInterval: snap.causeInterval,
            netState: snap.networkReport?.netState ?? "",
            netStateSource: snap.networkReport?.netSource ?? "",
            childViews: hasSampleRate ? pages : []
        )

        snap.groupTimer.nativeAppProperties = native
        snap.groupTimer.pageTimeBuilder = { unionPgTm }

        BlueTriangle.endTimer(snap.groupTimer)
        self.submitChildsWcdRequests()
        logger.info("Submitting group result: \(snap.timers.count) timers with name: \(snap.pageName)")
    }

    func forcefullyEndAllTimers() {
        let timersSnap = lock.sync { Array(self.timers) }
        closeGroup() // will snapshot & submit if ready

        for timer in timersSnap where !timer.hasEnded {
            let prop = timer.nativeAppProperties
            let full: Millisecond = (prop.loadTime > 0) ? (timeInterval.milliseconds - prop.loadStartTime) : 0
            timer.nativeAppProperties = NativeAppProperties(
                fullTime: full,
                loadTime: prop.loadTime,
                loadStartTime: prop.loadStartTime,
                loadEndTime: prop.loadEndTime,
                maxMainThreadUsage: prop.maxMainThreadUsage,
                screenType: prop.screenType,
                offline: prop.offline,
                wifi: prop.wifi,
                cellular: prop.cellular,
                ethernet: prop.ethernet,
                other: prop.other,
                grouped: true,
                netState: prop.netState,
                netStateSource: prop.netStateSource
            )
            timer.end()
        }
    }

    // MARK: Lifecycle helpers (no nested locks)

    private func closeGroup() {
        let didClose: Bool = lock.sync {
            guard !isGroupClosed else { return false }
            isGroupClosed = true
            return true
        }

        if didClose {
            logger.info("Group closed due to idle.")
            updatePageNameFromSnapshot()
            invalidateIdleTimerOnMain()
        }

        trySubmitGroup()
    }

    private func trySubmitGroup() {
        let shouldFireCompletion: Bool = lock.sync {
            guard isGroupClosed, !hasSubmitted else { return false }
            let allEnded = timers.allSatisfy { $0.hasEnded }
            if allEnded {
                hasSubmitted = true
                return true
            }
            return false
        }

        if shouldFireCompletion {
            onGroupCompleted(self)
        }
    }

    private func scheduleIdleTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.idleTimer?.invalidate()
            let t = Timer(timeInterval: self.groupingIdleTime, repeats: false) { [weak self] _ in
                self?.closeGroup()
            }
            self.idleTimer = t
            RunLoop.main.add(t, forMode: .common)
        }
    }

    private func invalidateIdleTimerOnMain() {
        DispatchQueue.main.async { [weak self] in
            self?.idleTimer?.invalidate()
            self?.idleTimer = nil
        }
    }

    // MARK: Observing
    private func observe(_ timer: BTTimer) {
        timer.onEnd = { [weak self] in
            self?.timerDidEnd()
        }
    }

    private func timerDidEnd() {
        trySubmitGroup()
    }
    
    private func updatePageNameFromSnapshot() {
        lock.sync {
            let pairs: [(String, String)] = Array(timers).map { timer in
                (timer.getPageName(), timer.getPageTitle())
            }
            let newName: String
            if !hasForcedGroup {
                newName = groupName ?? extractLastPageName(from: pairs)
                groupTimer.setPageName(newName)
            } else {
                newName = groupTimer.getPageName()
            }
            let traficSegment = BlueTriangle.trafficSegmentName == Constants.defaultTraficSegment ? Constants.SCREEN_TRACKING_TRAFFIC_SEGMENT : BlueTriangle.trafficSegmentName
            groupTimer.setTrafficSegment(traficSegment)
            BlueTriangle.updateCaptureRequest(
                pageName: newName,
                startTime: groupTimer.startTime.milliseconds
            )
        }
    }

    private func submitActionsWcdRequests() {
        let name = groupTimer.getPageName()
        let start = groupTimer.startTime
        Task { await actionTracker.uploadActions(name, pageStartTime: start) }
    }

    private func submitChildsWcdRequests() {
        let pageName = groupTimer.getPageName()
        let pageType = groupTimer.page.pageType
        let trafficSegment = groupTimer.page.trafficSegment
        let groupStart = groupTimer.startTime.milliseconds
        let timersSnap = lock.sync { Array(self.timers) }

        Task {
            await BlueTriangle.startGroupTimerRequest(page: Page(pageName: pageName, pageType: pageType, trafficSegment: trafficSegment), startTime: groupStart)
            for t in timersSnap {
                await self.submitSingleRequest(groupTimer: self.groupTimer, timer: t, group: pageName)
            }
            await BlueTriangle.uploadGroupedViewCollectedRequests()
        }
    }

    private func submitSingleRequest(groupTimer: BTTimer, timer: BTTimer, group: String) async {
        let prop = timer.nativeAppProperties
        let loadStartTime = prop.loadStartTime > 0 ? prop.loadStartTime : timer.startTime.milliseconds
        let loadEndTime = prop.loadEndTime > 0 ? prop.loadEndTime : (loadStartTime + Constants.minPgTm)
        let actualLoadEndTime = (loadEndTime - loadStartTime) < Constants.minPgTm ? (loadStartTime + Constants.minPgTm) : loadEndTime
        let minCPU = timer.performanceReport?.minCPU ?? 0
        let maxCPU = timer.performanceReport?.maxCPU ?? 0
        let avgCPU = timer.performanceReport?.avgCPU ?? 0
        let minMemory = timer.performanceReport?.minMemory ?? 0
        let maxMemory = timer.performanceReport?.maxMemory ?? 0
        let avgMemory = timer.performanceReport?.avgMemory ?? 0

        let native = NativeAppProperties(
            fullTime: prop.fullTime,
            loadTime: prop.loadTime,
            loadStartTime: prop.loadStartTime,
            loadEndTime: prop.loadEndTime,
            maxMainThreadUsage: prop.maxMainThreadUsage,
            screenType: prop.screenType,
            offline: prop.offline,
            wifi: prop.wifi,
            cellular: prop.cellular,
            ethernet: prop.ethernet,
            other: prop.other,
            grouped: true,
            netState: prop.netState,
            netStateSource: prop.netStateSource
        )

        await BlueTriangle.captureGroupRequest(
            startTime: loadStartTime,
            endTime: actualLoadEndTime,
            groupStartTime: groupTimer.startTime.milliseconds,
            response: CustomPageResponse(file: timer.getPageName(),
                                         url: timer.getPageName(),
                                         domain: group,
                                         native: native,
                                         minCPU: minCPU,
                                         maxCPU: maxCPU,
                                         avgCPU: avgCPU,
                                         minMemory: minMemory,
                                         maxMemory: maxMemory,
                                         avgMemory: avgMemory)
        )
    }

    // MARK: Utilities
    func totalPgTmUnion(_ intervals: [(Millisecond, Millisecond)]) -> Millisecond {
        let valid = intervals.filter { $0.1 > $0.0 }
        guard !valid.isEmpty else { return 0 }
        let sorted = valid.sorted { $0.0 < $1.0 }
        var total: Millisecond = 0
        var (currentStart, currentEnd) = sorted[0]

        for (s, e) in sorted.dropFirst() {
            if s > currentEnd {
                total += currentEnd - currentStart
                currentStart = s
                currentEnd = e
            } else {
                if e > currentEnd { currentEnd = e }
            }
        }
        total += currentEnd - currentStart
        return total
    }
    
    private func extractLastPageName(from titles: [(String, String)]) -> String {
        if let lastWithTitle = titles.last(where: { !$0.1.isEmpty }) { return lastWithTitle.1 }
        return titles.last?.0 ?? ""
    }

    private var timeInterval: TimeInterval { Date().timeIntervalSince1970 }

    // Snapshot type for submit()
    private struct SubmissionSnapshot {
        let timers: [BTTimer]
        let groupTimer: BTTimer
        let networkReport: NetworkReport?
        let maxMainThreadTask: Millisecond
        let groupingCause: GroupingCause?
        let causeInterval: Millisecond
        let pageName: String
        let fullTime: Millisecond

        static func make(from g: BTTimerGroup) -> SubmissionSnapshot {
            let timersArr = Array(g.timers)
            let gt = g.groupTimer
            return .init(
                timers: timersArr,
                groupTimer: gt,
                networkReport: gt.networkReport,
                maxMainThreadTask: gt.performanceReport?.maxMainThreadTask.milliseconds ?? 0,
                groupingCause: g.groupingCause,
                causeInterval: g.causeInterval,
                pageName: gt.getPageName(),
                fullTime: g.timeInterval.milliseconds - gt.startTime.milliseconds
            )
        }
    }
}

struct CustomPageResponse{
    let file: String?
    let url: String?
    let domain: String?
    let native: NativeAppProperties?
    let minCPU: Float?
    let maxCPU: Float?
    let avgCPU: Float?
    let minMemory: UInt64?
    let maxMemory: UInt64?
    let avgMemory: UInt64?
}
