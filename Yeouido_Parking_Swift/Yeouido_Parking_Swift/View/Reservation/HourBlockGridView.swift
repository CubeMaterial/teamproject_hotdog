//
//  HourBlockGridView.swift
//  Yeouido_Parking_Swift
//
//  Created by 유다원 on 4/12/26.
//

import SwiftUI

struct HourBlockGridView: View {
    
    let selectedDate: Date
    let reservedHours: Set<Int>
    @Binding var selectedStartHour: Int?
    @Binding var selectedEndHour: Int?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<24, id: \.self) { hour in
                let disabled = reservedHours.contains(hour) || isPastHour(hour)
                
                Button {
                    handleTap(hour)
                } label: {
                    Text(String(format: "%02d:00", hour))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isSelected(hour) ? Color(hex: "ED9781") : Color.white)
                        .foregroundColor(disabled ? .gray : (isSelected(hour) ? .white : .black))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                        .cornerRadius(10)
                }
                .disabled(disabled)
            }
        }
    }
    
    private func handleTap(_ hour: Int) {
        if reservedHours.contains(hour) || isPastHour(hour) { return }
        
        if selectedStartHour == nil {
            selectedStartHour = hour
            selectedEndHour = nil
            return
        }
        
        if let start = selectedStartHour, selectedEndHour == nil {
            if hour == start {
                selectedStartHour = nil
                selectedEndHour = nil
                return
            }
            
            if hour < start {
                selectedStartHour = hour
                selectedEndHour = nil
                return
            }
            
            for h in start...hour {
                if reservedHours.contains(h) || isPastHour(h) {
                    return
                }
            }
            
            selectedEndHour = hour
            return
        }
        
        selectedStartHour = hour
        selectedEndHour = nil
    }
    
    private func isSelected(_ hour: Int) -> Bool {
        if let start = selectedStartHour, let end = selectedEndHour {
            return hour >= start && hour <= end
        } else if let start = selectedStartHour {
            return hour == start
        }
        return false
    }
    
    private func isPastHour(_ hour: Int) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        if !calendar.isDate(selectedDate, inSameDayAs: now) {
            return false
        }
        
        let currentHour = calendar.component(.hour, from: now)
        return hour <= currentHour
    }
}
