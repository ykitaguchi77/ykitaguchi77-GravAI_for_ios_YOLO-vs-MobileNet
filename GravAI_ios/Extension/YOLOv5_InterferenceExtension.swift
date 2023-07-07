//
//  InterferenceExtension.swift
//  CorneAI_ios_ver2
//
//  Created by Yoshiyuki Kitaguchi on 2023/01/03.
//

import SwiftUI
import CoreML


class Yolov5Interference: ObservableObject {
    @Published var model = try? yolo5n_100epoch(configuration: MLModelConfiguration())
    @Published var image: UIImage
    @Published var size = CGSize(width: 640, height: 640)
    @Published var classes = ["cont", "grav"]
    @Published var message = ""
    
    init(image: UIImage){
        self.image = image
    }
    
    func classify() -> Double{
        let resizedImage = self.image.resizeImageTo(size:size)
        let buffer = resizedImage!.convertToBuffer()
        
        let output = try? model!.prediction(image: buffer!, iouThreshold: 0.45, confidenceThreshold: 0.25)
        let confidence = convertToClass(from: output!.confidence)
        //let coordinates = convertToCoordinates(from: output!.coordinates)
        //print("confidence: \(String(describing: confidence)), coordinates: \(String(describing: coordinates))")
        return confidence
    }
    
    func convertToClass(from mlMultiArray: MLMultiArray) -> Double {
        var array: [Double] = []
        var dict: [String:String] = [:]
        let length = mlMultiArray.count

        if length == 2 {
            for i in 0..<length {
                array.append(Double(truncating: mlMultiArray[[0,NSNumber(value: i)]]))
            }
            
            for i in 0..<length {
                dict.updateValue(String(format: "%.3f", array[i]), forKey: classes[i])
            }
            
            var sortData = dict.sorted { $0.1 > $1.1 }.map { $0 }[0...1]
            print("sortData (likelihood): \(sortData)")
            
            var convertedData = [(key: String, value: Double)]()
            for data in sortData {
                if let value = Double(data.value) {
                    convertedData.append((key: data.key, value: value))
                }
            }
            
            var sum = 0.0
            for data in convertedData {
                sum += data.value
            }
            
            for i in 0..<convertedData.count {
                sortData[i] = (key: convertedData[i].key, value: String(format: "%.3f", convertedData[i].value / sum))
            }
            print("sortData (probability): \(sortData)")

            if sortData[0].key == "grav" {
                return Double(sortData[0].value)!
            } else if sortData[0].key == "cont" {
                return Double(sortData[1].value)!
            } else {
                return 0.0
            }
        } else {
            return 0.0
        }
    }
    
    
    func convertToCoordinates(from mlMultiArray: MLMultiArray) -> [Double] {
        // Init our output array
        var array: [Double] = []
        // Get length
        let length = mlMultiArray.count
        // Set content of multi array to our out put array
        if length != 0 {
            // Set content of multi array to our out put array
            for i in 0...length - 1 {
                array.append(Double(truncating: mlMultiArray[[0,NSNumber(value: i)]]))
            }} else {
                array = [0,0,0,0]
            }
            return array
    }
    
}


