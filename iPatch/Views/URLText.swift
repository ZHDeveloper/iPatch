//
//  URLText.swift
//  iPatch
//
//  Created by Eamon Tracey.
//

import SwiftUI

struct URLText: View {
    let url: URL?
    @State private var popoverPresented = false
    
    var body: some View {
        Text(url?.lastPathComponent ?? "Choose one")
    }
}

struct MultipleURLText: View {
    let url: [URL]?
    @State private var popoverPresented = false
    
    var tips: String {
        let array: [String] = url?.compactMap({
            $0.lastPathComponent
        }) ?? []
        if array.isEmpty {
            return "Choose one"
        }
        else {
            return array.joined(separator: ",")
        }
    }
    
    var body: some View {
        Text(tips)
    }
}

