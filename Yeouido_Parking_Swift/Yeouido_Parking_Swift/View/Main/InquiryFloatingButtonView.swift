//
//  InquiryFloatingButtonView.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import SwiftUI

struct InquiryFloatingButtonView: View {
    @Binding var isExpanded: Bool
    let isCompact: Bool
    let onCallTap: () -> Void
    let onChatTap: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if isExpanded {
                FloatingActionItem(
                    title: "채팅문의",
                    systemName: "message.fill",
                    backgroundColor: Color(hex: "63C9F2"),
                    isCompact: isCompact,
                    action: onChatTap
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))

                FloatingActionItem(
                    title: "전화하기",
                    systemName: "phone.fill",
                    backgroundColor: Color(hex: "75B992"),
                    isCompact: isCompact,
                    action: onCallTap
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                    isExpanded.toggle()
                }
            } label: {
                Group {
                    if isCompact {
                        VStack(spacing: 7) {
                            Image(systemName: isExpanded ? "xmark" : "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 18, weight: .bold))
                                .padding(.top, 2)

                            Text("문의하기")
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 78, height: 78)
                        .background(Color(hex: "ED9781"))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: isExpanded ? "xmark" : "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 16, weight: .bold))

                            Text("문의하기")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 54)
                        .background(Color(hex: "ED9781"))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct FloatingActionItem: View {
    let title: String
    let systemName: String
    let backgroundColor: Color
    let isCompact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isCompact {
                    VStack(spacing: 7) {
                        Image(systemName: systemName)
                            .font(.system(size: 18, weight: .bold))
                            .padding(.top, 2)

                        Text(title)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                    }
                    .frame(width: 78, height: 78)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: systemName)
                            .font(.system(size: 14, weight: .bold))

                        Text(title)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 46)
                    .clipShape(Capsule())
                }
            }
            .foregroundStyle(.white)
            .background(backgroundColor)
            .clipShape(isCompact ? AnyShape(RoundedRectangle(cornerRadius: 24)) : AnyShape(Capsule()))
            .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Color.white.ignoresSafeArea()

        InquiryFloatingButtonView(
            isExpanded: .constant(true),
            isCompact: false,
            onCallTap: {},
            onChatTap: {}
        )
        .padding(20)
    }
}
