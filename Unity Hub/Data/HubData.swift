//
//  HubData.swift
//  Unity Hub S
//
//  Created by RyanBoyer on 3/28/21.
//

import Foundation

struct HubData {
    static let fileName: String = "UnityHubS/HubData.json"
    static var fileLocation: URL { return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName, isDirectory: false) }
    
    var uuid: String
    
    var hubLocation: String
    var installLocation: String
    var projectLocation: String
    
    var customInstallLocations: [String]
    
    var useEmoji: Bool
    var usePins: Bool
    var showLocation: Bool
    var showFileSize: Bool
    var useSmallSidebar: Bool
    var showSidebarCount: Bool

    var defaultVersion: UnityVersion
    
    var projects: [ProjectData]
    var versions: [UnityVersion]
    
    init() {
        self = .init(uuid: UUID().uuidString, projects: [])
    }
    
    init(uuid: String, projects: [ProjectData]) {
        self.uuid = uuid

        self.hubLocation = #"/Applications/Unity\ Hub.app"#
        self.installLocation = #"/Applications/Unity/Hub/Editor"#
        self.projectLocation = #"~"#
        
        self.customInstallLocations = []
        
        self.useEmoji = true
        self.usePins = true
        self.showLocation = false
        self.showFileSize = false
        self.useSmallSidebar = false
        self.showSidebarCount = true

        self.defaultVersion = .null

        self.projects = projects
        self.versions = []
        
        wrap()
    }
    
    static func load() -> HubData {
        do {
            let data = try Data(contentsOf: fileLocation)
            let wrapper = HubDataWrapper(data: data)
            var hubData = wrapper.unwrap()
            hubData.wrap()
            _ = hubData.validate()
            return hubData
        } catch {
            print(error.localizedDescription)
            
            let defaultData = HubData()
            defaultData.wrap()
            return defaultData
        }
    }
    
    func wrap() {
        HubDataWrapper.wrap(self)
    }
}

extension HubData: Identifiable {
    var id: String { return uuid }
}

extension HubData: Validatable {
    mutating func validate() -> Bool {
        for var project in projects {
            if !project.validate() {
                projects.removeElement(project)
            } else {
                projects.setElement(project, where: { $0.path == project.path })
            }
        }
        for var version in versions {
            if !version.validate() {
                versions.removeElement(version)
            } else {
                versions.setElement(version, where: { $0.version == version.version })
            }
        }
        return true
    }
}