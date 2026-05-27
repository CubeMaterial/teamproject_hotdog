//
//  FacilityViewModel.swift
//  Yeouido_Parking_Swift
//
//  Created by 유다원 on 4/12/26.
//

import Foundation
import Combine

@MainActor
final class FacilityViewModel: ObservableObject {
    @Published var facilities: [Facility] = []
    @Published var isLoading = false
    
    func fetchFacilities() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            facilities = try await APIService.shared.fetchFacilities()
        } catch {
            print("시설 조회 실패:", error)
        }
    }
    
    func fetchReservableFacilities() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            facilities = try await APIService.shared.fetchReservableFacilities()
        } catch {
            print("예약 가능 시설 조회 실패:", error)
        }
    }
}
