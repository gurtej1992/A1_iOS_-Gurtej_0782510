//
//  ViewController.swift
//  A1_iOS_ Gurtej_0782510
//
//  Created by Tej on 25/01/21.
//

import UIKit
import MapKit

class MainVC: UIViewController {
    var locationManger = CLLocationManager()
    var arrTitle = ["A","B","C"]
    var arrCoordinates = [CLLocationCoordinate2D]()
    var polygen = MKPolygon()
    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManger.delegate = self
        locationManger.requestWhenInUseAuthorization()
        locationManger.startUpdatingLocation()
        
        let longTap = UITapGestureRecognizer(target: self, action: #selector(handleLongPress(tap:)))
        mapView.addGestureRecognizer(longTap)
    }
    @objc func handleLongPress(tap : UILongPressGestureRecognizer) {
        let location = tap.location(in: mapView)
        let coordinates = mapView.convert(location, toCoordinateFrom: mapView)
        if arrCoordinates.count == 3{
            let closest = arrCoordinates.closest(to: CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude))!
            let locationA  = CLLocation(latitude: closest.latitude, longitude: closest.longitude)
            let locationB  = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            let distance = locationA.distance(from: locationB)
            if distance > 7000{
                mapView.removeOverlay(polygen)
                for pin in mapView.annotations{
                    mapView.removeAnnotation(pin)
                }
                arrCoordinates.removeAll()
                arrCoordinates.append(coordinates)
                setupAnnotation(title: arrTitle[arrCoordinates.count - 1], coordinates: coordinates)
            }
            else{
                let arry = mapView.annotations
                if let pin = arry.first(where: {$0.coordinate.latitude == closest.latitude && $0.coordinate.longitude == closest.longitude}){
                    if let index = arrCoordinates.firstIndex(where: {$0.latitude == closest.latitude && $0.longitude == closest.longitude}){
                        arrCoordinates.remove(at: index)
                        mapView.removeAnnotation(pin)
                        mapView.removeOverlay(polygen)
                    }
                }
                print("Pin to close")
                return
            }
        }
        else if arrCoordinates.count <= 3{
            arrCoordinates.append(coordinates)
            setupAnnotation(title: arrTitle[arrCoordinates.count - 1], coordinates: coordinates)
        }
        if arrCoordinates.count == 3{
            polygen = MKPolygon(coordinates: arrCoordinates, count: arrCoordinates.count)
            mapView.addOverlay(polygen)
        }
        
    }
    func setupAnnotation(title : String, coordinates: CLLocationCoordinate2D){
        let pin = MKPointAnnotation()
        pin.title = title
        pin.coordinate = coordinates
        mapView.addAnnotation(pin)
    }
    @IBAction func handleDirection(_ sender: Any) {
        if arrCoordinates.count == 3{
            mapView.removeOverlay(polygen)
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: arrCoordinates[0].latitude, longitude: arrCoordinates[0].longitude), addressDictionary: nil))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: arrCoordinates[1].latitude, longitude: arrCoordinates[1].longitude), addressDictionary: nil))
            request.requestsAlternateRoutes = true
            request.transportType = .automobile

            let directions = MKDirections(request: request)

            directions.calculate { [unowned self] response, error in
                guard let unwrappedResponse = response else { return }

                if let route = unwrappedResponse.routes.first {
                    self.mapView.addOverlay(route.polyline)
                    self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                }
            }
            let request2 = MKDirections.Request()
            request2.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: arrCoordinates[1].latitude, longitude: arrCoordinates[1].longitude), addressDictionary: nil))
            request2.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: arrCoordinates[2].latitude, longitude: arrCoordinates[2].longitude), addressDictionary: nil))
            request2.requestsAlternateRoutes = true
            request2.transportType = .automobile
            
            let directions2 = MKDirections(request: request2)
            
            directions2.calculate { [unowned self] response, error in
                guard let unwrappedResponse = response else { return }
                
                if let route = unwrappedResponse.routes.first {
                    self.mapView.addOverlay(route.polyline)
                    self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                }
            }
            let request3 = MKDirections.Request()
            request3.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: arrCoordinates[2].latitude, longitude: arrCoordinates[2].longitude), addressDictionary: nil))
            request3.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: arrCoordinates[0].latitude, longitude: arrCoordinates[0].longitude), addressDictionary: nil))
            request3.requestsAlternateRoutes = true
            request3.transportType = .automobile
            
            let directions3 = MKDirections(request: request3)
            
            directions3.calculate { [unowned self] response, error in
                guard let unwrappedResponse = response else { return }
                
                if let route = unwrappedResponse.routes.first {
                    self.mapView.addOverlay(route.polyline)
                    self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                }
            }
        }
    }
}
extension MainVC : CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first{
            let span = MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.region = region
        }
    }
}
extension MainVC : MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolygon{
            let poly = MKPolygonRenderer(overlay: overlay)
            poly.lineWidth = 4
            poly.strokeColor = .green
            poly.fillColor = .red
            poly.alpha = 0.5
            return poly
        }
        else if overlay is MKPolyline{
            let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
            renderer.strokeColor = UIColor.blue
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
extension Array where Iterator.Element == CLLocationCoordinate2D {
    
    func closest(to fixedLocation: CLLocation) -> Iterator.Element? {
        
        return self.sorted { (coordinate1, coordinate2) -> Bool in
            let location1 = CLLocation(latitude: coordinate1.latitude, longitude:coordinate1.longitude)
            let location2 = CLLocation(latitude: coordinate2.latitude, longitude:coordinate2.longitude)
            
            let distanceFromUser1 = fixedLocation.distance(from: location1)
            let distanceFromUser2 = fixedLocation.distance(from: location2)
            
            return distanceFromUser1 < distanceFromUser2
        }.first
        
    }
}
