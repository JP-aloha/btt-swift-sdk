//
//  ImageLoader.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 9/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import UIKit

actor ImageLoader: ImageLoading {
    private let session: URLSession
    private var taskCount: Int = 0
    private var onComplete: VoidCallback?

    init(session: URLSession) {
        self.session = session
    }

    func setCompletion(_ completion: VoidCallback?) {
        onComplete = completion
    }

    func load(_ url: URL) async throws -> UIImage? {
        incrementTasks()
        do {
            let data = try await session.btData(from: url).0
            decrementTasks()

            return UIImage(data: data)
        } catch {
            decrementTasks()
            throw error
        }
    }
}

private extension ImageLoader {
    func incrementTasks() {
        taskCount += 1
    }

    func decrementTasks() {
        guard taskCount > 0 else {
            return
        }
        taskCount -= 1

        if taskCount == 0 {
            onComplete?()
        }
    }
}
