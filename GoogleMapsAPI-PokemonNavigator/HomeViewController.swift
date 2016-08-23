//
//  HomeViewController.swift
//  PokeNavigator
//
//  Created by Cristian Mungiu on 7/18/16.
//  Copyright © 2016 Cristian Mungiu. All rights reserved.
//

import UIKit
import GoogleMaps
import SwiftyJSON
import JLToast
import ImageLoader
import MBProgressHUD


class HomeViewController: AppViewController, GMSMapViewDelegate, GPSTrackerDelegate, GetNearbyPokemonsDelegate, GetCommonPokemonDelegate, GetAllPokemonsDelegate, UIScrollViewDelegate {
    
    var nearbyPokemonIDs: [UInt] = []
    var mProgress: MBProgressHUD!
    
    private var width: CGFloat!
    private var height: CGFloat!
    
    private var visibleX: CGFloat!
    private var currentPage: UInt!
    private var isForward: Bool!
    private var maxPageMinusThree: UInt!
    
    @IBOutlet weak var viewMap: GMSMapView!
    @IBOutlet weak var viewCommonPokemon: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var buttonPrev: UIButton!
    @IBOutlet weak var buttonNext: UIButton!
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
        InitMapView()        
        InitCommonPokemonView()
        InitDelegates()
        
		nearbyPokemonIDs = []
        
        showSharing("Loading...")
	}

    override func viewWillAppear(animated: Bool) {
        
        InitNavigationBar()
        GPSTracker.getUpdateUserLocationDelegate = self
        APIHandler.getNearbyPokemonsDelegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        GPSTracker.getUpdateUserLocationDelegate = nil
    }
    
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
    
    private func showSharing(lblTitle : String){
        mProgress = MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().keyWindow!, animated: true)
        mProgress.mode = MBProgressHUDMode.AnnularDeterminate
        mProgress.label.text = lblTitle
        
        mProgress.showAnimated(true)
    }
    
    // MARK: - Initialize
    
    // Check UserProfileButton Avaliablity
    private func InitNavigationBar() {
        
        if gCurrentUserInfo != nil{
            
            setUserProfileButton()
        } else {
            
            removeUserProfileButton()
        }
    }
    
    // MapView Initialize
    private func InitMapView() {
        
        viewMap.clear()
        viewMap.myLocationEnabled = true
        viewMap.settings.myLocationButton = true
        viewMap.delegate = self
    }
    
    // Delegates Initialize
    private func InitDelegates() {
        
        APIHandler.getCommonPokemonDelegate = self
        APIHandler.getAllPokemonsDelegate = self
    }
    
    // Common Pokemon Initialize
    private func InitCommonPokemonView() {
        
        viewCommonPokemon.setCornerRadius(cornerRadius: 3.0)
        viewCommonPokemon.setShadow(offset: 2.0, radius: 1.0, opacity: 0.5)
        viewCommonPokemon.hidden = true
        backgroundView.setCornerRadius(cornerRadius: 3.0)
        APIHandler.getCommonPokemons()
    }
    
    // MARK: - Show Common Pokemon

    private func ShowCommonPokemon() {
        
        APIHandler.getCommonPokemonDelegate = nil        
        
        width = scrollView.frame.size.width / 3
        height = scrollView.frame.size.height
        
        scrollView.delegate = nil
        scrollView.contentSize = CGSizeMake(width * CGFloat(Pokemon.commonPokemons.count), height)
        currentPage = 0
        
        for subview in scrollView.subviews {
            subview.removeFromSuperview()
        }
        
        viewCommonPokemon.hidden = false
        buttonPrev.hidden = true
        buttonNext.hidden = true
        
        switch Pokemon.commonPokemons.count {
        case 0:
            
            JLToast.makeText("There is not common pokemon.", delay: 0.0, duration: 2.0).show()
            viewCommonPokemon.hidden = true
            break
        case 1:
            
            let imageView = UIImageView(frame: CGRectMake(width * 1.5, 0.0, width, height))
            imageView.load(Constants.APIEndpoints.BaseURL + Pokemon.commonPokemons[0].imageURL)
            scrollView.addSubview(imageView)
            break
        case 2:
            
            let imageViewI = UIImageView(frame: CGRectMake(width / 3, 0.0, width, height))
            let imageViewII = UIImageView(frame: CGRectMake(width * 5 / 3, 0.0, width, height))
            imageViewI.load(Constants.APIEndpoints.BaseURL + Pokemon.commonPokemons[0].imageURL)
            imageViewII.load(Constants.APIEndpoints.BaseURL + Pokemon.commonPokemons[1].imageURL)
            scrollView.addSubview(imageViewI)
            scrollView.addSubview(imageViewII)
            break
        case 3:
            
            LoadCommonPokemonsOnScrollView()
            break
        default: // is more than 3
            
            buttonPrev.hidden = true
            buttonNext.hidden = false
            scrollView.delegate = self
            LoadCommonPokemonsOnScrollView()
            break
        }
    }
    
    // Load Common Pokemons On ScrollView
    private func LoadCommonPokemonsOnScrollView() {
        
        for (index, commonPokemon) in Pokemon.commonPokemons.enumerate() {
        
            let imageView = UIImageView(frame: CGRectMake(width * CGFloat(index), 0, width, height))
            imageView.load(Constants.APIEndpoints.BaseURL + commonPokemon.imageURL)
            scrollView.addSubview(imageView)
        }
    }
    
    // MARK: - Button Clicked Prev/Next
    
    // Clicked Previous Button
    @IBAction func btnPrevClicked(sender: UIButton) {
        
        scrollView.delegate = nil
        if currentPage > 0 {
            
            ScrollToPrev()
            if currentPage <= 0 {
                buttonPrev.hidden = true
            }
            buttonNext.hidden = false
        }
        scrollView.delegate = self
    }
    
    // Clicked Next Button
    @IBAction func btnNextClicked(sender: UIButton) {
        
        scrollView.delegate = nil
        if currentPage < maxPageMinusThree {
            
            ScrollToNext()
            if currentPage >= maxPageMinusThree {
                buttonNext.hidden = true
            }
            buttonPrev.hidden = false
        }
        scrollView.delegate = self
    }
    
    // Scroll To Indicated Rect
    private func ScrollToPrev() {
        currentPage = currentPage - 1
        let rect = CGRectMake(CGFloat(currentPage) * width, 0, width * 3, height)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
    
    private func ScrollToNext() {
        currentPage = currentPage + 1
        let rect = CGRectMake(CGFloat(currentPage) * width, 0, width * 3, height)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
    
    // MARK: - Set UserProfileButton
    
    private func setUserProfileButton() {
        
        let userSilhouetteButtonImage = UIImage(named: "UserSilhouette")
        let buttonUserProfile = UIButton()
        buttonUserProfile.setImage(userSilhouetteButtonImage, forState: .Normal)
        buttonUserProfile.frame = CGRectMake(0, 0, 25.0, 25.0)
        buttonUserProfile.addTarget(self, action: #selector(HomeViewController.barButtonUserProfileClicked), forControlEvents: UIControlEvents.TouchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttonUserProfile)
    }
    
    private func removeUserProfileButton() {
        
        navigationItem.rightBarButtonItems = []
    }
    
    @objc private func barButtonUserProfileClicked() {
        print("👆🏽👆🏽UserProfile Clicked...")
        self.performSegueWithIdentifier("gotoLogout", sender: self)
    }
    
    // MARK: - Clicked AddPokemon
    
    @IBAction func btnAddPokemonClicked(sender: UIButton) {
        
        // Check Local DB Status
        
        if CheckFetchPokemonData() {
            
            if !Reachability.isConnectedToNetwork() {
                JLToast.makeText(Constants.Messages.CONNECTION_FAILED, delay: 0.0, duration: 2.0).show()
                return
            }
        } else {
            return
        }
        
        print("👆🏽👆🏽Add Button Clicked...")
        var nextVCIdentifier = ""
        if gCurrentUserInfo != nil{
            nextVCIdentifier = "gotoAddPokemon" // gotoAddPokemon
        }
        else{
            nextVCIdentifier = "gotoLogin" // gotoLogin
        }
        self.performSegueWithIdentifier(nextVCIdentifier, sender: self)
    }
    
    // MARK: - GPSTracker Delegate
    
    // Update location
    func UpdateGPSTracker(didUpdateLocation location: CLLocation) {
        
        if (GPSTracker.oldLocation == nil) ||
            (GPSTracker.oldLocation != nil && checkDistance(NewLocation: location,
                                                            OldLocation: GPSTracker.oldLocation,
                                                            LimitedDistance: GPSTracker.limitedDistance)) {
            
            viewMap.camera.target
            viewMap.camera = GMSCameraPosition(target: location.coordinate,
                                               zoom: GPSTracker.zoomValue,
                                               bearing: 0.0,
                                               viewingAngle: 0.0)
            
            GPSTracker.oldLocation = location
//            let demiLocation = CLLocation(latitude: 23.3, longitude: 23.3)
            APIHandler.getNearbyPokemons(location: location, radius: GPSTracker.radius)
        }
    }
    
    // Check If Distance Between Two Points(New, Old) Is More Than Limited Distance
    private func checkDistance(NewLocation newLocation: CLLocation,
                       OldLocation oldLocation: CLLocation,
               LimitedDistance limitedDistance: Double) -> Bool {
        
        let meters: CLLocationDistance = newLocation.distanceFromLocation(oldLocation)
        return meters > limitedDistance ? true : false
    }
    
    
    // MARK: - GetNearbyPokemons Delegate
    
    func getNearbyPokemonsSucceed(responseObject: AnyObject) {
        let responseJSONObject = JSON(responseObject)
        if responseJSONObject["status"].stringValue == "success" {
            print("👉👉 Successfully Get Nearby Pokemons")
            ShowNearbyPokemons(responseJSONObject["pokemons"].arrayValue)
            APIHandler.getDropAndNearbyPokemonDelegate?.getDropAndNearbyPokemonSucceed(responseObject)
        } else {
            print("💀💀 Error in Get Nearby Pokemons")
            JLToast.makeText(Constants.Messages.ERROR_IN_SERVICE, delay: 0.0, duration: 2.0)
        }
    }
    
    func getNearbyPokemonsFailed(error: NSError) {
        print("💀💀 Error in getNearbyPokemons API: \(error.localizedDescription)")
        APIHandler.getDropAndNearbyPokemonDelegate?.getDropAndNearbyPokemonFailed(error)
    }
    
    // Save Nearby Pokemons
    private func ShowNearbyPokemons(responseObject: [JSON]) {
        
        for response in responseObject {
            
            let pokemon = Pokemon.nearbyPokemon(id: response["id"].uIntValue,
                                              pokemon_id: response["pokemon_id"].uIntValue,
                                              latitude: response["latitude"].doubleValue,
                                              longitude: response["longitude"].doubleValue,
                                              imageURL: response["image"].stringValue)
            if !nearbyPokemonIDs.contains(pokemon.id) {
                nearbyPokemonIDs.append(pokemon.id)
                let position = CLLocationCoordinate2DMake(pokemon.latitude, pokemon.longitude)
                let marker = GMSMarker(position: position)
                print(Constants.APIEndpoints.BaseURL + pokemon.imageURL)
                let imageView = UIImageView(frame: CGRectMake(0, 0, 50.0, 50.0))
                imageView.load(Constants.APIEndpoints.BaseURL + pokemon.imageURL)
                marker.iconView = imageView
                marker.map = viewMap
            }
        }
    }
    
    // MARK: - GetCommonPokemon Delegate
    func getCommonPokemonSucceed(response: JSON) {
        
        let arrayPokemonsJSON = response["pokemons"].arrayValue
        Pokemon.saveCommonPokemons(arrayPokemonsJSON)
        ShowCommonPokemon()
        
        maxPageMinusThree = UInt(arrayPokemonsJSON.count - 3)
        
        APIHandler.getCommonPokemonDelegate = nil
        
        if CheckFetchPokemonData() {
            mProgress.hideAnimated(true)
        }
    }
    
    func getCommonPokemonFailed(error: NSError) {
        
        APIHandler.getCommonPokemonDelegate = nil
        
        if CheckFetchPokemonData() {
            mProgress.hideAnimated(true)
        }
        JLToast.makeText(error.localizedDescription, delay: 0.0, duration: 2.0)
    }
    
    // MARK: - GetAllPokemons Delegate
    func getAllPokemonsSucceed() {
        
        APIHandler.getAllPokemonsDelegate = nil
        
        if CheckFetchPokemonData() {
            mProgress.hideAnimated(true)
        }
    }
    
    func getAllPokemonsFailed(error: NSError) {
        
        APIHandler.getCommonPokemonDelegate = nil
        
        if CheckFetchPokemonData() {
            mProgress.hideAnimated(true)
        }
        JLToast.makeText(Constants.Messages.CONNECTION_FAILED, delay: 0.0, duration: 2.0).show()
    }
    
    
    // MARK: - Check All Pokemons & Common Pokemons
    
    func CheckFetchPokemonData() -> Bool {
        
        if APIHandler.getAllPokemonsDelegate == nil && APIHandler.getCommonPokemonDelegate == nil {
            return true
        }
        return false
    }
    
    
    // MARK: - UIScrollViewDelegate
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        visibleX = scrollView.bounds.origin.x
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.x > visibleX {
            isForward = true
        } else {
            isForward = false
        }
        
        if !decelerate {
            scrollView.scrollRectToVisible(calculateScrollPosition(), animated: true)
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let scrollRect = calculateScrollPosition()
        scrollView.scrollRectToVisible(scrollRect, animated: true)
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        
//        SetCurrentPageByScrollPosition()
    }
    
    private func SetCurrentPageByScrollPosition() {
        
        let pageFloat = scrollView.bounds.origin.x / width
        if pageFloat < 0 {
            currentPage = 0
        } else if pageFloat > CGFloat(maxPageMinusThree) {
            currentPage = maxPageMinusThree
        } else {
            currentPage = UInt(pageFloat)
        }
        
    }
    
    private func calculateScrollPosition() -> CGRect {
        
        if isForward == true {
            currentPage = UInt(ceil(scrollView.contentOffset.x / width))
            if currentPage > maxPageMinusThree {
                currentPage = maxPageMinusThree
            }
        } else {
            let pageFloat = scrollView.contentOffset.x / width
            if pageFloat < 0 {
                currentPage = 0
            } else if pageFloat > CGFloat(maxPageMinusThree) {
                currentPage = maxPageMinusThree
            } else {
                currentPage = UInt(pageFloat)
            }
        }
        
        if currentPage == maxPageMinusThree {
            buttonPrev.hidden = false
            buttonNext.hidden = true
        } else if currentPage == 0 {
            buttonPrev.hidden = true
            buttonNext.hidden = false
        } else {
            buttonPrev.hidden = false
            buttonNext.hidden = false
        }
        
        return CGRectMake(width * CGFloat(currentPage), 0, width * 3, height)
    }
    
    private func calculateScrollPositionAfterDecelerating() -> CGRect {
        
        currentPage = UInt(ceil(scrollView.contentOffset.x / width))
        return CGRectMake(width * CGFloat(currentPage), 0, width * 3, height)
    }
    
    // MARK: - Navigation Function
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "gotoAddPokemon" || segue.identifier == "gotoLogout" {
            
            setBackButton()
        }
    }
}

