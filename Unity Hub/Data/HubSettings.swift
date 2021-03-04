//
//  HubSettings.swift
//  Unity Hub
//
//  Created by Ryan Boyer on 9/22/20.
//

import Foundation
import SwiftUI

class HubSettings: ObservableObject {
    static let defaultInstallLocation: String = #"/Applications/Unity/Hub/Editor"#
    static let defaultHubLocation: String = #"/Applications/Unity\ Hub.app"#
    static let hubSubFolder: String = #"/Contents/MacOS/Unity\ Hub"#
    
    static var hubCommandBase: String {
        return "\(hubLocation)\(hubSubFolder) -- --headless"
    }

    static var installLocation: String {
        get { return UserDefaults.standard.string(forKey: "installLocation") ?? HubSettings.defaultInstallLocation }
        set { UserDefaults.standard.setValue(newValue, forKey: "installLocation") }
    }
    
    static var customInstallPaths: [String] {
        get { return UserDefaults.standard.stringArray(forKey: "customInstallPaths") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "customInstallPaths") }
    }
    
    static var projectPaths: [String] {
        get { return UserDefaults.standard.stringArray(forKey: "projectPaths") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "projectPaths") }
    }
    
    static var hubLocation: String {
        get { return UserDefaults.standard.string(forKey: "hubLocation") ?? HubSettings.defaultHubLocation }
        set { UserDefaults.standard.set(newValue, forKey: "hubLocation") }
    }
    
    @Published var versionsInstalled: [UnityVersion] = []
    @Published var projects: [ProjectMetadata] = []
    
    var lastestVersionInstalled: UnityVersion? {
        if versionsInstalled.count == 0 {
            return nil
        }
        return versionsInstalled[0]
    }
    
    //TO DO: don't recalculate all
    static func getAllVersions(settings: HubSettings) {
        settings.versionsInstalled.removeAll()
        let fm = FileManager.default
        let path = HubSettings.installLocation

        do {
            let items = try fm.contentsOfDirectory(atPath: path)
            
            var isDir: ObjCBool = false

            for item in items {
                let path = "\(path)/\(item)"
                if fm.fileExists(atPath: path, isDirectory: &isDir) {
                    if isDir.boolValue && validateEditor(path: path) {
                        settings.versionsInstalled.append(UnityVersion(item, path: path))
                    }
                }
            }
            
            for i in 0 ..< HubSettings.customInstallPaths.count {
                if !fm.fileExists(atPath: HubSettings.customInstallPaths[i]) {
                    HubSettings.customInstallPaths.remove(at: i)
                    continue
                }
                let items = try fm.contentsOfDirectory(atPath: HubSettings.customInstallPaths[i])
                 
                if items.contains("Unity.app") {
                    if isDir.boolValue && validateEditor(path: HubSettings.customInstallPaths[i]) {
                        let components = HubSettings.customInstallPaths[i].components(separatedBy: "/")
                        settings.versionsInstalled.append(UnityVersion(components.last!, path: HubSettings.customInstallPaths[i]))
                    }
                } else {
                    HubSettings.customInstallPaths.remove(at: i)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        
        settings.versionsInstalled.sort {
            switch $0.compare(other: $1) {
            case 1: return true
            case -1: return false
            default: return false
            }
        }
    }
    
    static func getAllProjects(settings: HubSettings) {
        settings.projects.removeAll()
        let fm = FileManager.default
            
        for path in HubSettings.projectPaths {
            if !fm.fileExists(atPath: path) {
                HubSettings.projectPaths.removeAll(where: { $0 == path })
                continue
            }
            
            do {
                let items = try fm.contentsOfDirectory(atPath: path)
                if !items.contains("Assets") || !items.contains("ProjectSettings") {
                    continue
                }
                                
                settings.projects.append(ProjectMetadata(readFrom: path))
            } catch {
                print(error.localizedDescription)
            }
        }
        
        settings.projects.sort(by: { $0.name < $1.name })
        
        HubSettings.projectPaths.removeAll()
        for project in settings.projects {
            HubSettings.projectPaths.append(project.path)
        }
    }
    
    static func validateEditor(path: String/*, version: UnityVersion*/) -> Bool {
        /*if version.installing {
            return true
        }*/
        do {
            var format = PropertyListSerialization.PropertyListFormat.xml
            let plistData = try Data(contentsOf: URL(fileURLWithPath: "\(path)/Unity.app/Contents/Info.plist"))
            if let plistDictionary = try PropertyListSerialization.propertyList(from: plistData, options: .mutableContainersAndLeaves, format: &format) as? [String : AnyObject] {
                if let bundleID = plistDictionary["CFBundleIdentifier"] as? String {
                    if !bundleID.contains("com.unity3d.UnityEditor") {
                        print("Invalid bundle identifier")
                        return false
                    }
                } else {
                    print("No bundle identifier")
                    return false
                }
            } else {
                print("No valid plist")
                return false
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return true
    }
}
