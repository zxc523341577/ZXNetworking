//
//  ZXNetworkingError.swift
//  SwiftTest
//
//  Created by Mac on 2020/12/5.
//

import Foundation

public class ZXNetworkingError: NSObject {
    /// 错误码
    @objc var code = -1
    /// 错误描述
    @objc var localizedDescription: String

    init(code: Int, desc: String) {
        self.code = code
        self.localizedDescription = desc
        super.init()
    }
}
