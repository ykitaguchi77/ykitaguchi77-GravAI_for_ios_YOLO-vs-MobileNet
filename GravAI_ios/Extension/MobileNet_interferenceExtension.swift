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
    
    func classify() -> (String) {
        let resizedImage = self.image.resizeImageTo(size:size)
        let buffer = resizedImage!.convertToBuffer()
        
        let output = try? model!.prediction(input_1: buffer!)
        
        if let output = output {
            let results = output.var_879.sorted { $0.1 > $1.1 } //modelにより名前が変わるので注意
            let topThree = results[0...1]
            let message = topThree.map { (key, value) in
                return "\(key) = \(String(format: "%.2f", value * 100))%"
            }.joined(separator: "\n")
            
            //self.classificationLabel = result
            return (message)
            
        }
    
        return ""
    }
}


