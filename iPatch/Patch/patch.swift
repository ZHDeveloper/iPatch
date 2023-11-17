//
//  patch.swift
//  iPatch
//
//  Created by Eamon Tracey on 3/25/21.
//

import Foundation

let bundle = Bundle.main

func patch(ipa ipaURL: URL, withDebOrDylib debOrDylibURL: [URL], andDisplayName displayName: String, injectSubstrate: Bool) {
    guard !debOrDylibURL.isEmpty else { return }
    try? fileManager.removeItem(at: tmp)
    try? fileManager.createDirectory(at: tmp, withIntermediateDirectories: false, attributes: .none)
    let appURL = extractAppFromIPA(ipaURL)
    let binaryURL = extractBinaryFromApp(appURL)
    let dylibs = debOrDylibURL.map {
        if $0.pathExtension == "deb" {
            return extractDylibFromDeb($0)
        }
        else {
            return $0
        }
    }
    insertDylibsDir(intoApp: appURL, withDylib: dylibs, injectSubstrate: injectSubstrate)
    dylibs.forEach {
        if !patch_binary_with_dylib(binaryURL.path, $0.lastPathComponent, injectSubstrate) {
            fatalExit("Unable to patch app binary at \(binaryURL.path). The binary may be malformed.")
        }
    }
    changeDisplayName(ofApp: appURL, to: displayName)
    saveFile(url: appToIPA(appURL), withPotentialName: displayName, allowedFileTypes: ["ipa"])
}

func insertDylibsDir(intoApp appURL: URL, withDylib dylibURLs: [URL], injectSubstrate: Bool) {
    let dylibsDir = appURL.appendingPathComponent("iPatchDylibs")
    
    dylibURLs.forEach { libUrl in
        let newDylibURL = dylibsDir.appendingPathComponent(libUrl.lastPathComponent)
        try? fileManager.createDirectory(at: dylibsDir, withIntermediateDirectories: false, attributes: .none)
        fatalTry("Failed to copy dylib \(libUrl.path) to app iPatchDylibs directory \(dylibsDir.path).") {
            try fileManager.copyItem(at: libUrl, to: newDylibURL)
        }
        shell(launchPath: INSTALL_NAME_TOOL, arguments: ["-id", "\(EXECIPATCHDYLIBS)/\(libUrl.lastPathComponent)", newDylibURL.path])
        
        if injectSubstrate {
            shell(launchPath: INSTALL_NAME_TOOL, arguments: ["-change", "/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate", "\(EXECIPATCHDYLIBS)/libsubstrate.dylib", newDylibURL.path])
            shell(launchPath: INSTALL_NAME_TOOL, arguments: ["-change", "@rpath/CydiaSubstrate.framework/CydiaSubstrate", "\(EXECIPATCHDYLIBS)/libsubstrate.dylib", newDylibURL.path])
        }
    }
    
    insertSubstrateDylibs(intoApp: appURL)
}

func insertSubstrateDylibs(intoApp appURL: URL) {
    let dylibsDir = appURL.appendingPathComponent("iPatchDylibs")
    fatalTry("Failed to copy libblackjack, libhooker, and libsubstrate to app iPatchDylibs directory \(dylibsDir.path).") {
        let libblackjackUrl = dylibsDir.appendingPathComponent("libblackjack.dylib")
        if !fileManager.fileExists(atPath: libblackjackUrl.path) {
            try! fileManager.copyItem(at: bundle.url(forResource: "libblackjack", withExtension: "dylib")!, to: libblackjackUrl)
        }
        let libhookerUrl = dylibsDir.appendingPathComponent("libhooker.dylib")
        if !fileManager.fileExists(atPath: libhookerUrl.path) {
            try! fileManager.copyItem(at: bundle.url(forResource: "libhooker", withExtension: "dylib")!, to: libhookerUrl)
        }
        let libsubstrateUrl = dylibsDir.appendingPathComponent("libsubstrate.dylib")
        if !fileManager.fileExists(atPath: libsubstrateUrl.path) {
            try! fileManager.copyItem(at: bundle.url(forResource: "libsubstrate", withExtension: "dylib")!, to: libsubstrateUrl)
        }
    }
}

func changeDisplayName(ofApp appURL: URL, to displayName: String) {
    let infoURL = appURL.appendingPathComponent("Info.plist")
    let info = NSDictionary(contentsOf: infoURL)!
    info.setValue(displayName, forKey: "CFBundleDisplayName")
    info.write(to: infoURL, atomically: true)
}
