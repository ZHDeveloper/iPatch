//
//  RootViewModel.swift
//  iPatch
//
//  Created by Eamon Tracey.
//

import AppKit
import Combine

class RootViewModel: ObservableObject {
    @Published var debOrDylibURL: [URL] = []
    @Published var ipaURL: URL? = nil
    @Published var injectSubstrate = true
    @Published var displayName = ""
    @Published var substratePopoverPresented = false
    @Published var isPatching = false
    
    var readyToPatch: Bool {
        var array: [URL?] = debOrDylibURL
        array.append(ipaURL)
        return !array.contains(nil)
        && fileManager.filesExist(atFileURLS: array.compactMap{$0})
    }
    
    func patch() {
        guard readyToPatch else { return }
        isPatching = true
        iPatch.patch(ipa: ipaURL!, withDebOrDylib: debOrDylibURL, andDisplayName: displayName, injectSubstrate: injectSubstrate)
        isPatching = false
    }
    
    func ipaURLDidChange() {
        displayName = ipaURL!.deletingPathExtension().lastPathComponent
    }
    
    func handleDrop(of providers: [NSItemProvider]) -> Bool {
        providers.forEach {
            let _ = $0.loadObject(ofClass: URL.self) { url, _  in
                switch url!.pathExtension {
                case "deb", "dylib":
                    DispatchQueue.main.async {
                        if let url = url {
                            self.debOrDylibURL.append(url)
                        }
                    }
                case "ipa":
                    DispatchQueue.main.async {
                        self.ipaURL = url!
                    }
                default:
                    NSSound.beep()
                }
            }
        }
        return true
    }
}
