//
//  demoApp.swift
//  demo
//
//  Created by QuickPose on 22/02/2023.
//

import SwiftUI
import AVFoundation

@main
struct demoApp: App {
    var body: some Scene {
        WindowGroup {
            DemoAppView()
        }
    }
}

struct DemoAppView: View {
    @State var cameraPermissionGranted = !ProcessInfo.processInfo.isiOSAppOnMac
    var body: some View {
        GeometryReader { geometry in
            if cameraPermissionGranted {
                ContentView()
            }
        }.onAppear {
            AVCaptureDevice.requestAccess(for: .video) { accessGranted in
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = accessGranted
                }
            }
        }
    }
}
