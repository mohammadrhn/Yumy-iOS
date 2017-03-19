//
//  MapViewController.swift
//  Yumy
//
//  Created by Mohammad Rahmanian on 3/7/17.
//  Copyright © 2017 Yumy. All rights reserved.
//

import UIKit
import ASHorizontalScrollView
import MapKit
import GoogleMaps
import NVActivityIndicatorView
import DZNEmptyDataSet
import Amplitude_iOS

class MapViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, UISearchBarDelegate, GMSMapViewDelegate, NVActivityIndicatorViewable, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var filtersHorizontalView: UIView!
    @IBOutlet weak var placeSearchBar: UISearchBar!
    @IBOutlet weak var googleMapView: GMSMapView!
    @IBOutlet weak var searchView: UITableView!
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    
    var places : [String : Place?] = [:]
    
    var buttons : [String : UIButton] = [:]
    
    var filteredPlaces : [Place] = []
    
    var searchActive : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        prepareHorizontalScrollView()
        prepareSearchBar()
        getUserLocation()
        
        googleMapView.delegate = self
        placeSearchBar.delegate = self
        searchView.delegate = self
        searchView.dataSource = self
        
        searchView.isHidden = true
        searchView.emptyDataSetSource = self
        searchView.emptyDataSetDelegate = self
        searchView.tableFooterView = UIView()
        
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        checkIntntAndLcnAvailability()
        
        for key in buttons.keys{
            switch key {
            case "Rst":
                buttons[key]?.setImage(UIImage(named: "DeActiveRestaurant"), for: .normal)
            case "FF":
                buttons[key]?.setImage(UIImage(named: "DeActiveFastfood"), for: .normal)
            case "De":
                buttons[key]?.setImage(UIImage(named: "DeActiveDelivery"), for: .normal)
            case "CS":
                buttons[key]?.setImage(UIImage(named: "DeActiveCoffee"), for: .normal)
            default:
                break
            }
        }
        
        for filter in Global.placeFiltersArray{
            switch filter {
            case "Rst":
                buttons[filter]?.setImage(UIImage(named: "ActiveRestaurant"), for: .normal)
            case "FF":
                buttons[filter]?.setImage(UIImage(named: "ActiveFastfood"), for: .normal)
            case "De":
                buttons[filter]?.setImage(UIImage(named: "ActiveDelivery"), for: .normal)
            case "CS":
                buttons[filter]?.setImage(UIImage(named: "ActiveCoffee"), for: .normal)
            default:
                break
            }
        }
        
        DispatchQueue.main.async {
            self.reloadMapData()
        }
    
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.searchView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.layoutIfNeeded()
        self.view.updateConstraints()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Private methods
    private func prepareHorizontalScrollView(){
        let horizontalScrollView:ASHorizontalScrollView = ASHorizontalScrollView(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100))
        
        horizontalScrollView.uniformItemSize = CGSize(width: 84, height: 84)
        
        for i in 1...4{
            horizontalScrollView.addItem(createButton(idx: i))
        }
        _ = horizontalScrollView.centerSubviews()
        
        filtersHorizontalView.addSubview(horizontalScrollView)
    }
    
    private func createButton(idx: Int) -> UIButton{
        let button = UIButton(frame: CGRect.zero)
        button.titleLabel?.font = Global.iranSans16
        button.layer.cornerRadius = 5
        button.tag = idx
        button.addTarget(self, action: #selector(filterPlace), for: .touchUpInside)
        button.layer.shadowColor = UIColor.darkGray.cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowOffset = CGSize.zero
        button.layer.shadowRadius = 5
        switch idx {
        case 3:
            button.setImage(UIImage(named: "DeActiveRestaurant"), for: .normal)
            buttons["Rst"] = button
        case 2:
            button.setImage(UIImage(named: "DeActiveFastfood"), for: .normal)
            buttons["FF"] = button
        case 4:
            button.setImage(UIImage(named: "DeActiveDelivery"), for: .normal)
            buttons["De"] = button
        case 1:
            button.setImage(UIImage(named: "DeActiveCoffee"), for: .normal)
            buttons["CS"] = button
        default: break
        }
        
        return button
    }
    
    private func prepareSearchBar(){
        let textFieldInsideSearchBar = placeSearchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.attributedPlaceholder = NSAttributedString(string:NSLocalizedString("جستجو کنید", comment:""), attributes:[NSFontAttributeName: Global.iranSans14!])
        textFieldInsideSearchBar?.font = Global.iranSans14
        placeSearchBar.setValue("لغو", forKey:"_cancelButtonText")
        let cancelButtonAttributes: NSDictionary = [NSForegroundColorAttributeName: Global.yumyRed, NSFontAttributeName: Global.iranSans16!]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes as? [String : AnyObject], for: .normal)
    }
    
    private func prepareMapView(){
        Amplitude.logEvent("User location", withEventProperties: ["lat: ": String(format: "%f",(Global.userLocation?.latitude)!), "lng: ": String(format: "%f", (Global.userLocation?.longitude)!)])
        googleMapView.animate(toLocation: Global.userLocation!)
        googleMapView.animate(toZoom: 15.0)
        googleMapView.isMyLocationEnabled = true
    }
    
    private func getUserLocation(){
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    private func setMapCntrOnUsrLcn(){
        googleMapView.animate(toLocation: self.currentLocation!)
    }
    
    private func checkIntntAndLcnAvailability(){
        var callback: ((Bool, Bool) -> (Void))?;
        callback = {(internetStatus, locationStatus) -> (Void) in
            if(internetStatus == false){
                Global.internetAvailability = false
                DispatchQueue.main.async {
                    self.stopAnimating()
                }
                Global.askMessage("لطفا از متصل بودن اینترنت خود اطمینان داشته باشید"){ () -> (Void) in
                    callback!(Global.isInternetAvailable(), Global.isLocationServiceAvailable())
                }
            } else {
                Global.internetAvailability = true
            }
            
            if(locationStatus == false) {
                DispatchQueue.main.async {
                    self.stopAnimating()
                }
                Global.askMessage("لطفا از روشن بودن سرویس مکان یاب خود اطمینان داشته باشید"){ () -> (Void) in
                    callback!(Global.isInternetAvailable(), Global.isLocationServiceAvailable())
                }
            }
            
        }
        callback!(Global.isInternetAvailable(), Global.isLocationServiceAvailable())
    }
    
    // MARK: - Uncategorized methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Global.userLocation = manager.location!.coordinate
        locationManager.stopUpdatingLocation()
        self.prepareMapView()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func filterPlace(sender: UIButton!){
        checkIntntAndLcnAvailability()
        if(Global.internetAvailability){
            switch sender.tag {
            case 3:
                if Global.placeFiltersArray.contains("Rst") {
                    sender.setImage(UIImage(named: "DeActiveRestaurant"), for: .normal)
                    Global.placeFiltersArray = Global.placeFiltersArray.filter{$0 != "Rst"}
                    
                } else {
                    Global.placeFiltersArray.append("Rst")
                    sender.setImage(UIImage(named: "ActiveRestaurant"), for: .normal)
                }
            case 2:
                if Global.placeFiltersArray.contains("FF") {
                    sender.setImage(UIImage(named: "DeActiveFastfood"), for: .normal)
                    Global.placeFiltersArray = Global.placeFiltersArray.filter{$0 != "FF"}
                } else {
                    Global.placeFiltersArray.append("FF")
                    sender.setImage(UIImage(named: "ActiveFastfood"), for: .normal)
                }
            case 4:
                if Global.placeFiltersArray.contains("De") {
                    sender.setImage(UIImage(named: "DeActiveDelivery"), for: .normal)
                    Global.placeFiltersArray = Global.placeFiltersArray.filter{$0 != "De"}
                } else {
                    Global.placeFiltersArray.append("De")
                    sender.setImage(UIImage(named: "ActiveDelivery"), for: .normal)
                }
            case 1:
                if Global.placeFiltersArray.contains("CS") {
                    sender.setImage(UIImage(named: "DeActiveCoffee"), for: .normal)
                    Global.placeFiltersArray = Global.placeFiltersArray.filter{$0 != "CS"}
                } else {
                    Global.placeFiltersArray.append("CS")
                    sender.setImage(UIImage(named: "ActiveCoffee"), for: .normal)
                }
            default:
                break
            }
            Amplitude.logEvent("Filters tapped", withEventProperties: ["filters: ": Global.placeFiltersArray] )
            DispatchQueue.main.async {
                self.startAnimating(CGSize(width: 48, height: 48), type: NVActivityIndicatorType(rawValue: 8)!)
            }
            
            
            
            YumyAPI.loadPlaces(callback: {
                DispatchQueue.main.async {
                    self.reloadMapData()
                    self.stopAnimating()
                }
            })
        }
        
    }
    
    // MARK: - Map View Methods
    
    func reloadMapData(){
        self.googleMapView.clear()
        var dataSource : [Place] = []
        if(Global.isNearMeActivated){
            dataSource = Global.nearPlaces
        } else {
            dataSource = Global.places
        }
        for place in dataSource{
            places[place.name] = place
            let position =  place.location.coordinate
            let marker = GMSMarker(position: position)
            marker.title = place.name
            marker.snippet = place.address
            marker.map = googleMapView
            switch place.type {
            case "رستوران":
                marker.icon = UIImage(named: "RestaurantMapIcon")
            case "فست فود":
                marker.icon = UIImage(named: "FastfoodMapIcon")
            case "بیرون بر":
                marker.icon = UIImage(named: "DeliveryMapIcon")
            case "کافی شاپ":
                marker.icon = UIImage(named: "CoffeeMapIcon")
            default:
                break
            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        let infoWindow = Bundle.main.loadNibNamed("infoWindow", owner: self, options: nil)?.first! as! CustomInfoWindow
        infoWindow.placeNameLabel.text = marker.title
        infoWindow.placeAddressLabel.text = marker.snippet
        return infoWindow
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        Amplitude.logEvent("Marker infoView Tapped")
        Global.selectedPlace = places[marker.title!]!
        self.navigationController?.pushViewController((self.storyboard?.instantiateViewController(withIdentifier: "PlaceViewController"))!, animated: true)
    }
    
    // MARK: - Search Table View Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceTableViewCell", for: indexPath) as? PlaceTableViewCell else {
            fatalError("cell is not a PlaceTableViewCell")
        }
        let place = filteredPlaces[indexPath.row]
        
        cell.placeNameLabel.text = place.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Global.selectedPlace = filteredPlaces[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.pushViewController((self.storyboard?.instantiateViewController(withIdentifier: "PlaceViewController"))!, animated: true)
    }
    
    func reloadTableData(){
        DispatchQueue.main.async {
            self.searchView.reloadData()
        }
    }
    
    
    // MARK: - Actions
    @IBAction func getCurrentLocation(_ sender: UIButton) {
        self.getUserLocation()
    }
    
    // MARK: - Search methods
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        Amplitude.logEvent("MapView Search Entered")
        searchActive = true;
        self.searchView.isHidden = false
        placeSearchBar.showsCancelButton = true
        
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
        placeSearchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        placeSearchBar.text = ""
        placeSearchBar.resignFirstResponder()
        self.searchView.isHidden = true
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        placeSearchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if(Global.isNearMeActivated){
            filteredPlaces = Global.nearPlaces.filter{
                $0.name.contains(searchText)
            }
        } else {
            filteredPlaces = Global.places.filter{
                $0.name.contains(searchText)
            }
        }
        searchActive = true
        self.reloadTableData()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        placeSearchBar.resignFirstResponder()
    }
    
    // MARK: - empty Table view methods
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "متاسفانه محلی با نام مورد نظر پیدا نشد"
        let attrs = [NSFontAttributeName: Global.iranSans14!]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "sad")
    }
    
}
