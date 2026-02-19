//
//  GlobleProperties.swift
//  blue-triangle
//
//  Created by Ashok Singh on 03/02/26.
//

import Foundation

final class GlobalProperties {
    
    private let storageKey = Constants.globalPropertiesStoreKey
    private var data: GlobalPropertiesData = .defaultValue

    init() {
        load()
    }

    func getGlobalProperties() -> GlobalPropertiesData {
        data
    }

    func updateAbTestID(_ id: String?) {
        guard let id else {
            data.abTestID = nil
            save()
            return
        }
        data.abTestID = String(id.prefix(512))
        save()
    }
    
    func updateDataCenter(_ dataCenter: String?) {
        data.dataCenter = dataCenter
        save()
    }
    
    func updateCampaignMedium(_ medium : String?) {
        data.campaignMedium = medium
        save()
    }
    
    func updateCampaignName(_ name : String?) {
        data.campaignName = name
        save()
    }
    
    func updateCampaignSource(_ source : String?) {
        data.campaignSource = source
        save()
    }
    
    func updateCustomCategory1(_ category1 : String?) {
        data.customCategory.cv6 = category1
        save()
    }
    
    func updateCustomCategory2(_ category2 : String?) {
        data.customCategory.cv7 = category2
        save()
    }
    
    func updateCustomCategory3(_ category3 : String?) {
        data.customCategory.cv8 = category3
        save()
    }
    
    func updateCustomCategory4(_ category4 : String?) {
        data.customCategory.cv9 = category4
        save()
    }
    
    func updateCustomCategory5(_ category5 : String?) {
        data.customCategory.cv10 = category5
        save()
    }

    private func load() {
        guard let saved = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(
                GlobalPropertiesData.self,
                from: saved
              )
        else {
            data = .defaultValue
            return
        }

        data = decoded
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(data) else {
            return
        }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }
}

struct CustomCategory: Codable, Sendable {
    var cv6: String?
    var cv7: String?
    var cv8: String?
    var cv9: String?
    var cv10: String?
}

struct GlobalPropertiesData: Codable, Sendable {
    var abTestID: String?
    var campaignMedium: String?
    var campaignName: String?
    var campaignSource: String?
    var dataCenter: String?
    var customCategory: CustomCategory

    static let defaultValue = GlobalPropertiesData(
        abTestID: BlueTriangle.configuration.abTestID,
        campaignMedium: BlueTriangle.configuration.campaignMedium,
        campaignName:  BlueTriangle.configuration.campaignName,
        campaignSource:  BlueTriangle.configuration.campaignSource,
        dataCenter:  BlueTriangle.configuration.dataCenter,
        customCategory: .init()
    )
}
