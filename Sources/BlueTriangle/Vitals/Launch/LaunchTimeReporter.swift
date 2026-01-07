//
//  LaunchTimeReporter.swift
//  
//
//  Created by Ashok Singh on 08/05/24.
//

import Foundation
import Combine

class LaunchTimeReporter : ObservableObject, @unchecked Sendable {
    
    private var cancellables = Set<AnyCancellable>()
    
    private let session: SessionProvider
    private let uploader: Uploading
    private let logger: Logging
    private let monitor : LaunchTimeMonitor
    init(using session: @escaping SessionProvider,
         uploader: Uploading,
         logger: Logging ,
         monitor : LaunchTimeMonitor) {
        self.monitor    = monitor
        self.logger     = logger
        self.uploader   = uploader
        self.session    = session
        self.start()
    }
    
    func start(){
        self.registerLaunchEvent()
        self.monitor.start()
        logger.info("Setup to receive launch event")
    }
    
    private func registerLaunchEvent() {
        self.monitor.launchEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { event in
                if let event = event{
                    switch event {
                    case .Cold(let date, let duration):
                        self.logger.info("Received cold launch at \(date)")
                        self.uploadReports(Constants.COLD_LAUNCH_PAGE_NAME, date, duration)
                    case .Hot(let date, let duration):
                        self.logger.info("Received hot launch at \(date)")
                        self.uploadReports(Constants.HOT_LAUNCH_PAGE_NAME, date, duration)
                    }
                }
            }.store(in: &self.cancellables)
    }
    
    func stop(){
        self.monitor.stop()
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
        self.cancellables.removeAll()
    }
    
    private func uploadReports(_ pageName : String, _ time : Date, _ duration : TimeInterval) {
        Task {
            do {
                guard let session = self.session() else {
                    return
                }
                
                print("Session uploadReports: \(session.sessionID)")
                let groupName = Constants.LAUNCH_TIME_PAGE_GROUP
                let trafficSegmentName = Constants.LAUNCH_TIME_TRAFFIC_SEGMENT
                let timeMS = time.timeIntervalSince1970.milliseconds
                let durationMS = duration.milliseconds
                
                let timerRequest = try await self.makeTimerRequest(session: session,
                                                                   time: timeMS,
                                                                   duration: durationMS,
                                                                   pageName: pageName,
                                                                   pageGroup: groupName,
                                                                   trafficSegment: trafficSegmentName)
                self.uploader.send(request: timerRequest)
                self.logger.info("Launch time reported at \(time)")
            } catch {
                self.logger.error(error.localizedDescription)
            }
        }
    }
    
    private func makeTimerRequest(session: Session, time : Millisecond, duration : Millisecond , pageName: String, pageGroup : String, trafficSegment : String) async throws -> Request {
        let page = Page(pageName: pageName , pageType: pageGroup)
        let timer = PageTimeInterval(startTime: time, interactiveTime: 0, pageTime: duration)
        let customMetrics = session.customVarriables(logger: logger)
        let nativeAppProperties: NativeAppProperties = await .nstEmpty
        let model = TimerRequest(session: session,
                                 page: page,
                                 timer: timer,
                                 customMetrics: customMetrics,
                                 trafficSegmentName: trafficSegment,
                                 nativeAppProperties: nativeAppProperties)
        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           model: model)
    }
    
    deinit {
        stop()
    }
}
