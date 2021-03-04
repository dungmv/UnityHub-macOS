//
//  InstallsTab.swift
//  Unity Hub
//
//  Created by Ryan Boyer on 9/22/20.
//

import SwiftUI
import AppKit

struct InstalledVersionPanel: View {
    @EnvironmentObject var settings: HubSettings
    @State private var showInstaller: Bool = false
    @State private var showRemovalSheet: Bool = false
    @State private var installIndexToRemove: IndexSet?
    @State private var installToRemove: UnityVersion?
    @State private var installToRemoveName: String?

    var body: some View {
        List {
            ForEach(settings.versionsInstalled) { version in
                VStack {
                    InstalledVersionButton(version: version, action: {}, deleteAction: prepareForDeletion)
                    
                    if version != settings.versionsInstalled.last ?? UnityVersion.null {
                        ListDividerView()
                    }
                }
            }
            .onDelete(perform: prepareForDeletion)
        }
        .navigationTitle("Installs")
        .onAppear(perform: getAllVersions)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: locateVersion) {
                    Image(systemName: "folder")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button(action: installVersion) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showInstaller) {
            InstallSheet()
        }
        .alert(isPresented: $showRemovalSheet) {
            Alert(
                title: Text("Uninstall Unity \(installToRemoveName!)"),
                message: Text("Are you sure you want to uninstall Unity version \(installToRemoveName!)?"),
                primaryButton: .cancel(Text("Cancel")),
                secondaryButton: .destructive(Text("Uninstall")) { deleteItems(offsets: installIndexToRemove) }
            )
        }
    }
    
    func getAllVersions() {
        HubSettings.getAllVersions(settings: settings)
    }
    
    func locateVersion() {
        NSOpenPanel.openFolder { result in
            if case let .success(path) = result {
                if !HubSettings.customInstallPaths.contains(path) {
                    HubSettings.customInstallPaths.append(path)
                }
                
                getAllVersions()
            }
        }
    }
    
    func installVersion() {
        showInstaller.toggle()
    }
    
    func prepareForDeletion(at offsets: IndexSet) {
        installIndexToRemove = offsets
        installToRemoveName = settings.versionsInstalled[offsets.first!].version
        showRemovalSheet.toggle()
    }
    
    func prepareForDeletion(version: UnityVersion) {
        installToRemove = version
        installToRemoveName = version.version
        showRemovalSheet.toggle()
    }
    
    func deleteItems(offsets: IndexSet?) {
        if let index = offsets?.first {
            DispatchQueue.global(qos: .background).async {
                let _ = shell("rm -rf \(settings.versionsInstalled[index].path)")
            }
            settings.versionsInstalled.remove(at: index)
        } else {
            deleteItems(install: installToRemove)
        }
    }
    
    func deleteItems(install: UnityVersion?) {
        if let version = install {
            DispatchQueue.global(qos: .background).async {
                let _ = shell("rm -rf \(version.path)")
            }
            settings.versionsInstalled.removeAll(where: { $0.version == version.version })
        }
    }
}
