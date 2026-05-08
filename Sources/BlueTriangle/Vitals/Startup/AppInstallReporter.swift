//
//  AppInstallReporter.swift
//  blue-triangle
//
//  Created by Ashok Singh on 06/05/26.
//

import Foundation

class AppInstallReporter {
    private let session: SessionProvider
    private let uploader: Uploading
    private let logger: Logging
    
    init(using session: @escaping SessionProvider,
         uploader: Uploading,
         logger: Logging) {
        self.logger     = logger
        self.uploader   = uploader
        self.session    = session
    }
    
    func reportAppInstallEvent(_ installTime: Date = Date()){
        self.uploadReports(BTTEvents.appInstall, installTime)
    }
}

extension AppInstallReporter {
    
    private func uploadReports(_ event : BTTEvent, _ installTime : Date = Date()) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let strongSelf = self, let session = strongSelf.session() else {
                    return
                }
                print("Session uploadReports: \(session.sessionID)")
                let groupName = Constants.APP_INSTALL_PAGE_GROUP
                let trafficSegmentName = Constants.APP_INSTALLTRAFFIC_SEGMENT
                let timeMS = Date().timeIntervalSince1970.milliseconds
                let installMS = installTime.timeIntervalSince1970.milliseconds
                let durationMS = Constants.minPgTm
                
                let timerRequest = try strongSelf.makeTimerRequest(session: session,
                                                                   time: timeMS,
                                                                   installTime: installMS,
                                                                   duration: durationMS,
                                                                   pageName: event.defaultPageName,
                                                                   pageGroup: groupName,
                                                                   trafficSegment: trafficSegmentName,
                                                                   event: event)
                strongSelf.uploader.send(request: timerRequest)
                strongSelf.logger.info("App Install time reported at \(installTime)")
            } catch {
                self?.logger.error(error.localizedDescription)
            }
        }
    }
    
    private func makeTimerRequest(session: Session, time : Millisecond, installTime : Millisecond, duration : Millisecond , pageName: String, pageGroup : String, trafficSegment : String, event : BTTEvent) throws -> Request {
        let page = Page(pageName: pageName , pageType: pageGroup)
        let timer = PageTimeInterval(startTime: time, interactiveTime: 0, pageTime: duration)
        var nativeAppProperties : NativeAppProperties? = .nstEmpty
        nativeAppProperties?.eventId = event.id
        nativeAppProperties?.installTime = installTime
        let customMetrics = session.customVarriables(logger: logger)
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
}
