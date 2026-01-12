import SwiftUI

// MARK: - Custom App Fonts

extension Font {
    // PT Root UI - основной шрифт для текста
    static func ptRootRegular(_ size: CGFloat) -> Font {
        .custom("PTRootUI-Regular", size: size)
    }
    
    static func ptRootMedium(_ size: CGFloat) -> Font {
        .custom("PTRootUI-Medium", size: size)
    }
    
    static func ptRootBold(_ size: CGFloat) -> Font {
        .custom("PTRootUI-Bold", size: size)
    }
    
    // Gilroy - для заголовков и акцентов
    static func gilroyExtraBold(_ size: CGFloat) -> Font {
        .custom("Gilroy-ExtraBold", size: size)
    }
    
    static func gilroyLight(_ size: CGFloat) -> Font {
        .custom("Gilroy-Light", size: size)
    }
}

// MARK: - App Typography

struct AppFont {
    // Headlines
    static let largeTitle = Font.gilroyExtraBold(34)
    static let title = Font.gilroyExtraBold(28)
    static let title2 = Font.gilroyExtraBold(22)
    static let title3 = Font.ptRootBold(20)
    
    // Body
    static let headline = Font.ptRootBold(17)
    static let body = Font.ptRootRegular(17)
    static let bodyMedium = Font.ptRootMedium(17)
    
    // Secondary
    static let subheadline = Font.ptRootMedium(15)
    static let footnote = Font.ptRootRegular(13)
    static let caption = Font.ptRootRegular(12)
    static let caption2 = Font.ptRootMedium(11)
    
    // Prices & Numbers
    static let price = Font.gilroyExtraBold(20)
    static let priceSmall = Font.ptRootBold(16)
}
