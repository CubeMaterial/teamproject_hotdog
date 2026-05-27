import SwiftUI

struct ChatbotFloatingButton: View {
    var body: some View {
        ZStack {
            ChatBubbleShape()
                .fill(Color(red: 0.99, green: 0.43, blue: 0.12))

            ZStack {
                Circle()
                    .fill(Color(red: 0.97, green: 0.92, blue: 0.82))
                    .frame(width: 56, height: 56)

                headsetBand

                Group {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 0.18, green: 0.20, blue: 0.25))
                        .frame(width: 11, height: 24)
                        .offset(x: -24, y: 8)

                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 0.18, green: 0.20, blue: 0.25))
                        .frame(width: 11, height: 24)
                        .offset(x: 24, y: 8)
                }

                Group {
                    Ellipse()
                        .fill(Color(red: 0.95, green: 0.68, blue: 0.39))
                        .frame(width: 22, height: 33)
                        .rotationEffect(.degrees(18))
                        .offset(x: -24, y: -2)

                    Ellipse()
                        .fill(Color(red: 0.95, green: 0.68, blue: 0.39))
                        .frame(width: 22, height: 33)
                        .rotationEffect(.degrees(-18))
                        .offset(x: 24, y: -2)
                }

                Group {
                    Circle()
                        .fill(Color(red: 0.20, green: 0.14, blue: 0.10))
                        .frame(width: 11, height: 15)
                        .offset(x: -12, y: 2)

                    Circle()
                        .fill(.white)
                        .frame(width: 4, height: 4)
                        .offset(x: -14, y: 0)

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addQuadCurve(to: CGPoint(x: 10, y: 4), control: CGPoint(x: 7, y: -3))
                    }
                    .stroke(Color(red: 0.20, green: 0.14, blue: 0.10), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 14, height: 10)
                    .offset(x: 10, y: 4)
                }

                Group {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color(red: 0.20, green: 0.14, blue: 0.10))
                        .frame(width: 18, height: 12)
                        .offset(y: 16)

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addQuadCurve(to: CGPoint(x: 12, y: 0), control: CGPoint(x: 6, y: 6))
                    }
                    .stroke(Color(red: 0.20, green: 0.14, blue: 0.10), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .frame(width: 14, height: 8)
                    .offset(x: -8, y: 26)

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addQuadCurve(to: CGPoint(x: 12, y: 0), control: CGPoint(x: 6, y: 6))
                    }
                    .stroke(Color(red: 0.20, green: 0.14, blue: 0.10), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .frame(width: 14, height: 8)
                    .scaleEffect(x: -1, y: 1)
                    .offset(x: 8, y: 26)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 1.0, green: 0.40, blue: 0.22))
                        .frame(width: 10, height: 13)
                        .offset(y: 28)
                }

                Group {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addQuadCurve(to: CGPoint(x: 16, y: 12), control: CGPoint(x: 9, y: 2))
                    }
                    .stroke(Color(red: 0.18, green: 0.20, blue: 0.25), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 20, height: 14)
                    .offset(x: 22, y: 20)

                    Capsule()
                        .fill(Color(red: 0.18, green: 0.20, blue: 0.25))
                        .frame(width: 14, height: 9)
                        .offset(x: 28, y: 26)
                }
            }
            .offset(y: -2)
        }
        .frame(width: 72, height: 72)
    }

    private var headsetBand: some View {
        Circle()
            .trim(from: 0.12, to: 0.88)
            .stroke(Color(red: 0.18, green: 0.20, blue: 0.25), lineWidth: 6)
            .frame(width: 58, height: 58)
            .rotationEffect(.degrees(180))
            .offset(y: -6)
    }
}

private struct ChatBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tailStartX = rect.minX + rect.width * 0.18
        let tailPoint = CGPoint(x: rect.minX + rect.width * 0.06, y: rect.maxY - rect.height * 0.16)
        let tailReturn = CGPoint(x: rect.minX + rect.width * 0.28, y: rect.maxY - rect.height * 0.22)

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY - 2),
            radius: rect.width * 0.48,
            startAngle: .degrees(-90),
            endAngle: .degrees(135),
            clockwise: false
        )
        path.addQuadCurve(to: tailPoint, control: CGPoint(x: rect.minX - 2, y: rect.maxY - rect.height * 0.02))
        path.addLine(to: tailReturn)
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY - 2),
            radius: rect.width * 0.48,
            startAngle: .degrees(145),
            endAngle: .degrees(270),
            clockwise: false
        )

        let _ = tailStartX
        return path
    }
}
