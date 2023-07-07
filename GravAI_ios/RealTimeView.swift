//
//  RealTimeView.swift
//  CorneAI_ios_ver2
//
//  Created by Yoshiyuki Kitaguchi on 2023/01/01.
//

import SwiftUI
import CoreML
import AVFoundation


struct RealTimeView: View {
    @ObservedObject var user: User
    @State private var image: UIImage?
    @State private var isStreaming: Bool = true
    @State var showAlert = false
    @State var samplePhotos =  ["grav_1", "grav_2", "cont_1", "cont_2"]
    //@State var result: (String, [Double]) = ("", [0,0,0,0]) //confidence, coordinate
    @State private var useFrontCamera = true


    let videoCapture = VideoCapture()
    
    @State private var rect: CGRect = .zero //スクリーンショット用
    @State var screenImage: UIImage? = nil //スクリーンショット用
  
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            
            //show results
            if let image = image {
                let yolov5Result = Yolov5Interference(image: image).classify()
                
                HStack {
                    Text("Yolov5")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Spacer()
                    
                    Text("\(yolov5Result)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom)
                }
                
                ColorChangingProgressView(value: yolov5Result)
                    .frame(height: 20)
                    .padding(.horizontal)
            }
            
            
            if let image = image {
                let mobileNetResult = MobileNetInterference(image: image).classify()
                
                HStack {
                    Text("MobileNetV3")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Spacer()
                    
                    Text("\(mobileNetResult)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom)
                }
                
                ColorChangingProgressView(value: mobileNetResult)
                    .frame(height: 20)
                    .padding(.horizontal)
            }
            
            
            
            //screenshot button
            if image != nil {
                Button("screenshot"){
                    //classifyImage(image: image!)
                    self.screenImage = UIApplication.shared.windows[0].rootViewController?.view!.getImage(rect: self.rect) //ここがうまくいっていない
                    UIImageWriteToSavedPhotosAlbum(screenImage!, nil, nil, nil)
                    //print("screenshot done!")
                }
                .font(.largeTitle)
            }
            
            
            
        }
        .onAppear{
            videoCapture.run { sampleBuffer in
                if let convertImage = UIImageFromSampleBuffer(sampleBuffer) {
                    DispatchQueue.main.async {
                        self.image = convertImage
                    }
                }
            }
        }
        .onDisappear(perform: videoCapture.stop)
        .background(RectangleGetter(rect: $rect))
    }

    func UIImageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            let context = CIContext()
            if let image = context.createCGImage(ciImage, from: imageRect) {
                let cropped = image.cropToSquare()
                //classifyImage(image: UIImage(cgImage: cropped))
                return UIImage(cgImage: cropped)
            }
        }
        return nil
    }
    
}



struct ColorChangingProgressView: View {
    var value: Double // Must be between 0 and 1
    var highThreshold: Double = 0.5 // Red color threshold

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: CGFloat(self.value) * geometry.size.width, height: geometry.size.height)
                    .foregroundColor(self.value > highThreshold ? Color.red : Color.white)
            }
        }.cornerRadius(5.0)
    }
}











