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
    var myLocation = CLLocationCoordinate2D()
    var polygen = MKPolygon()
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManger.delegate = self
        locationManger.requestWhenInUseAuthorization()
        locationManger.startUpdatingLocation()
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSinglePress(tap:)))
        mapView.addGestureRecognizer(singleTap)
    }
    //Action for single tap
    @objc func handleSinglePress(tap : UILongPressGestureRecognizer) {
        let location = tap.location(in: mapView)
        let coordinates = mapView.convert(location, toCoordinateFrom: mapView)
        if arrCoordinates.count == 3{
            let result = checkAnnotationNearBy(coordinates: coordinates)
            if result.0{
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
                if let pin = arry.first(where: {$0.coordinate.latitude == result.1.latitude && $0.coordinate.longitude == result.1.longitude}){
                    if let index = arrCoordinates.firstIndex(where: {$0.latitude == result.1.latitude && $0.longitude == result.1.longitude}){
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
    // NearBy annotation
    func checkAnnotationNearBy(coordinates: CLLocationCoordinate2D) -> (Bool,CLLocationCoordinate2D){
        let closest = arrCoordinates.closest(to: CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude))!
        let locationA  = CLLocation(latitude: closest.latitude, longitude: closest.longitude)
        let locationB  = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let distance = locationA.distance(from: locationB)
        if distance > 7000{
            return (true ,closest)
        }
        else{
            return (false,closest)
        }
    }
    // Add Annotation
    func setupAnnotation(title : String, coordinates: CLLocationCoordinate2D){
        let pins = mapView.annotations
        let pin = MKPointAnnotation()
        pin.title = title
        pin.coordinate = coordinates
        mapView.addAnnotation(pin)
    }
    // Direction for coordinates
    func getDirections(for index:(Int,Int)){
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: arrCoordinates[index.0].latitude, longitude: arrCoordinates[index.0].longitude), addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: arrCoordinates[index.1].latitude, longitude: arrCoordinates[index.1].longitude), addressDictionary: nil))
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
    }
    //Direction Button
    @IBAction func handleDirection(_ sender: Any) {
        if arrCoordinates.count == 3{
            mapView.removeOverlay(polygen)
            getDirections(for: (0, 1))
            getDirections(for: (1, 2))
            getDirections(for: (2, 0))
        }
    }
}
extension MainVC : CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first{
            myLocation = location.coordinate
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
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
        annotationView.markerTintColor = UIColor.blue
        annotationView.canShowCallout = true
        let loc1 = CLLocation(latitude: myLocation.latitude, longitude: myLocation.longitude)
        let loc2 = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        let distance = loc1.distance(from: loc2)
        let distanceInMeter = Measurement(value: distance, unit: UnitLength.meters)
        let distanceInKM = (distanceInMeter.converted(to: UnitLength.kilometers).value).rounded()
        let label1 = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        
        label1.text = "Distance from \(annotation.title! ?? "") to my location is \(distanceInKM) km"
        label1.numberOfLines = 0
        annotationView.detailCalloutAccessoryView = label1
        return annotationView
        
    }
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        if let annotation = views.first(where: { $0.reuseIdentifier == "AnnotId" })?.annotation {
            mapView.selectAnnotation(annotation, animated: true)
        }
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
