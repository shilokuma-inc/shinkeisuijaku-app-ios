//
//  TextSizeLayoutTests.swift
//  ShinkeisuijakuTests
//
//  文字の大きさに合わせた並べ方（アクセシビリティの大きな文字では縦に積む）を確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import SwiftUI
import Testing

struct TextSizeLayoutTests {
    /// ふつうの大きさ（xxxLarge まで）は横に並べ、アクセシビリティの大きさ（AX1〜AX5）は縦に積む
    @Test
    func stacksVerticallyOnlyForAccessibilitySizes() {
        let regular: [DynamicTypeSize] = [.xSmall, .large, .xxxLarge]
        let accessibility: [DynamicTypeSize] = [.accessibility1, .accessibility3, .accessibility5]
        #expect(regular.allSatisfy { !TextSizeLayout.stacksVertically($0) })
        #expect(accessibility.allSatisfy { TextSizeLayout.stacksVertically($0) })
    }

}
