//
//  UnityVersion.swift
//  Unity Hub
//
//  Created by Ryan Boyer on 9/23/20.
//

import Foundation
import AppKit

struct UnityVersion {
    let version: String
    var major: Int
    var minor: Int
    var update: Int
    var channel: String
    var iteration: Int
    var installing: Bool
    var lts: Bool
    
    var path: String = ""

    // a: alpha
    // b: beta
    // f: final (official)
    // p: patch
    // c: china
    static let versionRegex = try! NSRegularExpression(pattern: #"^(\d+)\.(\d+)\.(\d+)([a|b|f|p|c])(\d+)"#)
    static let null: UnityVersion = UnityVersion("0.0.0a0")

    init(_ version: String, path: String = "") {
        self.version = version
        self.major = 0
        self.minor = 0
        self.update = 0
        self.channel = ""
        self.iteration = 0
        self.installing = false
        self.lts = false
        
        self.path = path

        UnityVersion.versionRegex.enumerateMatches(in: version, options: [], range: NSRange(0 ..< version.count)) { (match, _, stop) in
            guard let match = match else { return }
            
            if match.numberOfRanges == 6,
               let range1 = Range(match.range(at: 1), in: version),
               let range2 = Range(match.range(at: 2), in: version),
               let range3 = Range(match.range(at: 3), in: version),
               let range4 = Range(match.range(at: 4), in: version),
               let range5 = Range(match.range(at: 5), in: version) {
                self.major = Int(String(version[range1])) ?? 0
                self.minor = Int(String(version[range2])) ?? 0
                self.update = Int(String(version[range3])) ?? 0
                self.channel = String(version[range4])
                self.iteration = Int(String(version[range5])) ?? 0
                stop.pointee = true
            } else {
                print("UnityVersion \(version) is not a valid unity version")
            }
        }
        
        self.lts = isLts()
    }

    func getBranch() -> String {
        return "\(major).\(minor)"
    }

    func isOfficial() -> Bool {
        return isCorrectChannel(channelChar: "f");
    }

    func isAlpha() -> Bool {
        return isCorrectChannel(channelChar: "a");
    }

    func isBeta() -> Bool {
        return isCorrectChannel(channelChar: "b");
    }
    
    func isPrerelease() -> Bool {
        return isAlpha() || isBeta()
    }
    
    func isLts() -> Bool {
        return ((major == 2017 || major == 2018 || major == 2019) && minor == 4)
        || ((major == 2020 || major == 2021) && minor == 3)
    }
}

//MARK: - Validation
extension UnityVersion {
    func isCorrectChannel(channelChar: String) -> Bool {
        var correct: Bool = false
        UnityVersion.versionRegex.enumerateMatches(in: version, options: [], range: NSRange(0 ..< version.count)) { (match, _, stop) in
            guard let match = match else { return }
            correct = String(version[Range(match.range(at: 4), in: version) ?? (version.startIndex ..< version.endIndex)]) == channelChar
        }
        return correct
    }

    func isValid() -> Bool {
        var valid: Bool = false
        UnityVersion.versionRegex.enumerateMatches(in: version, options: [], range: NSRange(0 ..< version.count)) { (match, _, stop) in
            guard let match = match else { return }
            valid = match.numberOfRanges == 6
        }
        return valid
    }
    
    static func validateEditor(path: String) -> Bool {
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
            return false
        }
        
        return true
    }
}

//MARK: - Modules
extension UnityVersion {
    var moduleURL: URL {
        get { return URL(fileURLWithPath: "\(path)/modules.json") }
    }
    
    func getData() throws -> Data {
        return try Data(contentsOf: moduleURL)
    }
    
    func getModules() -> [ModuleJSON] {
        do {
            let data: Data = try getData()
            return try! JSONDecoder().decode([ModuleJSON].self, from: data)
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    
    func hasModule(module: UnityModule) -> Bool {
        return getModules().contains(where: { $0.id == module.id })
    }
    
    func getInstalledModules() -> [UnityModule] {
        var unityModules: [UnityModule] = []
                
        let modules: [ModuleJSON] = getModules()
        
        for module in modules {
            if module.selected, let unityModule = UnityModule(rawValue: module.id) {
                let index = unityModules.firstIndex(where: { $0.getPlatform() == unityModule.getPlatform() })
                if index == nil {
                    unityModules.append(unityModule)
                }
            }
        }
                
        return unityModules
    }
    
    func removeModule(module: UnityModule) {
        do {
            var modules: [ModuleJSON] = getModules()
                        
            for i in 0..<modules.count {
                if modules[i].selected, let m = UnityModule(rawValue: modules[i].id) {
                    if m == module, let installPath = module.getInstallPath() {
                        modules[i].selected = false
                                                
                        DispatchQueue.global(qos: .background).async {
                            let _ = shell("rm -rf \(path)\(installPath)")
                        }
                    }
                }
            }
            
            let toSave = try JSONEncoder().encode(modules)
            try toSave.write(to: moduleURL)
        } catch {
            print(error.localizedDescription)
        }
    }
}


//MARK: - Compare
extension UnityVersion: Comparable {
    func compare(other: UnityVersion) -> Int {
        if major == other.major {
            if minor == other.minor {
                if update == other.update {
                    if channel == other.channel {
                        if iteration == other.iteration {
                            return 0
                        }
                        return iteration > other.iteration ? 1 : -1
                    }
                    return channel > other.channel ? 1 : -1
                }
                return update > other.update ? 1 : -1
            }
            return minor > other.minor ? 1 : -1
        }
        return major > other.major ? 1 : -1
    }

    static func ==(lhs: UnityVersion, rhs: UnityVersion) -> Bool {
        return lhs.compare(other: rhs) == 0
    }
    
    static func <(lhs: UnityVersion, rhs: UnityVersion) -> Bool {
        return lhs.compare(other: rhs) == 1
    }
    
    static func >(lhs: UnityVersion, rhs: UnityVersion) -> Bool {
        return lhs.compare(other: rhs) == -1
    }
}

extension UnityVersion: Equatable {}

extension UnityVersion: Hashable {}

extension UnityVersion: Identifiable {
    var id: String {
        return version
    }
}
