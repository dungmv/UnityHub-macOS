//
//  InstallModuleSheet.swift
//  Unity Hub S
//
//  Created by RyanBoyer on 3/4/21.
//

import SwiftUI

struct InstallModuleSheet: View {
    @EnvironmentObject var settings: AppState
    @Environment(\.presentationMode) var presentationMode

    @State var selectedVersion: UnityVersion
    
    @State private var selectedModules: [UnityModule: Bool] = [:]
    @State private var availableModules: [UnityModule] = []

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button("Cancel", action: closeMenu)
                    .padding(8)
                Spacer()
            }
            ModuleSheet(selectedModules: $selectedModules, availableModules: $availableModules)
                .padding(.horizontal)
            HStack {
                Spacer()
                Button("Install", action: installSelectedItems)
                    .disabled(selectedVersion == UnityVersion.null)
                    .padding(8)
            }
        }
        .onAppear {
            setupView()
        }
    }
    
    func setupView() {
        availableModules = UnityModule.getAvailableModules()
        let preinstalledModules = selectedVersion.getInstalledModules()
        availableModules.removeAll(where: { preinstalledModules.contains($0) })
        
        for module in availableModules {
            selectedModules[module] = false
        }
    }
    
    func closeMenu() {
        presentationMode.wrappedValue.dismiss()
    }
    
    func installSelectedItems() {
        print("starting install")
        
        var command = "\(settings.hubCommandBase) im --version \(selectedVersion.version)"
        
        for module in availableModules {
            if selectedModules[module] ?? false {
                command.append(" -m \(module.rawValue)")
            }
        }
        
        command.append(" --cm")
        
        selectedVersion.installing = true

        DispatchQueue.global(qos: .background).async {
            let string = shell(command)
            
            DispatchQueue.main.async {
                if string.contains("successfully downloaded") {
                    let index = settings.hub.versions.firstIndex(where: { $0.version == selectedVersion.version })!
                    if string.contains("successfully downloaded") {
                        var versionSet = settings.hub.versions[index]
                        versionSet.installing = false
                        settings.hub.versions[index] = versionSet
                    } else {
                        settings.hub.versions.remove(at: index)
                    }
                    settings.wrap()
                }
            }
        }
                
        closeMenu()
    }
}