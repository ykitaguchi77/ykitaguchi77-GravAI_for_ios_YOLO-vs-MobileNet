//
//  MobileNet_interferenceExtension.swift
//  GravAI_ios
//
//  Created by Yoshiyuki Kitaguchi on 2023/03/24.
//

import SwiftUI
import CoreML

class MobileNetInterference: ObservableObject {
    @Published var model = try? MobileNetV3_extended(configuration: MLModelConfiguration())
    @Published var image: UIImage
    @Published var size = CGSize(width: 224, height: 224)
    @Published var classes = ["cont", "grav"]
    @Published var message = ""
    @Published var classificationLabel: String = ""
    
    init(image: UIImage){
        self.image = image
    }
    
    func classify() -> (Double) {
        let resizedImage = self.image.resizeImageTo(size:size)
        let buffer = resizedImage!.convertToBuffer()
        
        let output = try? model!.prediction(input_1: buffer!)
        
        if let output = output {
            let results = output.var_879.sorted { $0.1 > $1.1 } //modelにより名前が変わるので注意
            let topThree = results[0...1]
            
            print("key0: \(topThree[0].key), value0: \(topThree[0].value)")
            print("key1: \(topThree[1].key), value1: \(topThree[1].value)")

            
            if topThree[0].key == "grav" {
                return Double(topThree[0].value)
            } else if topThree[0].key == "cont" {
                return Double(topThree[1].value)
            } else {
                return 0.0
            }
        } else {
            return 0.0
        }
    }
}


