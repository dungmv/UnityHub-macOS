//
//  InstallsTab.swift
//  Unity Hub
//
//  Created by Ryan Boyer on 9/22/20.
//

import SwiftUI
import AppKit

struct InstallsTab: View {
    @EnvironmentObject var settings: HubSettings
    
    var body: some View {
        List {
            ForEach(settings.versionsInstalled, id: \.self.0) { version in
                UnityVersionButton(path: version.0, version: version.1)
            }
        }
        .navigationTitle("Installs")
        .onAppear(perform: getAllVersions)
        .onDisappear(perform: { settings.versionsInstalled.removeAll() })
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: locateVersion) {
                    Image(systemName: "magnifyingglass")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button(action: installVersion) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    func getAllVersions() {
        let fm = FileManager.default
        let path = settings.installLocation

        do {
            let items = try fm.contentsOfDirectory(atPath: path)
            
            var isDir: ObjCBool = false

            for item in items {
                let path = "\(path)/\(item)"
                if fm.fileExists(atPath: path, isDirectory: &isDir) {
                    if isDir.boolValue {
                        settings.versionsInstalled.append((path, item))
                    }
                }
            }
            
            for i in 0 ..< settings.customInstallPaths.count {
                if !fm.fileExists(atPath: settings.customInstallPaths[i]) {
                    settings.customInstallPaths.remove(at: i)
                    continue
                }
                let items = try fm.contentsOfDirectory(atPath: settings.customInstallPaths[i])
                 
                if items.contains("Unity.app") {
                    if isDir.boolValue {
                        let components = settings.customInstallPaths[i].components(separatedBy: "/")
                        settings.versionsInstalled.append((settings.customInstallPaths[i], components.last!))
                    }
                } else {
                    settings.customInstallPaths.remove(at: i)
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print(error.localizedDescription)
        }
    }
    
    func locateVersion() {
        NSOpenPanel.openFolder { result in
            if case let .success(path) = result {
                if !settings.customInstallPaths.contains(path) {
                    settings.customInstallPaths.append(path)
                }
                
                settings.versionsInstalled.removeAll()
                getAllVersions()
            }
        }
    }
    
    func installVersion() {
        
    }
}

struct InstallsTab_Previews: PreviewProvider {
    static var previews: some View {
        InstallsTab()
    }
}