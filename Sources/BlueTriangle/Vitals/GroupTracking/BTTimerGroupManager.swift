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
            // Check if there's a closed but unsubmitted group
            let closedGroup: BTTimerGroup? = lock.sync {
                activeGroups.first(where: { $0.isClosed && !$0.hasGroupSubmitted })
            }
            
            if let closedGroup = closedGroup {
                // Check if the timer belongs to the same group
                if closedGroup.belongsToSameGroup(timer.getPageName()) {
                    // Forcefully add to the closed group if it's from the same group
                    closedGroup.add(timer)
                } else {
                    // Different group - forcefully submit the closed group and create new one
                    closedGroup.forcefullyEndAllTimers()
                    // Create new group for unique timer
                    let interval = computeCauseInterval(from: lock.sync { lastTimerTime })
                    let newGroup = startNewGroup(groupName: timer.getPageName(), hasForcedGroup: false, cause: .timeout, causeInterval: interval)
                    newGroup.add(timer)
                }
            } else {
                // No closed unsubmitted group exists - create new group
                let interval = computeCauseInterval(from: lock.sync { lastTimerTime })
                let newGroup = startNewGroup(groupName: timer.getPageName(), hasForcedGroup: false, cause: .timeout, causeInterval: interval)
                newGroup.add(timer)
            }
        }
    }

    func startGroupIfNeeded(_ groupName : String) {
        let decision: (shouldStart: Bool, cause: GroupingCause?, lastTimerSnap: Millisecond?, existingGroup: BTTimerGroup?) = lock.sync {
            // There's only one active group at a time (either open or closed but not submitted)
            let existingGroup = activeGroups.first(where: { !$0.hasGroupSubmitted })
            
            // If there's an existing group that's open
            if let group = existingGroup, !group.isClosed {
                // First check if this timer already belongs to the open group
                if group.belongsToSameGroup(groupName) {
                    // Same timer - always add to existing group, ignore tap detection
                    return (false, nil, lastTimerTime, nil)
                }
                
                // Different timer - check for tap detection
                if let lt = lastTimerTime, lt < lastActionTime {
                    // Tap detected with different timer - force start a new group
                    return (true, .tap, lastTimerTime, group)
                }
                
                // Different timer but no tap detected - add to existing open group
                return (false, nil, lastTimerTime, nil)
            }
            
            // If there's a closed but unsubmitted group, check if timer belongs to it
            if let closedGroup = existingGroup, closedGroup.isClosed, !closedGroup.hasGroupSubmitted {
                // Check if the timer belongs to the closed group
                if closedGroup.belongsToSameGroup(groupName) {
                    // Timer belongs to closed group - don't create new group, will add to closed group
                    return (false, nil, lastTimerTime, nil)
                } else {
                    // Timer doesn't belong to closed group - force submit closed group and create new one
                    return (true, .timeout, lastTimerTime, closedGroup)
                }
            }
            
            // No existing group - create new one
            return (true, .timeout, lastTimerTime, nil)
        }
        
        // If we don't need to start a new group, just return
        // Timers will be added to existing group via add(timer:) method
        if !decision.shouldStart {
            return
        }
        
        // Need to start a new group
        // First, forcefully submit the existing group if it exists (tap case or closed group doesn't match)
        if let existingGroup = decision.existingGroup {
            existingGroup.forcefullyEndAllTimers()
        }
        
        guard let cause = decision.cause else { return }
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

    /// Records a grouped screen's JS-thread hang on the group holding that screen's timer,
    /// since for grouped screens only the group timer's report is sent.
    func addJSHang(durationMs: Millisecond, for timer: BTTimer) {
        let groups = lock.sync { activeGroups }
        guard let group = groups.first(where: { $0.contains(timer) }) else {
            logger.debug("No unsubmitted group found for JS hang on \(timer.getPageName())")
            return
        }
        group.addJSHang(durationMs: durationMs)
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
