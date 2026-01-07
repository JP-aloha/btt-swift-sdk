//
//  BTTimerGroupManager.swift
//  blue-triangle
//
//  Created by Ashok Singh on 28/05/25.
//

import Foundation

actor BTTimerGroupManager {
    private var activeGroups: Set<BTTimerGroup> = []
    private let logger: Logging
    private var lastTimerTime: Millisecond?
    private var lastActionTime = Date().timeIntervalSince1970.milliseconds
    private let lock = NSLock()

    init(logger: Logging) { self.logger = logger }

    func add(timer: BTTimer) async {
        let target: BTTimerGroup? = lock.sync {
            if let open = Array(activeGroups).last(where: { !$0.isClosed }) {
                lastTimerTime = timer.startTime.milliseconds
                return open
            } else {
                lastTimerTime = timer.startTime.milliseconds
                return nil
            }
        }

        if let tg = target {
            tg.add(timer)
        } else {
            let interval = computeCauseInterval(from: lock.sync { lastTimerTime })
            let newGroup = await startNewGroup(cause: .timeout, causeInterval: interval, time: timer.startTime)
            newGroup.add(timer)
        }
    }

    func startGroupIfNeeded(_ time : TimeInterval) async {
        let decision: (shouldStart: Bool, cause: GroupingCause?, lastTimerSnap: Millisecond?) = lock.sync {
            if Array(activeGroups).last(where: { !$0.isClosed }) == nil {
                return (true, .timeout, lastTimerTime)
            } else if let lt = lastTimerTime, lt < lastActionTime {
                return (true, .tap, lastTimerTime)
            }
            return (false, nil, lastTimerTime)
        }
        
        guard decision.shouldStart, let cause = decision.cause else { return }
        let interval = computeCauseInterval(from: decision.lastTimerSnap)
        _ = await startNewGroup(cause: cause, causeInterval: interval, time: time)
    }

    func setNewGroup(_ newGroup: String, _ time : TimeInterval) async {
        let interval = computeCauseInterval(from: lock.sync { lastTimerTime })
        _ = await startNewGroup(groupName: newGroup, cause: .manual, causeInterval: interval, time: time)
    }

    func setGroupName(_ groupName: String) {
        let open = lock.sync { Array(activeGroups).last(where: { !$0.hasGroupSubmitted }) }
        open?.setGroupName(groupName)
    }

    func recordAction(_ action: UserAction) {
        let open = lock.sync { Array(activeGroups).last(where: { !$0.hasGroupSubmitted }) }
        open?.recordActions(action)
    }

    func refreshGroupName() {
        let open = lock.sync { Array(activeGroups).last(where: { !$0.hasGroupSubmitted }) }
        open?.refreshGroupName()
    }

    func setLastAction(_ time: Date) {
        if BlueTriangle.configuration.enableGroupingTapDetection {
            lock.sync { self.lastActionTime = time.timeIntervalSince1970.milliseconds }
        }
    }

    // MARK: – Internals

    private func computeCauseInterval(from last: Millisecond?) -> Millisecond {
        guard let last = last else { return 0 }
        let now = Date().timeIntervalSince1970.milliseconds
        return max(0, now - last)
    }

    /// Starts a new group. No nested locks: we snapshot the open group under lock,
    /// act on it outside, then append the new group under lock.
    @discardableResult
    private func startNewGroup(groupName: String? = nil, cause: GroupingCause? = nil, causeInterval: Millisecond, time : TimeInterval = Date().timeIntervalSince1970) async -> BTTimerGroup {
        let openSnap: BTTimerGroup? = lock.sync { Array(activeGroups).last(where: { !$0.hasGroupSubmitted }) }
        if let open = openSnap {
            logger.info("Forcefully submitted open group")
            await open.forcefullyEndAllTimers()
        }

        let newGroup = BTTimerGroup(
            logger: logger,
            groupName: groupName,
            cause: cause,
            causeInterval: causeInterval,
            time: time,
            onGroupCompleted: { [weak self] group in
                Task { [weak self] in
                    guard let self else { return }
                    await self.handleGroupCompletion(group)
                }
            }
        )

        lock.sync {
            lastTimerTime = nil
            activeGroups.insert(newGroup)
        }
        return newGroup
    }

    private func handleGroupCompletion(_ group: BTTimerGroup) async {
        await group.submit()
        lock.sync { activeGroups.remove(group)}
    }
}

