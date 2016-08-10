//
//  HomeViewController.swift
//  PokeNavigator
//
//  Created by Cristian Mungiu on 7/18/16.
//  Copyright © 2016 Cristian Mungiu. All rights reserved.
//

import UIKit
import SwiftyJSON
import JLToast
import ImageLoader
import MBProgressHUD
import CoreLocation
import MapKit

enum PokemonTypeStatus {
    case Rare
    case Uncommon
    case Common
}

class HomeViewController: AppViewController, MKMapViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate, GetAllPokemonsDelegate,GetNearbyPokemonsDelegate, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties

    var selectedList: [Pokemon] = []
    var checkList: [Bool] = []
    var pokemonTypeStatus = PokemonTypeStatus.Rare
    var mProgress: MBProgressHUD!
    var isUnknownUserLocation = true
    var searchAnnotationView: MKAnnotationView! = nil
    var filteredPokemonList: [Pokemon] = []
    
    @IBOutlet weak var textSearch: UITextField!
    @IBOutlet weak var buttonMenu: UIButton!
    @IBOutlet weak var buttonScan: UIButton!
    @IBOutlet weak var viewButtons: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var viewFilter: UIView!
    @IBOutlet weak var viewRareBottom: UIView!
    @IBOutlet weak var viewUncommonBottom: UIView!
    @IBOutlet weak var viewCommonBottom: UIView!
    @IBOutlet weak var viewSelectAllFooter: UIView!
    @IBOutlet weak var viewDeselectAllFooter: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Main functions of ViewController
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
        // MapView Initialize
        
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        // Search Text Field Initialize\
        textSearch.delegate = self
        textSearch.returnKeyType = .Search
        buttonScan.setShadow(offset: 1.0, radius: 1.0, opacity: 0.5)
        
        // TableView Initialize
        
        let nib = UINib(nibName: "PokemonTableViewCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "PokemonTableViewCell")
        
        // Start GPS Tracker
        StartGPSTracker()
        
        // Load All Pokemons
        APIHandler.getAllPokemonsDelegate = self
        APIHandler.getAllPokemons()
        
        // Set TapGesture On View
        setTapGesture()
        
        ShowLoading("Loading...")
	}

    override func viewWillAppear(animated: Bool) {
        
        buttonMenu.hidden = false
        viewButtons.hidden = true
        viewFilter.hidden = true
        GPSTracker.sharedTracker.delegate = self
        APIHandler.getNearbyPokemonsDelegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        GPSTracker.sharedTracker.delegate = nil
    }
    
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
    
    
    // MARK: - Initialize
    
    // FitlerView Initializes
    private func InitFilterView() {
    
        viewFilter.setShadow(offset: 2.0, radius: 2.0, opacity: 0.5)
        viewRareBottom.hidden = false
        viewUncommonBottom.hidden = true
        viewCommonBottom.hidden = true
        viewSelectAllFooter.hidden = false
        viewDeselectAllFooter.hidden = true
    
        UpdatePokemonsTable()
    }
    
    // Update Pokemons Table With Rare|Uncommon|Common
    private func UpdatePokemonsTable() {
    
        switch pokemonTypeStatus {
        case .Rare:
            selectedList = Pokemon.allPokemons.filter({$0.rarity == "rare"})
            break
        case .Uncommon:
            selectedList = Pokemon.allPokemons.filter({$0.rarity == "uncommon"})
            break
        case .Common:
            selectedList = Pokemon.allPokemons.filter({$0.rarity == "common"})
            break
        }
        
        // Sort List Alphabetically
        selectedList = selectedList.sort({(item1, item2) -> Bool in
            return item1.name.lowercaseString < item2.name.lowercaseString ? true : false
        })
        
        checkList = Array(count: selectedList.count, repeatedValue: true)
        tableView.delegate = self
        tableView.reloadData()
        tableView.setContentOffset(CGPointZero, animated: false)
    }
    
    // MARK: - Set TapGesture around the textfield
    private func setTapGesture() {
        
        let tapGestureArroundTextField = UITapGestureRecognizer(target: self,
                                                                action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGestureArroundTextField)
        
        let tapGetureOnTableView = UITapGestureRecognizer(target: self,
                                                               action: #selector(tableTapped))
        tableView.addGestureRecognizer(tapGetureOnTableView)
    }
    
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc private func tableTapped(tap: UITapGestureRecognizer) {
        
        dismissKeyboard()
        
        let location: CGPoint = tap.locationInView(tableView)
        let path: NSIndexPath! = tableView.indexPathForRowAtPoint(location)!
        
        if path != nil {
            self.tableView(tableView, didSelectRowAtIndexPath: path)
        }
    }

    // Start GPS Tracking
    private func StartGPSTracker() {
        
        GPSTracker.sharedTracker.delegate = self
        GPSTracker.sharedTracker.requestWhenInUseAuthorization()
        GPSTracker.sharedTracker.startUpdatingLocation()
        
        precondition(CLLocationManager.locationServicesEnabled())
        print("👉👉 Core Location Enabled: \(CLLocationManager.authorizationStatus())")
    }
    
    // MARK: - Loding Progress Show
    
    private func ShowLoading(lblTitle : String){
        mProgress = MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().keyWindow!, animated: true)
        mProgress.mode = MBProgressHUDMode.AnnularDeterminate
        mProgress.label.text = lblTitle
        
        mProgress.showAnimated(true)
    }
    
    
    // MARK: <>--------------- Clicked Main Buttons --------------<>
    
    // MARK: - Clicked ScanButton
    
    @IBAction func btnScanClicked(sender: UIButton) {
        
        viewFilter.hidden = true
        viewButtons.hidden = true
        dismissKeyboard()
        
        if let location = GPSTracker.sharedTracker.currentLocation {
            APIHandler.getNearbyPokemonsDelegate = self
            ShowLoading("Loading...")
            APIHandler.getNearbyPokemons(location: location, radius: GPSTracker.radius)
        }
        
    }
    
    // MARK: - Clicked MenuButton
    
    @IBAction func btnMenuClicked(sender: UIButton) {
    
        dismissKeyboard()
        viewButtons.hidden = false
    }
    
    
    // MARK: - Clicked Navigation Button
    
    @IBAction func btnNavigationClicked(sender: UIButton) {
        
        dismissKeyboard()
        ShowCurrentLocationOnMapCenter()
        viewButtons.hidden = true
    }
    
    
    // MARK: - Clicked Fitler Button
    
    @IBAction func btnFilterClicked(sender: UIButton) {
    
        dismissKeyboard()
        viewButtons.hidden = true
        viewFilter.hidden = false
        viewSelectAllFooter.hidden = false
        viewDeselectAllFooter.hidden = true
        pokemonTypeStatus = PokemonTypeStatus.Rare
        InitFilterView()
    }
    
    // MARK: - Clicked Notification Button
    
    @IBAction func btnNotifiacationClicked(sender: UIButton) {
    
        
    }
    
    // MARK: <>-------------------- FilterView --------------------<>
    
    // MARK: - Clicked Rare Button
    
    @IBAction func buttonRareClicked(sender: UIButton) {
        
        viewRareBottom.hidden = false
        viewUncommonBottom.hidden = true
        viewCommonBottom.hidden = true
        viewSelectAllFooter.hidden = false
        viewDeselectAllFooter.hidden = true
        
        pokemonTypeStatus = .Rare
        UpdatePokemonsTable()
    }
    
    // MARK: - Clicked Uncommon Button
    
    @IBAction func buttonUncommonClicked(sender: UIButton) {
        
        viewRareBottom.hidden = true
        viewUncommonBottom.hidden = false
        viewCommonBottom.hidden = true
        viewSelectAllFooter.hidden = false
        viewDeselectAllFooter.hidden = true
        
        pokemonTypeStatus = .Uncommon
        UpdatePokemonsTable()
    }
    
    // MARK: - Clicked Common Button
    
    @IBAction func buttonCommonClicked(sender: UIButton) {
        
        viewRareBottom.hidden = true
        viewUncommonBottom.hidden = true
        viewCommonBottom.hidden = false
        viewSelectAllFooter.hidden = false
        viewDeselectAllFooter.hidden = true
        
        pokemonTypeStatus = .Common
        UpdatePokemonsTable()
    }
    
    // MARK: - Clicked Select All Button
    
    @IBAction func buttonSelectAllClicked(sender: UIButton) {
        
        viewSelectAllFooter.hidden = false
        viewDeselectAllFooter.hidden = true
        checkList = Array(count: selectedList.count, repeatedValue: true)
        tableView.reloadData()
    }
    
    // MARK: - Clicked Deselect All Button
    
    @IBAction func buttonDeselectAllClicked(sender: UIButton) {
    
        viewSelectAllFooter.hidden = true
        viewDeselectAllFooter.hidden = false
        checkList = Array(count: selectedList.count, repeatedValue: false)
        tableView.reloadData()
    }
    
    // MARK: - Clicked Search Button On FilterView
    
    @IBAction func buttonSearchClicked(sender: UIButton) {
        
        viewFilter.hidden = true
        viewButtons.hidden = true
        
        filteredPokemonList = []
        
        for (index, item) in checkList.enumerate() {
            
            if item {
                filteredPokemonList.append(selectedList[index])
            }
        }
        
        ShowNearbyPokemonsFiltered()
    }
    
    // MARK: <>------------------- Delegates --------------------<>
    
    // MARK: - GPSTracker Delegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let currentLocation = mapView.userLocation.location {
            print("📍📍Current User Location - (22,336362764738545, 114,13966723425783)")
            self.UpdateGPSTracker(didUpdateLocation: currentLocation)
        }
    }

    // Update location
    private func UpdateGPSTracker(didUpdateLocation location: CLLocation) {
        
        GPSTracker.sharedTracker.currentLocation = location
       
        if isUnknownUserLocation {
            isUnknownUserLocation = false
            
            // Load Nearby Pokemons
            APIHandler.getNearbyPokemonsDelegate = self
            APIHandler.getNearbyPokemons(location: GPSTracker.sharedTracker.currentLocation,
                                         radius: GPSTracker.radius)
            ShowCurrentLocationOnMapCenter()
        }
    }
    
    // MARK: - MapView SetRegion
    
    private func ShowCurrentLocationOnMapCenter() {
        
        let region = MKCoordinateRegionMakeWithDistance(GPSTracker.sharedTracker.currentLocation.coordinate,
                                                        500 , 500)
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - Search Text Delegate
    
    // Clicked Search
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        print("👇👇  Tapped Search Button")
        if !IsBlank(textSearch) {
            SearchLocation(textSearch.text!)
        }
        dismissKeyboard()
        
        return false
    }
    
    
    // MARK: - Location Search
    
    private func SearchLocation(locationName: String) {
        
//        ShowLoading("Searching...")
        let localSearchRequest = MKLocalSearchRequest()
        localSearchRequest.naturalLanguageQuery = locationName
        let localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.startWithCompletionHandler { (localSearchResponse, error) in
            
            if localSearchResponse == nil {
            
                self.mProgress.hideAnimated(true)
                let alertController = UIAlertController(title: nil, message: "Place Not Found", preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
                return
            }
            
            let pointAnnotation = MKPointAnnotation()
            for item in localSearchResponse!.mapItems {
                let placemark = item.placemark
//                let placemark = localSearchResponse!.mapItems.first!.placemark
                pointAnnotation.coordinate = placemark.coordinate
                pointAnnotation.title = locationName
                let region = MKCoordinateRegionMakeWithDistance(pointAnnotation.coordinate, 500 , 500)
                self.mapView.setRegion(region, animated: true)
//                APIHandler.getNearbyPokemons(location: CLLocation(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude),
//                    radius: GPSTracker.radius)
                self.searchAnnotationView = MKAnnotationView(annotation: pointAnnotation, reuseIdentifier: "SearchPokemonAnnotation")
                self.mapView.addAnnotation(self.searchAnnotationView.annotation!)
            }
            
        }
        print("👉👉  Successfully Searched")
    }
    
    // MARK: - MapView Delegate
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if !(annotation is CustomPointAnnotation) {
            
            if searchAnnotationView == nil {
                return nil
            }
            let reuseId = "SearchPokemonAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
            let pinImage = UIImage(named: "PinMarker")
            let size = CGSize(width: 40.0, height: 50.0)
            UIGraphicsBeginImageContext(size)
            pinImage?.drawInRect(CGRectMake(0, 0, size.width, size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            annotationView?.image = resizedImage
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        
        let reuseId = "PokemonAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        annotationView?.bounds = CGRectMake(0, 0, 40, 50)
        
        let imgURL = (annotation as! CustomPointAnnotation).pinImageURL
        let request: NSURLRequest = NSURLRequest(URL: NSURL(string: imgURL)!)
        NSURLConnection.sendAsynchronousRequest(request,
                                                queue: NSOperationQueue.mainQueue())
        { (response, data, error) in
            if error == nil {
                let pinImage = UIImage(data: data!)
                let size = CGSize(width: 40.0, height: 40.0)
                UIGraphicsBeginImageContext(size)
                pinImage?.drawInRect(CGRectMake(0, 0, size.width, size.height))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                annotationView?.image = resizedImage
            }
        }
        let frame = CGRectMake(0, 40, 40, 10)
        let timeLabel = UILabel(frame: frame)
        timeLabel.font = timeLabel.font.fontWithSize(15)
        timeLabel.textAlignment = NSTextAlignment.Center
        timeLabel.text = (annotation as! CustomPointAnnotation).pinTimeLabel
        annotationView?.addSubview(timeLabel)
        return annotationView
    }
    
    private func GetTimeFromStamp(stamp: Double) -> String{
        
        let date = NSDate(timeIntervalSince1970: stamp)
        print(date)
        let calendar = NSCalendar.currentCalendar()
        let comp = calendar.components([.Hour, .Minute], fromDate: date)
        return ("\(comp.hour):\(comp.minute)")
    }
    
    
    // MARK: - GetNearbyPokemons Delegate
    
    func getNearbyPokemonsSucceed(responseObject: AnyObject) {
        
        APIHandler.getNearbyPokemonsDelegate = nil
        CheckLoadingStatus()
        
        let responseJSONObject = JSON(responseObject)
        if responseJSONObject["status"].stringValue == "success" {
            print("👉👉 Successfully Get Nearby Pokemons")
            Pokemon.saveNearbyPokemons(responseJSONObject["pokemons"].arrayValue, completion: {
                self.ShowNearbyPokemons()
            })
        } else {
            print("💀💀 Error in Get Nearby Pokemons")
            JLToast.makeText(Constants.Messages.ERROR_IN_SERVICE, delay: 0.0, duration: 2.0)
        }
    }
    
    func getNearbyPokemonsFailed(error: NSError) {
        
        APIHandler.getNearbyPokemonsDelegate = nil
        CheckLoadingStatus()
        print("💀💀 Error in getNearbyPokemons API: \(error.localizedDescription)")
    }
    
    // Save Nearby Pokemons

    private func ShowNearbyPokemons() {
        
        mapView.removeAnnotations(mapView.annotations)
        for nearbyPokemon in Pokemon.allNearbyPokemons {
            
            let position = CLLocationCoordinate2DMake(nearbyPokemon.latitude, nearbyPokemon.longitude)
            let pokemon = Pokemon.allPokemons.filter({$0.id == nearbyPokemon.pokemon_id}).first!
            let pointAnnotation = CustomPointAnnotation()
            pointAnnotation.coordinate = position
            pointAnnotation.title = pokemon.name
            pointAnnotation.subtitle = GetTimeFromStamp(nearbyPokemon.disappear_time)
            pointAnnotation.pinImageURL = Constants.APIEndpoints.BaseURL + pokemon.imageURL
            pointAnnotation.pinTimeLabel = GetTimeFromStamp(nearbyPokemon.disappear_time)
            let annotationView = MKAnnotationView(annotation: pointAnnotation, reuseIdentifier: "PokemonAnnotation")
            self.mapView.addAnnotation(annotationView.annotation!)
        }
        
        if searchAnnotationView != nil {
            self.mapView.addAnnotation(searchAnnotationView.annotation!)
        }
    }
    
    private func ShowNearbyPokemonsFiltered() {
        
        mapView.removeAnnotations(mapView.annotations)
        for nearbyPokemon in Pokemon.allNearbyPokemons {
            
            if !filteredPokemonList.map({$0.id}).contains(nearbyPokemon.pokemon_id) {
                continue
            }
            
            let position = CLLocationCoordinate2DMake(nearbyPokemon.latitude, nearbyPokemon.longitude)
            let pokemon = Pokemon.allPokemons.filter({$0.id == nearbyPokemon.pokemon_id}).first!
            let pointAnnotation = CustomPointAnnotation()
            pointAnnotation.coordinate = position
            pointAnnotation.title = pokemon.name
            pointAnnotation.subtitle = GetTimeFromStamp(nearbyPokemon.disappear_time)
            pointAnnotation.pinImageURL = Constants.APIEndpoints.BaseURL + pokemon.imageURL
            pointAnnotation.pinTimeLabel = GetTimeFromStamp(nearbyPokemon.disappear_time)
            let annotationView = MKAnnotationView(annotation: pointAnnotation, reuseIdentifier: "PokemonAnnotation")
            self.mapView.addAnnotation(annotationView.annotation!)
        }
        
        if searchAnnotationView != nil {
            self.mapView.addAnnotation(searchAnnotationView.annotation!)
        }
    }
    
    // MARK: - GetAllPokemons Delegate
    
    func getAllPokemonsSucceed(responseObject: AnyObject) {
        
        APIHandler.getAllPokemonsDelegate = nil
        CheckLoadingStatus()
        
        let responseJSONObject = JSON(responseObject)
        if responseJSONObject["status"].stringValue == "success" {
            
            print("👉👉 Successfully Get All Pokemons")
            Pokemon.saveAllPokemons(responseJSONObject["pokemons"].arrayValue)
            
        } else {
            print("💀💀 Error in Get All Pokemons")
            JLToast.makeText(Constants.Messages.ERROR_IN_SERVICE, delay: 0.0, duration: 3.0)
        }
        
    }
    
    func getAllPokemonsFailed(error: NSError) {
        
        print("💀💀 Error in getAllPokemons API: \(error.localizedDescription)")
        APIHandler.getAllPokemonsDelegate = nil
        CheckLoadingStatus()
        JLToast.makeText(Constants.Messages.CONNECTION_FAILED, delay: 0.0, duration: 3.0).show()
    }
    
    // Check Loading Status
    
    private func CheckLoadingStatus() {

        if APIHandler.getAllPokemonsDelegate == nil && APIHandler.getNearbyPokemonsDelegate == nil {
            
            // Hide Loading
            mProgress.hideAnimated(true)
        }
    }
    
    
    // MARK: - TabelView Delegate
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        return 50.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return selectedList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("PokemonTableViewCell", forIndexPath: indexPath) as! PokemonTableViewCell
        let pokemon = selectedList[indexPath.row]
        cell.imgPokemon.load(Constants.APIEndpoints.BaseURL + pokemon.imageURL)
        cell.lblPokemonName.text = pokemon.name
        if checkList[indexPath.row] {
            cell.imgCheckMark.image = UIImage(named: "CheckMark")
        } else {
            cell.imgCheckMark.image = UIImage()
        }
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! PokemonTableViewCell
        if checkList[indexPath.row] {
            checkList[indexPath.row] = false
            cell.imgCheckMark.image = UIImage()
        } else {
            checkList[indexPath.row] = true
            cell.imgCheckMark.image = UIImage(named: "CheckMark")
        }
    }
    
    // MARK: - Navigation Function
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "gotoAddPokemon" || segue.identifier == "gotoLogout" {

        }
    }
}

