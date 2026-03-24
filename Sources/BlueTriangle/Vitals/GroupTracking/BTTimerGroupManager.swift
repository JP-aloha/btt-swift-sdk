//
//  BTTimerGroupManager.swift
//  blue-triangle
//
//  Created by Ashok Singh on 28/05/25.
//

import Foundation

final class BTTimerGroupManager {
    private var activeGroups: [BTTimerGroup] = []
    private let logger: Logging
    private var lastTimerTime: Millisecond?
    private var lastActionTime = Date().timeIntervalSince1970.milliseconds
    private let lock = NSLock()

    init(logger: Logging) { self.logger = logger }

    func add(timer: BTTimer) {
        let target: BTTimerGroup? = lock.sync {
            if let open = activeGroups.last(where: { !$0.isClosed }) {
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
            let newGroup = startNewGroup(groupName: timer.getPageName(), hasForcedGroup: false, cause: .timeout, causeInterval: interval)
            newGroup.add(timer)
        }
    }

    func startGroupIfNeeded(_ groupName : String) {
        let decision: (shouldStart: Bool, cause: GroupingCause?, lastTimerSnap: Millisecond?) = lock.sync {
            if activeGroups.last(where: { !$0.isClosed }) == nil {
                return (true, .timeout, lastTimerTime)
            } else if let lt = lastTimerTime, lt < lastActionTime {
                return (true, .tap, lastTimerTime)
            }
            return (false, nil, lastTimerTime)
        }
        
        guard decision.shouldStart, let cause = decision.cause else { return }
        let interval = computeCauseInterval(from: decision.lastTimerSnap)
        _ = startNewGroup(groupName: groupName, hasForcedGroup: false, cause: cause, causeInterval: interval)
    }

    func setNewGroup(_ newGroup: String) {
        let interval = computeCauseInterval(from: lock.sync { lastTimerTime })
        _ = startNewGroup(groupName: newGroup, hasForcedGroup: true,  cause: .manual, causeInterval: interval)
    }

    func setGroupName(_ groupName: String) {
        let open = lock.sync { activeGroups.last(where: { !$0.hasGroupSubmitted }) }
        open?.setGroupName(groupName)
    }

    func refreshGroupName() {
        let open = lock.sync { activeGroups.last(where: { !$0.hasGroupSubmitted }) }
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
    private func startNewGroup(groupName: String, hasForcedGroup: Bool, cause: GroupingCause? = nil, causeInterval: Millisecond) -> BTTimerGroup {
        let openSnap: BTTimerGroup? = lock.sync { activeGroups.last(where: { !$0.hasGroupSubmitted }) }
        if let open = openSnap {
            logger.info("Forcefully submitted open group")
            open.forcefullyEndAllTimers()
        }

        let newGroup = BTTimerGroup(
            logger: logger,
            groupName: groupName,
            hasForcedGroup: hasForcedGroup,
            cause: cause,
            causeInterval: causeInterval,
            onGroupCompleted: { [weak self] group in
                self?.handleGroupCompletion(group)
            }
        )

        lock.sync {
            lastTimerTime = nil
            activeGroups.append(newGroup)
        }
        return newGroup
    }

    private func handleGroupCompletion(_ group: BTTimerGroup) {
        group.submit()
        lock.sync { activeGroups.removeAll { $0 === group } }
    }
}
