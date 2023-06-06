//
//  ContentView.swift
//  Video Demo
//
//  Created by Peter Nash on 21/02/2023.
//

import SwiftUI
import QuickPoseCore
import QuickPoseSwiftUI

struct ContentView: View {
    var quickPose = QuickPose(sdkKey: "YOUR SDK KEY HERE")
    @State var squatCounter = QuickPoseThresholdCounter()
    @State var leftKneeSquatCounter = QuickPoseThresholdCounter()
    @State var overlayImage: UIImage?
    @State var count: Int?
    @State var feedbackText: String?
    @State var scale = 1.0
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if ProcessInfo.processInfo.isiOSAppOnMac, let url = Bundle.main.url(forResource: "squats-pete", withExtension: "mov") {
                    QuickPoseSimulatedCameraView(useFrontCamera: true, delegate: quickPose, video: url)
                } else {
                    QuickPoseCameraView(useFrontCamera: true, delegate: quickPose)
                }
                QuickPoseOverlayView(overlayImage: $overlayImage)
            }.overlay(alignment: .top) {
                if let count = count {
                    Text("\(count) squats").foregroundColor(Color.white).font(.system(size: 32))
                        .padding(100)
                        .scaleEffect(scale)
                }
            }.overlay(alignment: .bottom) {
                if let feedback = feedbackText {
                    Text(feedback).foregroundColor(Color.white).font(.system(size: 26)).multilineTextAlignment(.center)
                        .padding(100)
                }
            }
            .frame(width: geometry.size.width)
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                let smallStyle = QuickPose.Style(relativeFontSize: 0.3, relativeArcSize: 0.3, relativeLineWidth: 0.3, conditionalColors: [QuickPose.Style.ConditionalColor(min: nil, max: 140, color: UIColor.green)])
                let squatCounterFeature = QuickPose.Feature.fitness(.squats, style: smallStyle)
                let leftKneeRom = QuickPose.Feature.rangeOfMotion(.knee(side: .left, clockwiseDirection: true), style: smallStyle)
                let rightKneeRom = QuickPose.Feature.rangeOfMotion(.knee(side: .right, clockwiseDirection: false), style: smallStyle)
                
                let redStyle = QuickPose.Style(relativeFontSize: 0.3, relativeArcSize: 0.3, relativeLineWidth: 0.3, color: UIColor.red)
                
                let features = [squatCounterFeature, leftKneeRom, rightKneeRom]
                quickPose.start(features: features) { status, outputImage, result, feedback, _ in
                    overlayImage = outputImage
                    if let feedback = feedback[squatCounterFeature]  {
                        feedbackText = feedback.displayString
                    } else if let fitnessResult = result[squatCounterFeature], let leftKneeRomResult = result[leftKneeRom] {
                            
                            _ = leftKneeSquatCounter.count(leftKneeRomResult.value < 140 ? fitnessResult.value : 0)
                            _ = squatCounter.count(fitnessResult.value) { status in
                                if case let .poseComplete(squatCount) = status {
                                    if leftKneeSquatCounter.state.count != squatCount {
                                        feedbackText = "left side is not low enough"
                                        squatCounter.state = leftKneeSquatCounter.state
                                        quickPose.update(features: [squatCounterFeature, leftKneeRom.restyled(redStyle), rightKneeRom])
                                    } else {
                                        feedbackText = nil
                                        count = squatCount
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            scale = 2.0
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                scale = 1.0
                                            }
                                        }
                                    }
                                } else {
                                    feedbackText = nil
                                    quickPose.update(features: features) // reset colors
                                }
                            }
                        }
                }
            }
        }
    }
}

