//
//  ZXMultipartData.swift
//  SwiftTest
//
//  Created by Mac on 2020/12/8.
//
import Foundation


/// 常见的类型，其他的百度
public enum ZXDataMTMEType: String {
    case JPEG = "image/jpeg"
    case PNG = "image/png"
    case GIF = "image/gif"
    case HEIC = "image/heic"
    case HEIF = "image/heif"
    case WEBP = "image/webp"
    case TIF = "image/tif"
    case MP4 = "video/mp4"
    case AUDIO_MPEG = "audio/mpeg"
    case JSON = "application/json"
}

class ZXMultipartData: NSObject {
    let data: Data
    let name: String
    let fileName: String
    let mimeType: String
    
    /*
     当提交一张图片或一个文件的时候, name 可以随便设置，服务端直接能拿到，如果服务端需要根据name去取不同文件的时候
     则appendPartWithFileData 方法中的 name 需要根据form的中的name一一对应
     所以name的值，是需要跟后台服务端商量好的.
     */
    
    init(data: Data, name: String, fileName: String, mimeType: String) {
        self.data = data
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
    convenience init(data: Data, name: String, fileName: String, type: ZXDataMTMEType) {
        self.init(data: data, name: name, fileName: fileName, mimeType: type.rawValue)
    }
}
