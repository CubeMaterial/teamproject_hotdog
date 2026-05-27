//
//  ReservationFormView.swift
//  Yeouido_Parking_Swift
//
//  Created by 유다원 on 4/12/26.
//

import SwiftUI

struct ReservationFormView: View {
    
    @EnvironmentObject private var globalState: GlobalState
    
    let facility: Facility
    
    @StateObject private var vm = ReservationViewModel()
    
    @State private var selectedDate = Date()
    @State private var selectedStartHour: Int?
    @State private var selectedEndHour: Int?
    @State private var goToDetail = false
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "63C9F2"),
                    Color(hex: "75B992")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("예약하기")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.black)

                        Text("원하는 날짜와 시간을 선택해 주세요")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.black.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    
                    // 상단 시설 정보 카드
                    VStack(alignment: .leading, spacing: 10) {
                        Text(facility.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        Text(facility.info ?? "시설 설명 없음")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white.opacity(0.88))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                    
                    // 날짜 선택 카드
                    VStack(alignment: .leading, spacing: 12) {
                        Label("예약 날짜", systemImage: "calendar")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .onChange(of: selectedDate) { _, _ in
                            selectedStartHour = nil
                            selectedEndHour = nil
                            Task {
                                await loadDailyReservations()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white.opacity(0.88))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                    
                    // 시간 선택 카드
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("예약 시간", systemImage: "clock")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Text("회색은 선택 불가")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HourBlockGridView(
                            selectedDate: selectedDate,
                            reservedHours: vm.reservedHours,
                            selectedStartHour: $selectedStartHour,
                            selectedEndHour: $selectedEndHour
                        )
                        
                        if let start = selectedStartHour {
                            let end = selectedEndHour ?? start
                            
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "ED9781"))
                                
                                Text("선택 시간")
                                    .font(.subheadline)
                                    .foregroundColor(.black.opacity(0.7))
                                
                                Spacer()
                                
                                Text("\(String(format: "%02d:00", start)) ~ \(String(format: "%02d:00", end + 1))")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(14)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white.opacity(0.88))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                    
                    // 예약 버튼
                    Button {
                        submitReservation()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle")
                            Text("예약하기")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .background(Color(hex: "ED9781"))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 78)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("예약하기")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadDailyReservations()
            }
            .navigationDestination(isPresented: $goToDetail) {
                if let created = vm.createdReservation {
                    ReservationDetailView(reservationId: created.id)
                } else {
                    EmptyView()
                }
            }
            .alert("예약 불가", isPresented: $showAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadDailyReservations() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)
        await vm.fetchDailyReservations(facilityId: facility.id, date: dateString)
    }
    
    private func submitReservation() {
        let now = Date()
        let calendar = Calendar.current
        
        guard let startHour = selectedStartHour else {
            alertMessage = "시작 시간을 선택해주세요."
            showAlert = true
            return
        }
        let endHour = selectedEndHour ?? startHour
        
        guard let startDate = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: selectedDate),
              let endDate = calendar.date(bySettingHour: endHour + 1, minute: 0, second: 0, of: selectedDate) else {
            alertMessage = "시간 계산에 실패했습니다."
            showAlert = true
            return
        }
        
        if startDate <= now {
            alertMessage = "현재 시간 이후만 선택할 수 있습니다."
            showAlert = true
            return
        }
        
        guard let userID = globalState.currentUserID else {
            alertMessage = "로그인 사용자 정보를 확인할 수 없습니다."
            showAlert = true
            return
        }
        
        Task {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let startString = formatter.string(from: startDate)
            let endString = formatter.string(from: endDate)
            
            let result = await vm.createReservation(
                userId: userID,
                facilityId: facility.id,
                startDate: startString,
                endDate: endString
            )
            
            if let createdReservation = result {
                globalState.scheduleReservationNotifications(
                    reservationID: createdReservation.id,
                    facilityName: facility.name,
                    startDate: startDate
                )
                goToDetail = true
            } else {
                alertMessage = vm.errorMessage ?? "예약에 실패했습니다."
                showAlert = true
            }
        }
    }
}
