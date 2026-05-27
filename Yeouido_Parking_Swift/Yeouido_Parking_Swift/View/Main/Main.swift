//
//  Main.swift
//  Yeouido_Parking_Swift
//
//  Created by 이상현 on 4/12/26.
//

import SwiftUI
import UIKit

struct MainView: View {
    @EnvironmentObject private var globalState: GlobalState

    var body: some View {
        ZStack {
            switch globalState.selectedMainTab {
            case .home:
                HomeView()
            case .map:
                MapView()
            case .facility:
                FacilityView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !(globalState.selectedMainTab == .map && globalState.isMapFilterSheetPresented) {
                MainFloatingTabBar(
                    selectedTab: selectedTabBinding
                )
                .padding(.horizontal, 18)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
        }
    }

    private var selectedTabBinding: Binding<MainTab> {
        Binding(
            get: { globalState.selectedMainTab },
            set: { newValue in
                globalState.selectedMainTab = newValue
            }
        )
    }
}

private struct MainFloatingTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 12) {
                sideTabButton(for: .home)

                Spacer(minLength: 78)

                sideTabButton(for: .facility)
            }
            .padding(.horizontal, 14)
            .padding(.top, 9)
            .padding(.bottom, 9)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.96))

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.92),
                                    Color(hex: "E4F5EF")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, y: 8)

            mapTabButton
                .offset(y: -12)
        }
    }

    private func sideTabButton(for tab: MainTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 6) {
                Image(systemName: tab.symbolName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(selectedTab == tab ? Color(hex: "167A8C") : Color(hex: "1F3F38").opacity(0.72))
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(selectedTab == tab ? Color(hex: "DDF5EE") : Color.clear)
                    )

                Text(tab.title)
                    .font(.system(size: 11, weight: selectedTab == tab ? .bold : .semibold))
                    .foregroundStyle(selectedTab == tab ? Color(hex: "167A8C") : Color.black.opacity(0.68))
            }
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selectedTab == tab ? Color(hex: "F1FBF8") : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var mapTabButton: some View {
        Button {
            selectedTab = .map
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "63C9F2"),
                                Color(hex: "75D6AF")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 74)
                    .shadow(color: Color(hex: "63C9F2").opacity(0.32), radius: 12, y: 8)

                Circle()
                    .stroke(Color.white.opacity(0.88), lineWidth: 4)
                    .frame(width: 74, height: 74)

                VStack(spacing: 2) {
                    Image(systemName: MainTab.map.symbolName)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)

                    Text(MainTab.map.title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainView()
}
