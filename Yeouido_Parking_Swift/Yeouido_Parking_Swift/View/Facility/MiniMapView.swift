//
//  MiniMapView.swift
//  Yeouido_Parking_Swift
//
//  Created by 유다원 on 4/12/26.
//

import SwiftUI
import MapKit

struct MiniMapView: View {
    
    let lat: Double
    let long: Double
    
    @State private var region: MKCoordinateRegion
    
    init(lat: Double, long: Double) {
        self.lat = lat
        self.long = long
        
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: long),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [MapPinItem(lat: lat, long: long)]) { item in
            MapMarker(coordinate: item.coordinate, tint: .red)
        }
        .frame(height: 180)
        .cornerRadius(12)
    }
}

struct MapPinItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    
    init(lat: Double, long: Double) {
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
}
