//
//  MiniTokens.swift
//  MiniFocus
//
//  Mini Focus design system — central visual tokens.
//
//  Single source of truth for colors, spacing, radii, typography and motion.
//  Views must reference these tokens instead of hardcoding values, so the
//  brand identity stays consistent across every screen.
//
//  Palette and scale come from the Mini Focus brand kit
//  (design/brand-kit/brand/design-tokens.json). Interface typography uses the
//  system font (SF Pro) to support Dynamic Type and native accessibility.
//

import SwiftUI

// MARK: - Colors

/// Mini Focus color palette. Light appearance only (the brand kit does not
/// define dark tokens for v1.0).
enum MiniColor {
    /// #183B35 — CTAs, brand, titles, active state.
    static let primary = Color(red: 24 / 255, green: 59 / 255, blue: 53 / 255)
    /// #F7F6F1 — main screen background.
    static let background = Color(red: 247 / 255, green: 246 / 255, blue: 241 / 255)
    /// #FFFFFF — cards and raised surfaces.
    static let surface = Color.white
    /// #DCE9E1 — soft active status, secondary cards.
    static let sage = Color(red: 220 / 255, green: 233 / 255, blue: 225 / 255)
    /// #1D2824 — primary text.
    static let text = Color(red: 29 / 255, green: 40 / 255, blue: 36 / 255)
    /// #60756E — secondary text. Use at footnote size or larger.
    static let muted = Color(red: 96 / 255, green: 117 / 255, blue: 110 / 255)
    /// #E3E9E4 — hairlines and separators.
    static let line = Color(red: 227 / 255, green: 233 / 255, blue: 228 / 255)
    /// #D6A678 — physical/illustration detail. Not for small text.
    static let warm = Color(red: 214 / 255, green: 166 / 255, blue: 120 / 255)
    /// #A74336 — error / destructive.
    static let error = Color(red: 167 / 255, green: 67 / 255, blue: 54 / 255)
    /// Text that sits on top of the primary color.
    static let onPrimary = Color.white
}

// MARK: - Spacing

/// 4 pt base grid. Screen side margins 24 pt, component gap 16 pt, section gap 32 pt.
enum MiniSpacing {
    static let unit: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    /// Horizontal screen margin.
    static let horizontal: CGFloat = 24
    /// Gap between sibling components.
    static let component: CGFloat = 16
    /// Gap between sections.
    static let section: CGFloat = 32
}

// MARK: - Radius

enum MiniRadius {
    static let card: CGFloat = 20
    static let button: CGFloat = 16
    /// Pill / chip.
    static let chip: CGFloat = 999
}

// MARK: - Controls

enum MiniControl {
    static let buttonMinHeight: CGFloat = 52
    static let tapTargetMinSize: CGFloat = 44
}

// MARK: - Motion

enum MiniMotion {
    static let standard: TimeInterval = 0.2

    /// Standard animation that collapses when Reduce Motion is on.
    /// - Parameter reduceMotion: pass `accessibilityReduceMotion` from the view.
    static func standardAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: standard)
    }
}

// MARK: - Typography

/// Interface typography. Uses system text styles so Dynamic Type and
/// accessibility sizes work out of the box. Base scale 32/22/17/13 pt.
enum MiniFont {
    /// 32 pt — screen titles.
    static let largeTitle = Font.system(.largeTitle, design: .default, weight: .semibold)
    /// 22 pt — section titles.
    static let title = Font.system(.title2, design: .default, weight: .semibold)
    /// 17 pt — body.
    static let body = Font.system(.body)
    /// 17 pt — emphasized body / buttons.
    static let bodyEmphasized = Font.system(.body, design: .default, weight: .semibold)
    /// 13 pt — captions / secondary.
    static let caption = Font.system(.footnote)
}
