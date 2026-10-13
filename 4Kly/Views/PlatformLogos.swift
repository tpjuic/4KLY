//
//  PlatformLogos.swift
//  4Kly
//
//  Official-style platform logos for the empty state view
//

import SwiftUI

// MARK: - YouTube Logo (Red rounded rectangle with play button)
struct YouTubeLogo: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 1, green: 0, blue: 0))
                .frame(width: 42, height: 30)
            
            // Play triangle
            Path { path in
                path.move(to: CGPoint(x: 16, y: 9))
                path.addLine(to: CGPoint(x: 16, y: 21))
                path.addLine(to: CGPoint(x: 28, y: 15))
                path.closeSubpath()
            }
            .fill(Color.white)
            .frame(width: 42, height: 30)
        }
        .frame(width: 42, height: 30)
        .help("YouTube")
    }
}

// MARK: - SoundCloud Logo (Orange cloud shape)
struct SoundCloudLogo: View {
    var body: some View {
        ZStack {
            // Cloud shape
            HStack(spacing: 2) {
                ForEach(0..<8, id: \.self) { i in
                    let heights: [CGFloat] = [12, 16, 22, 26, 22, 18, 14, 10]
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 1.0, green: 0.5, blue: 0.0))
                        .frame(width: 3, height: heights[i])
                }
            }
        }
        .frame(width: 42, height: 30)
        .help("SoundCloud")
    }
}

// MARK: - Facebook Logo (Blue circle with f)
struct FacebookLogo: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.06, green: 0.52, blue: 0.98))
                .frame(width: 32, height: 32)
            
            // Custom f path
            Path { path in
                path.move(to: CGPoint(x: 18, y: 26))
                path.addLine(to: CGPoint(x: 18, y: 17))
                path.addLine(to: CGPoint(x: 22, y: 17))
                path.addLine(to: CGPoint(x: 22.5, y: 14))
                path.addLine(to: CGPoint(x: 18, y: 14))
                path.addLine(to: CGPoint(x: 18, y: 12))
                path.addQuadCurve(to: CGPoint(x: 20, y: 10), control: CGPoint(x: 18, y: 10))
                path.addLine(to: CGPoint(x: 22, y: 10))
                path.addLine(to: CGPoint(x: 22, y: 7))
                path.addLine(to: CGPoint(x: 19, y: 7))
                path.addQuadCurve(to: CGPoint(x: 14, y: 12), control: CGPoint(x: 14, y: 7))
                path.addLine(to: CGPoint(x: 14, y: 14))
                path.addLine(to: CGPoint(x: 11, y: 14))
                path.addLine(to: CGPoint(x: 11, y: 17))
                path.addLine(to: CGPoint(x: 14, y: 17))
                path.addLine(to: CGPoint(x: 14, y: 26))
                path.closeSubpath()
            }
            .fill(Color.white)
            .frame(width: 32, height: 32)
        }
        .frame(width: 42, height: 30)
        .help("Facebook")
    }
}

// MARK: - Vimeo Logo (Teal V with play button style)
struct VimeoLogo: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.10, green: 0.82, blue: 0.95))
                .frame(width: 32, height: 32)
            
            // V shape
            Path { path in
                path.move(to: CGPoint(x: 10, y: 11))
                path.addLine(to: CGPoint(x: 16, y: 22))
                path.addLine(to: CGPoint(x: 22, y: 11))
                path.addLine(to: CGPoint(x: 19, y: 11))
                path.addLine(to: CGPoint(x: 16, y: 18))
                path.addLine(to: CGPoint(x: 13, y: 11))
                path.closeSubpath()
            }
            .fill(Color.white)
            .frame(width: 32, height: 32)
        }
        .frame(width: 42, height: 30)
        .help("Vimeo")
    }
}

// MARK: - TikTok Logo (Music note with cyan/pink offset)
struct TikTokLogo: View {
    var body: some View {
        ZStack {
            // Note shape - cyan offset
            TikTokNoteShape()
                .fill(Color(red: 0.0, green: 0.96, blue: 0.88))
                .frame(width: 22, height: 26)
                .offset(x: -2, y: -1)
            
            // Note shape - pink offset
            TikTokNoteShape()
                .fill(Color(red: 1.0, green: 0.0, blue: 0.31))
                .frame(width: 22, height: 26)
                .offset(x: 2, y: 1)
            
            // Main note - white/black
            TikTokNoteShape()
                .fill(Color.white)
                .frame(width: 22, height: 26)
        }
        .frame(width: 42, height: 30)
        .help("TikTok")
    }
}

struct TikTokNoteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Stem
        path.move(to: CGPoint(x: w * 0.55, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.7))
        
        // Note head (circle at bottom)
        path.addEllipse(in: CGRect(x: w * 0.2, y: h * 0.6, width: w * 0.4, height: h * 0.35))
        
        // Top curl
        path.move(to: CGPoint(x: w * 0.55, y: h * 0.15))
        path.addQuadCurve(to: CGPoint(x: w * 0.85, y: h * 0.25), control: CGPoint(x: w * 0.75, y: h * 0.1))
        path.addQuadCurve(to: CGPoint(x: w * 0.55, y: h * 0.35), control: CGPoint(x: w * 0.85, y: h * 0.4))
        
        return path
    }
}

// MARK: - Twitch Logo (Purple with speech bubble/glitch)
struct TwitchLogo: View {
    var body: some View {
        ZStack {
            // Twitch shape
            Path { path in
                path.move(to: CGPoint(x: 8, y: 4))
                path.addLine(to: CGPoint(x: 8, y: 24))
                path.addLine(to: CGPoint(x: 14, y: 24))
                path.addLine(to: CGPoint(x: 18, y: 28))
                path.addLine(to: CGPoint(x: 22, y: 24))
                path.addLine(to: CGPoint(x: 30, y: 24))
                path.addLine(to: CGPoint(x: 30, y: 4))
                path.closeSubpath()
            }
            .fill(Color(red: 0.57, green: 0.27, blue: 1.0))
            .frame(width: 38, height: 32)
            
            // Eyes
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white)
                .frame(width: 4, height: 10)
                .offset(x: -4, y: -2)
            
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white)
                .frame(width: 4, height: 10)
                .offset(x: 4, y: -2)
        }
        .frame(width: 42, height: 30)
        .help("Twitch")
    }
}

// MARK: - Dailymotion Logo (Blue D with gradient)
struct DailymotionLogo: View {
    var body: some View {
        ZStack {
            // D shape
            Text("D")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.0, green: 0.44, blue: 0.75), Color(red: 0.2, green: 0.6, blue: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: 42, height: 30)
        .help("Dailymotion")
    }
}

// MARK: - Instagram Logo (Gradient square with camera)
struct InstagramLogo: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.51, green: 0.23, blue: 0.72),
                            Color(red: 0.89, green: 0.19, blue: 0.42),
                            Color(red: 0.99, green: 0.69, blue: 0.27)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .frame(width: 30, height: 30)
            
            // Outer border
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white, lineWidth: 2.5)
                .frame(width: 22, height: 22)
            
            // Inner circle
            Circle()
                .stroke(Color.white, lineWidth: 2.5)
                .frame(width: 10, height: 10)
            
            // Dot
            Circle()
                .fill(Color.white)
                .frame(width: 3, height: 3)
                .offset(x: 6, y: -6)
        }
        .frame(width: 42, height: 30)
        .help("Instagram")
    }
}

// MARK: - Twitter/X Logo
struct TwitterLogo: View {
    var body: some View {
        ZStack {
            // X shape
            Path { path in
                // First stroke of X
                path.move(to: CGPoint(x: 8, y: 6))
                path.addLine(to: CGPoint(x: 24, y: 26))
                
                // Second stroke of X
                path.move(to: CGPoint(x: 24, y: 6))
                path.addLine(to: CGPoint(x: 8, y: 26))
            }
            .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 32, height: 32)
        }
        .frame(width: 42, height: 30)
        .help("X (Twitter)")
    }
}

// MARK: - Reddit Logo (Orange alien face)
struct RedditLogo: View {
    var body: some View {
        ZStack {
            // Orange circle background
            Circle()
                .fill(Color(red: 1.0, green: 0.27, blue: 0.0))
                .frame(width: 32, height: 32)
            
            // Antenna stem
            Path { path in
                path.move(to: CGPoint(x: 18, y: 6))
                path.addQuadCurve(to: CGPoint(x: 22, y: 4), control: CGPoint(x: 20, y: 4))
            }
            .stroke(Color.white, lineWidth: 1.5)
            .frame(width: 32, height: 32)
            
            // Antenna ball
            Circle()
                .fill(Color.white)
                .frame(width: 4, height: 4)
                .offset(x: 5, y: -10)
            
            // Face (white oval)
            Ellipse()
                .fill(Color.white)
                .frame(width: 22, height: 16)
                .offset(y: 3)
            
            // Left ear
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .offset(x: -10, y: -2)
            
            // Right ear
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .offset(x: 10, y: -2)
            
            // Left eye
            Circle()
                .fill(Color(red: 1.0, green: 0.27, blue: 0.0))
                .frame(width: 6, height: 6)
                .offset(x: -5, y: 2)
            
            // Right eye
            Circle()
                .fill(Color(red: 1.0, green: 0.27, blue: 0.0))
                .frame(width: 6, height: 6)
                .offset(x: 5, y: 2)
            
            // Smile
            Path { path in
                path.move(to: CGPoint(x: 12, y: 21))
                path.addQuadCurve(to: CGPoint(x: 20, y: 21), control: CGPoint(x: 16, y: 24))
            }
            .stroke(Color(red: 1.0, green: 0.27, blue: 0.0), lineWidth: 1.5)
            .frame(width: 32, height: 32)
        }
        .frame(width: 42, height: 30)
        .help("Reddit")
    }
}
