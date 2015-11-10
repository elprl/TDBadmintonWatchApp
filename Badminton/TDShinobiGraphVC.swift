//
//  TDShinobiGraphVC.swift
//  Badminton
//
//  Created by Paul Leo on 10/11/2015.
//  Copyright © 2015 TapDigital Ltd. All rights reserved.
//


import UIKit
import Foundation
import HealthKit
import JGProgressHUD
import MHPrettyDate
import DateTools

class TDShinobiGraphVC: UIViewController, UIToolbarDelegate, SChartDatasource {
    @IBOutlet weak var chart: ShinobiChart!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var segmentedCtrl: UISegmentedControl!
    var HUD : JGProgressHUD?
    var startDate = NSDate()
    var endDate = NSDate()
    
    let energyUnit = HKUnit.kilocalorieUnit()
    let distanceUnit = HKUnit.meterUnit()
    let stepUnit = HKUnit.countUnit()
    let countPerMinuteUnit = HKUnit(fromString: "count/min")
    
    let energyType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!
    let distanceType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!
    let stepType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
    let heartRateType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
    
    var energySamples: [HKQuantitySample] = []
    var distanceSamples: [HKQuantitySample] = []
    var stepSamples: [HKQuantitySample] = []
    var heartRateSamples: [HKQuantitySample] = []
    
    private let _minute : UInt = 60
    private let _hour : UInt = 60 * 60
    private let _day : UInt = 60 * 60 * 24
    
    private let _heartrateId = "Heartrate"
    private let _distanceId = "Distance"
    private let _stepsId = "Steps"
    private let _energyId = "Active Energy"
    var cumulativeEnergy : Double = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = MHPrettyDate.prettyDateFromDate(startDate, withFormat: MHPrettyDateFormatNoTime)
        
        toolBar.delegate = self
        
        setupHeartRateGraph()
        
        HUD = JGProgressHUD(style: JGProgressHUDStyle.Light)
        HUD?.showInView(self.view)
        HUD?.dismissAfterDelay(15.0)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            var queries = [HKQuery]()
            queries.append(createStreamingDistanceQuery())
            queries.append(createStreamingEnergyQuery())
            queries.append(createStreamingStepQuery())
            queries.append(createStreamingHeartRateQuery())
            for query in queries {
                appDelegate.healthStore.executeQuery(query)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let sbViews = self.navigationController?.navigationBar.subviews {
            for view in sbViews {
                if view is UIImageView {
                    view.hidden = true
                    return
                }
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let sbViews = self.navigationController?.navigationBar.subviews {
            for view in sbViews {
                if view is UIImageView {
                    view.hidden = false
                    return
                }
            }
        }
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    func setupHeartRateGraph() {
        chart.licenseKey = "gSZlTcZdCPcgvT4MjAxNTEyMTBwYXVsX3JfbGVvQGhvdG1haWwuY29ti7K9mVMIXlfcC0HTwyC0tk8xs6ZeTmohFbrdR5xgg+ohdMLdkMJ7hsDAPSeDYwLV77heqz0k1erUnEAeDOptgRJhJiNaJhZw99WtbJmmv3/1SpKMkDT/Zo9M82lBy67+G+G2CnEa3kcVHsmwUIZVJp0PRhUM=AXR/y+mxbZFM+Bz4HYAHkrZ/ekxdI/4Aa6DClSrE4o73czce7pcia/eHXffSfX9gssIRwBWEPX9e+kKts4mY6zZWsReM+aaVF0BL6G9Vj2249wYEThll6JQdqaKda41AwAbZXwcssavcgnaHc3rxWNBjJDOk6Cd78fr/LwdW8q7gmlj4risUXPJV0h7d21jO1gzaaFCPlp5G8l05UUe2qe7rKbarpjoddMoXrpErC9j8Lm5Oj7XKbmciqAKap+71+9DGNE2sBC+sY4V/arvEthfhk52vzLe3kmSOsvg5q+DQG/W9WbgZTmlMdWHY2B2nbgm3yZB7jFCiXH/KfzyE1A==PFJTQUtleVZhbHVlPjxNb2R1bHVzPnh6YlRrc2dYWWJvQUh5VGR6dkNzQXUrUVAxQnM5b2VrZUxxZVdacnRFbUx3OHZlWStBK3pteXg4NGpJbFkzT2hGdlNYbHZDSjlKVGZQTTF4S2ZweWZBVXBGeXgxRnVBMThOcDNETUxXR1JJbTJ6WXA3a1YyMEdYZGU3RnJyTHZjdGhIbW1BZ21PTTdwMFBsNWlSKzNVMDg5M1N4b2hCZlJ5RHdEeE9vdDNlMD08L01vZHVsdXM+PEV4cG9uZW50PkFRQUI8L0V4cG9uZW50PjwvUlNBS2V5VmFsdWU+"
        chart.datasource = self
//        chart.delegate = self;
        chart.legend.hidden = false
        chart.legend.position = SChartLegendPosition.BottomMiddle;
        chart.title = "Wakt Metrics"
        
        // Turn off clipsToBounds so that our tooltip can go outside of the chart area
        chart.clipsToBounds = false
        
        // Add x-axis
        let dateAxis = SChartDateTimeAxis()
        dateAxis.title = "Time"
        chart.xAxis = dateAxis
        
        // Add y-axis (heartrate)
        let heartAxis = SChartNumberAxis()
        heartAxis.title = "BMP"
        heartAxis.style.titleStyle.textColor = UIColor.redColor()
        heartAxis.minorTickFrequency = 1
        heartAxis.setRangeWithMinimum(0, andMaximum: 220)
        heartAxis.enableGesturePanning = true
        heartAxis.enableGestureZooming = true
        heartAxis.enableMomentumPanning = true
        heartAxis.enableMomentumZooming = true
        chart.yAxis = heartAxis


        chart.legend.hidden = true
    }
    
    //MARK: SChartDatasource methods
    func numberOfSeriesInSChart(chart: ShinobiChart!) -> Int {
        return 4
    }
    
    func sChart(chart: ShinobiChart!, seriesAtIndex index: Int) -> SChartSeries! {
        let lineSeries = SChartLineSeries()
        let style = lineSeries.style()
        lineSeries.hidden = segmentedCtrl.selectedSegmentIndex != index

        switch (index) {
        case 0:
//            style.showFill = true
            style.lineColor = UIColor.redColor()
            lineSeries.title = "Heartrate"
        case 1:
//            style.showFill = true
            style.lineColor = UIColor.orangeColor()
            lineSeries.title = "Calories"
        case 2:
//            style.showFill = true
            style.lineColor = UIColor.yellowColor()
            lineSeries.title = "Steps"
        case 3:
//            style.showFill = true
            style.lineColor = UIColor.blueColor()
            lineSeries.title = "Distance"
        default:
            break
        }
        
        
        lineSeries.setStyle(style)
        return lineSeries
    }
    
    
    func sChart(chart: ShinobiChart!, numberOfDataPointsForSeriesAtIndex seriesIndex: Int) -> Int {
        var count : Int = 0
        
        switch (seriesIndex) {
        case 0:
            count = heartRateSamples.count
            print("heartRateSamples sample count = \(count)")
        case 1:
            count = energySamples.count
            if count > 1 { // workaround for last value being huge, must be bug
                return count - 1
            }
            print("energySamples sample count = \(count)")
        case 2:
            count = stepSamples.count
            print("stepSamples sample count = \(count)")
        case 3:
            count = distanceSamples.count
            print("distanceSamples sample count = \(count)")
        default:
            return count
        }
        
        return count
    }
    
    
    func sChart(chart: ShinobiChart!, dataPointAtIndex dataIndex: Int, forSeriesAtIndex seriesIndex: Int) -> SChartData! {
        var quant : HKQuantitySample
        
        let pt = SChartDataPoint()
        
        switch (seriesIndex) {
        case 0:
            quant = heartRateSamples[dataIndex]
            pt.xValue = quant.startDate
            pt.yValue = quant.quantity.doubleValueForUnit(countPerMinuteUnit)
            print(pt)
            return pt
        case 1:
            quant = energySamples[dataIndex]
            pt.xValue = quant.startDate
            cumulativeEnergy += quant.quantity.doubleValueForUnit(energyUnit)
            pt.yValue = cumulativeEnergy
            print(pt)
            return pt
        case 2:
            quant = stepSamples[dataIndex]
            pt.xValue = quant.startDate
            pt.yValue = quant.quantity.doubleValueForUnit(stepUnit)
            print(pt)
            return pt
        case 3:
            quant = distanceSamples[dataIndex]
            pt.xValue = quant.startDate
            pt.yValue = quant.quantity.doubleValueForUnit(distanceUnit)
            print(pt)
            return pt
       default:
            return pt
        }
    }

    
    
    //MARK: Data queries
    
    func createStreamingDistanceQuery() -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples()
        
        let distanceQuery = HKSampleQuery(sampleType: self.distanceType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) { _, samples, error in
            
            switch (samples, error) {
            case (let quantitySamples?, nil) :
                self.distanceSamples = quantitySamples as! [HKQuantitySample]
                self.refreshGraph(self._distanceId)
            case (_, _?):
                print(error!.localizedDescription)
                fallthrough
            default:
                self.HUD?.textLabel?.text = "No Distance Data"
                self.HUD?.dismissAfterDelay(5.0)
            }
        }
        
        return distanceQuery
    }
    
    
    func createStreamingStepQuery() -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples()
        
        let distanceQuery = HKSampleQuery(sampleType: self.stepType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) { _, samples, error in
            
            switch (samples, error) {
            case (let quantitySamples?, nil) :
                self.stepSamples = quantitySamples as! [HKQuantitySample]
                self.refreshGraph(self._stepsId)
            case (_, _?):
                print(error!.localizedDescription)
                fallthrough
            default:
                self.HUD?.textLabel?.text = "No Step Data"
                self.HUD?.dismissAfterDelay(5.0)
            }
        }
        
        return distanceQuery
    }
    
    
    func createStreamingEnergyQuery() -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples()
        
        let energyQuery = HKSampleQuery(sampleType: self.energyType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) { _, samples, error in
            switch (samples, error) {
            case (let quantitySamples?, nil) :
                self.energySamples = quantitySamples as! [HKQuantitySample]
                self.refreshGraph(self._energyId)
            case (_, _?):
                print(error!.localizedDescription)
                fallthrough
            default:
                self.HUD?.textLabel?.text = "No Energy Data"
                self.HUD?.dismissAfterDelay(5.0)
            }
        }
        
        return energyQuery
    }
    
    
    func createStreamingHeartRateQuery() -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples()
        
        let heartRateQuery = HKSampleQuery(sampleType: self.heartRateType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) { _, samples, error in
            
            switch (samples, error) {
            case (let quantitySamples?, nil) where quantitySamples.count > 0:
                self.heartRateSamples = quantitySamples as! [HKQuantitySample]
                self.refreshGraph(self._heartrateId)
            case (let quantitySamples?, nil) where quantitySamples.count == 0:
                self.heartRateSamples = quantitySamples as! [HKQuantitySample]
                self.displayNoData()
            case (_, _?):
                print(error!.localizedDescription)
                fallthrough
            default:
                self.displayNoData()
            }
        }
        
        return heartRateQuery
    }
    
    func predicateFromWorkoutSamples() -> NSPredicate {
        return HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .None)
    }
    
    
    func refreshGraph(identifier: String?) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.HUD?.dismissAnimated(true)
            self.chart.reloadData()
            self.chart.redrawChart()
        }
    }
    
    
    @IBAction func segmentCtrlChanged(sender: UISegmentedControl) {
        switch (sender.selectedSegmentIndex) {
        case 0:
            // Add y-axis (heartrate)
            let heartAxis = SChartNumberAxis()
            heartAxis.title = "BMP"
            heartAxis.style.titleStyle.textColor = UIColor.redColor()
            heartAxis.minorTickFrequency = 1
            heartAxis.setRangeWithMinimum(0, andMaximum: 220)
            heartAxis.enableGesturePanning = true
            heartAxis.enableGestureZooming = true
            heartAxis.enableMomentumPanning = true
            heartAxis.enableMomentumZooming = true
            chart.yAxis = heartAxis
            
        case 1:
            // Add  y-axis (calories)
            let energyAxis = SChartNumberAxis()
            energyAxis.title = "Calories (kcal)"
            energyAxis.style.titleStyle.textColor = UIColor.orangeColor()
            energyAxis.minorTickFrequency = 1
            energyAxis.axisLabelsAreFixed = true
            energyAxis.enableGesturePanning = true
            energyAxis.enableGestureZooming = true
            energyAxis.enableMomentumPanning = false
            energyAxis.enableMomentumZooming = false
            chart.yAxis = energyAxis
            
        case 2:
            // Add  y-axis (steps)
            let stepsAxis = SChartNumberAxis()
            stepsAxis.title = "Steps"
//            stepsAxis.labelFormatString = "%.0f"
            stepsAxis.minorTickFrequency = 1
            stepsAxis.axisLabelsAreFixed = true
            stepsAxis.enableGesturePanning = true
            stepsAxis.enableGestureZooming = true
            stepsAxis.enableMomentumPanning = false
            stepsAxis.enableMomentumZooming = false
            chart.yAxis = stepsAxis
            
        case 3:
            // Add  y-axis (distance)
            let distanceAxis = SChartNumberAxis()
            distanceAxis.title = "Distance (metres)"
            distanceAxis.titleLabel.textColor = UIColor.blueColor()
//            distanceAxis.labelFormatString = "%.0f"
            distanceAxis.axisLabelsAreFixed = true
            distanceAxis.enableGesturePanning = true
            distanceAxis.enableGestureZooming = true
            distanceAxis.enableMomentumPanning = false
            distanceAxis.enableMomentumZooming = false
            chart.yAxis = distanceAxis

        default:
            break
        }

        
        chart.redrawChart()
    }
    
    func displayNoData() {
        dispatch_async(dispatch_get_main_queue()) {
            guard let hud = self.HUD else {return}
            if !hud.visible {
                self.HUD = JGProgressHUD(style: JGProgressHUDStyle.Light)
                self.HUD?.showInView(self.view)
            }
            self.HUD?.setProgress(1.0, animated: true)
            self.HUD?.dismissAfterDelay(15.0)
            self.HUD?.textLabel?.text = "No Heartrate Data"
        }
    }
}