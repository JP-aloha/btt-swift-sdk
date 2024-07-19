//
//  LaunchTimeReporter.swift
//  
//
//  Created by Ashok Singh on 08/05/24.
//

import Foundation
import Combine

class LaunchTimeReporter : ObservableObject {
    
    static let COLD_LAUNCH_PAGE_NAME = "ColdLaunchTime"
    static let HOT_LAUNCH_PAGE_NAME = "HotLaunchTime"
    static let LAUNCH_TIME_PAGE_GROUP = "LaunchTime"
    private var cancellables = Set<AnyCancellable>()
    
    private let session: Session
    private let uploader: Uploading
    private let logger: Logging
    private let monitor : LaunchTimeMonitor
    
    init(session: Session,
         uploader: Uploading,
         logger: Logging ,
         monitor : LaunchTimeMonitor) {
        self.monitor    = monitor
        self.logger     = logger
        self.uploader   = uploader
        self.session    = session
        self.start()
    }

    private func start(){

        self.monitor.launchEventPubliser
            .receive(on: DispatchQueue.main)
            .sink { event in
                if let event = event{
                    switch event {
                    case .Cold(let date, let duration):
                        self.logger.info("Received cold launch at \(date)")
                        self.uploadReports(LaunchTimeReporter.COLD_LAUNCH_PAGE_NAME, date, duration)
                    case .Hot(let date, let duration):
                        self.logger.info("Received hot launch at \(date)")
                        self.uploadReports(LaunchTimeReporter.HOT_LAUNCH_PAGE_NAME, date, duration)
                    }
                }
            }.store(in: &self.cancellables)
        
        logger.info("Setup to receive launch event")
    }
    
    private func uploadReports(_ pageName : String, _ time : Date, _ duration : TimeInterval) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let strongSelf = self else {
                    return
                }
                
                let groupName = LaunchTimeReporter.LAUNCH_TIME_PAGE_GROUP
                let timeMS = time.timeIntervalSince1970.milliseconds
                let durationMS = duration.milliseconds
                
                let timerRequest = try strongSelf.makeTimerRequest(session: strongSelf.session,
                                                                   time: timeMS,
                                                                   duration: durationMS,
                                                                   pageName: pageName,
                                                                   pageGroup: groupName)
                strongSelf.uploader.send(request: timerRequest)
                strongSelf.logger.info("Launch time reported at \(time)")
            } catch {
                self?.logger.error(error.localizedDescription)
            }
        }
    }
    
    private func makeTimerRequest(session: Session, time : Millisecond, duration : Millisecond , pageName: String, pageGroup : String) throws -> Request {
        let page = Page(pageName: pageName , pageType: pageGroup)
        let timer = PageTimeInterval(startTime: time, interactiveTime: 0, pageTime: duration)
        let model = TimerRequest(session: session,
                                 page: page,
                                 timer: timer)
       print("TypeLaunch")
        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           model: model)
    }
}
