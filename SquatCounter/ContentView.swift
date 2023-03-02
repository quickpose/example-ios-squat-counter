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
    var quickPose = QuickPose(sdkKey: "01GSWNY1GK411GRZ0NJXBEYQA9")
    @State var squatCounter = QuickPoseThresholdCounter()
    @State var leftKneeSquatCounter = QuickPoseThresholdCounter()
    @State var overlayImage: UIImage?
    @State var count: Int?
    @State var feedback: String?
    @State var scale = 1.0
    var body: some View {
        ZStack {
            if let url = Bundle.main.url(forResource: "squats-pete", withExtension: "mov") {
                QuickPoseSimulatedCameraView(useFrontCamera: true, delegate: quickPose, video: url)
            }
            QuickPoseOverlayView(overlayImage: $overlayImage)
        }.overlay(alignment: .top) {
            if let count = count {
                Text("\(count) squats").foregroundColor(Color.white).font(.system(size: 32))
                    .padding(100)
                    .scaleEffect(scale)
            }
        }.overlay(alignment: .bottom) {
            if let feedback = feedback {
                Text(feedback).foregroundColor(Color.white).font(.system(size: 32))
                    .padding(100)
            }
        }
        .onAppear {
            let smallStyle = QuickPose.Style(relativeFontSize: 0.3, relativeArcSize: 0.3, relativeLineWidth: 0.3, conditionalColors: [QuickPose.Style.ConditionalColor(min: nil, max: 140, color: UIColor.green)])
            let squatCounterFeature = QuickPose.Feature.fitness(.squatCounter, style: smallStyle)
            let leftKneeRom = QuickPose.Feature.rangeOfMotion(.knee(side: .left, clockwiseDirection: true), style: smallStyle)
            let rightKneeRom = QuickPose.Feature.rangeOfMotion(.knee(side: .right, clockwiseDirection: false), style: smallStyle)
            
            let redStyle = QuickPose.Style(relativeFontSize: 0.3, relativeArcSize: 0.3, relativeLineWidth: 0.3, color: UIColor.red)
            
            let features = [squatCounterFeature, leftKneeRom, rightKneeRom]
            quickPose.start(features: features) { _, outputImage, result, _ in
                overlayImage = outputImage
                
                if let fitnessResult = result[squatCounterFeature], let leftKneeRomResult = result[leftKneeRom] {
                    
                    leftKneeSquatCounter.count(probability: leftKneeRomResult.value < 140 ? fitnessResult.value : 0)
                    
                    squatCounter.count(probability: fitnessResult.value) { status in
                        if case let .poseComplete(squatCount) = status {
                            if leftKneeSquatCounter.getCount() != squatCount {
                                feedback = "left side is not low enough"
                                squatCounter.setCount(leftKneeSquatCounter.getCount())
                                quickPose.update(features: [squatCounterFeature, leftKneeRom.restyled(redStyle), rightKneeRom])
                            } else {
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
                            feedback = ""
                            quickPose.update(features: features) // reset colors
                        }
                    }
                }
            }
        }
    }
}
    
