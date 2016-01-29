//
//  TDGraphVC.swift
//  Badminton
//
//  Created by Paul Leo on 05/11/2015.
//  Copyright © 2015 TapDigital Ltd. All rights reserved.
//

import UIKit
import Foundation
import CorePlot
import HealthKit
import JGProgressHUD
import MHPrettyDate
import DateTools

class TDGraphVC: UIViewController, CPTScatterPlotDataSource, CPTScatterPlotDelegate, CPTPlotSpaceDelegate, UIToolbarDelegate {
    @IBOutlet var graphView: CPTGraphHostingView!
    var HUD : JGProgressHUD?

    @IBOutlet weak var toolBar: UIToolbar!
    
    let energyUnit = HKUnit.calorieUnit()
    let distanceUnit = HKUnit.meterUnit()
    let stepUnit = HKUnit.countUnit()
    let countPerMinuteUnit = HKUnit(fromString: "count/min")
    var currentUnit = HKUnit(fromString: "count/min")
    
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
    
    let plotFactory = TDCorePlotFactory(startDate: NSDate(), endDate: NSDate())
    
    private var _bpmPlotRange = CPTMutablePlotRange(location: -20, length: 250)
    
    var plotSpace : CPTXYPlotSpace?
    let graph = CPTXYGraph(frame: CGRectZero)
    var maxHRValue = Double(0)
    var minHRValue = Double.infinity
    var touchedPoint : HKQuantitySample?
    var symbolTextAnnotation : CPTPlotSpaceAnnotation?
    
    //MARK: - Lifecycle events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = MHPrettyDate.prettyDateFromDate(plotFactory.startDate, withFormat: MHPrettyDateFormatNoTime)
        
        toolBar.delegate = self
        
        configureGraph()
        configureGraphForType(.Heartrate)
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
    
    //MARK: - Configured Graph
    
    func configureGraph() {
        // create graph
        graph.title = "Workout"
        graph.paddingLeft = 0
        graph.paddingTop = 0
        graph.paddingRight = 0
        graph.paddingBottom = 0
        
        let theme = CPTTheme(named: kCPTPlainWhiteTheme)
        graph.applyTheme(theme)
        
        plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace
        plotSpace?.allowsUserInteraction = true
        plotSpace?.delegate = self
        
        self.graphView.hostedGraph = graph
    }
  
    
    func configureGraphForType(type: TDPlotType) {
        plotFactory.resetPlots(graph)
        
        // Create energy calorie plot
        guard let energyLinePlot = plotFactory.createCorePlotForType(type) else {return}
        energyLinePlot.dataSource = self
        energyLinePlot.delegate = self
        graph.addPlot(energyLinePlot)
        configureTouchPlot()

        guard let x = plotFactory.configureTimeXAxisForGraph(graph),
            y = plotFactory.createAxisForType(graph, type:type) else { return }
        
        // Set axes
        graph.axisSet?.axes = [x, y]
        
        HUD = JGProgressHUD(style: JGProgressHUDStyle.Light)
        HUD?.showInView(self.view)
        HUD?.dismissAfterDelay(15.0)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            var query : HKQuery?
            switch type {
            case .Heartrate:
                if heartRateSamples.count > 0 {
                    savePeakHRValues()
                    refreshGraph(TDPlotType.Heartrate.rawValue)
                } else {
                    query = createStreamingHeartRateQuery()
                }
            case .Calories:
                if energySamples.count > 0 {
                    refreshGraph(TDPlotType.Calories.rawValue)
                } else {
                    query = createStreamingEnergyQuery()
                }
            case .Steps:
                if stepSamples.count > 0 {
                    refreshGraph(TDPlotType.Steps.rawValue)
                } else {
                    query = createStreamingStepQuery()
                }
            case .Distance:
                if distanceSamples.count > 0 {
                    refreshGraph(TDPlotType.Distance.rawValue)
                } else {
                    query = createStreamingDistanceQuery()
                }
            default:
                query = createStreamingHeartRateQuery()
            }
            
            if let query = query {
                appDelegate.healthStore.executeQuery(query)
            }
        }
    }
    
    
    func configureTouchPlot() {
        guard let touchPlot = plotFactory.createCorePlotForType(.TouchInteraction) else {return}
        touchPlot.dataSource = self
        touchPlot.delegate = self
        self.graph.addPlot(touchPlot)
    }
    
    func configurePeakHRLines() {
        guard let maxLine = plotFactory.createCorePlotForType(.Maxima),
        minLine = plotFactory.createCorePlotForType(.Minima) else {return}

        maxLine.dataSource = self
        maxLine.delegate = self
        minLine.dataSource = self
        minLine.delegate = self
        
        graph.addPlot(maxLine)
        graph.addPlot(minLine)
    }
    
    
    func addPeakHRAnnotations() {
        let annotationTextStyleTop = CPTMutableTextStyle()
        annotationTextStyleTop.color = CPTColor.redColor()
        annotationTextStyleTop.fontSize = 16.0
        annotationTextStyleTop.fontName = "Helvetica-Bold"
        
        let annotationTextStyleBottom = CPTMutableTextStyle()
        annotationTextStyleBottom.color = CPTColor.orangeColor()
        annotationTextStyleBottom.fontSize = 16.0
        annotationTextStyleBottom.fontName = "Helvetica-Bold"
        
        guard let plotSpace = plotSpace else {return}
        let maxPoint = CPTPlotSpaceAnnotation(plotSpace: plotSpace, anchorPlotPoint: [0.0, maxHRValue])
        maxPoint.contentLayer = CPTTextLayer(text:String(format: "Max %.0f bpm", maxHRValue), style:annotationTextStyleTop)
        maxPoint.displacement = CGPointMake(4.0, 0.0)
        maxPoint.contentAnchorPoint = CGPointMake(0, 0)
        
        let minPoint = CPTPlotSpaceAnnotation(plotSpace: plotSpace, anchorPlotPoint: [0.0, minHRValue])
        minPoint.contentLayer = CPTTextLayer(text:String(format: "Min %.0f bpm", minHRValue), style:annotationTextStyleBottom)
        minPoint.displacement = CGPointMake(4.0, 0.0)
        minPoint.contentAnchorPoint = CGPointMake(0, 1)
        
        graph.addAnnotation(maxPoint)
        graph.addAnnotation(minPoint)
    }
    
    //MARK: - CPTPlotDataSource events
    
    func numberOfRecordsForPlot(plot: CPTPlot) -> UInt {
        var count : UInt = 0
        
        switch (plot.identifier) {
        case (let id as String) where id == TDPlotType.Heartrate.rawValue:
            count = UInt(heartRateSamples.count)
            LogMessage("BPM", 0, "heartRateSamples sample count = \(count)")
        case (let id as String) where id == TDPlotType.Calories.rawValue:
            count = UInt(energySamples.count)
            LogMessage("Energy", 0, "energySamples sample count = \(count)")
        case (let id as String) where id == TDPlotType.Steps.rawValue:
            count = UInt(stepSamples.count)
            LogMessage("Steps", 0, "stepSamples sample count = \(count)")
        case (let id as String) where id == TDPlotType.Distance.rawValue:
            count = UInt(distanceSamples.count)
            LogMessage("Distance", 0, "distanceSamples sample count = \(count)")
        case (let id as String) where id == TDPlotType.Maxima.rawValue || id == TDPlotType.Minima.rawValue:
            count = 2
        case (let id as String) where id == TDPlotType.TouchInteraction.rawValue && touchedPoint != nil:
            count = 3
        default:
            return count
        }
        
        return count
    }
    
    
    func numberForPlot(plot: CPTPlot, field fieldEnum: UInt, recordIndex idx: UInt) -> AnyObject? {
        let x = UInt(CPTScatterPlotField.X.rawValue)
        let y = UInt(CPTScatterPlotField.Y.rawValue)
        
        var quant : HKQuantitySample
        
        switch (plot.identifier, fieldEnum) {
        case (let id as String, x) where id == TDPlotType.Heartrate.rawValue:
            quant = heartRateSamples[Int(idx)]
            let seconds = quant.startDate.timeIntervalSinceDate(plotFactory.startDate)
            return seconds
        case (let id as String, y) where id == TDPlotType.Heartrate.rawValue:
            quant = heartRateSamples[Int(idx)]
            let dValue = quant.quantity.doubleValueForUnit(countPerMinuteUnit)
            let seconds = quant.startDate.timeIntervalSinceDate(plotFactory.startDate)
            LogMessage("BPM", 0, String(format:"(%.0fs, %.0fbpm)", seconds, dValue))
            return dValue
        case (let id as String, x) where id == TDPlotType.Calories.rawValue:
            quant = energySamples[Int(idx)]
            let seconds = quant.startDate.timeIntervalSinceDate(plotFactory.startDate)
            return seconds
        case (let id as String, y) where id == TDPlotType.Calories.rawValue:
            quant = energySamples[Int(idx)]
            let dValue = quant.quantity.doubleValueForUnit(energyUnit)
            let seconds = quant.startDate.timeIntervalSinceDate(plotFactory.startDate)
            LogMessage("Energy", 0, String(format:"(%.0fs, %.0fcal)", seconds, dValue))
            return dValue
        case (let id as String, x) where id == TDPlotType.Steps.rawValue:
            quant = stepSamples[Int(idx)]
            let seconds = quant.startDate.timeIntervalSinceDate(plotFactory.startDate)
            return seconds
        case (let id as String, y) where id == TDPlotType.Steps.rawValue:
            quant = stepSamples[Int(idx)]
            let dValue = quant.quantity.doubleValueForUnit(stepUnit)
            let seconds = quant.startDate.timeIntervalSinceDate(plotFactory.startDate)
            LogMessage("Steps", 0, String(format:"(%.0fs, %.0fsteps)", seconds, dValue))
            return dValue
        case (let id as String, x) where id == TDPlotType.Distance.rawValue:
            quant = distanceSamples[Int(idx)]
            let seconds = quant.startDate.timeIntervalSinceDate(plotFactory.startDate)
            return seconds
        case (let id as String, y) where id == TDPlotType.Distance.rawValue:
            quant = distanceSamples[Int(idx)]
            let dValue = quant.quantity.doubleValueForUnit(distanceUnit)
            let seconds = quant.startDate.timeIntervalSinceDate(plotFactory.startDate)
            LogMessage("Distance", 0, String(format:"(%.0fs, %.0fm)", seconds, dValue))
            return dValue
        case (let id as String, x) where id == TDPlotType.Maxima.rawValue || id == TDPlotType.Minima.rawValue:
            if idx == 0 {
                return 0
            } else {
                return plotFactory.endDate.timeIntervalSinceDate(plotFactory.startDate)
            }
        case (let id as String, y) where id == TDPlotType.Maxima.rawValue:
            return maxHRValue
        case (let id as String, y) where id == TDPlotType.Minima.rawValue:
            return minHRValue
        case (let id as String, x) where id == TDPlotType.TouchInteraction.rawValue && touchedPoint != nil:
            return touchedPoint?.startDate.timeIntervalSinceDate(plotFactory.startDate)
        case (let id as String, y) where id == TDPlotType.TouchInteraction.rawValue && touchedPoint != nil:
            let bpm = touchedPoint?.quantity.doubleValueForUnit(currentUnit)
            if idx == 0 {
                return -200
            } else if idx == 1 {
                return bpm
            } else {
                return 500
            }
        default:
            return nil
        }
    }
    
    //MARK: - CPTPlotSpaceDelegate events
    
    func plotSpace(space: CPTPlotSpace, shouldScaleBy interactionScale: CGFloat, aboutPoint interactionPoint: CGPoint) -> Bool {
        return true
    }
    
    func plotSpace(space: CPTPlotSpace, willChangePlotRangeTo newRange: CPTPlotRange, forCoordinate coordinate: CPTCoordinate) -> CPTPlotRange? {
        if CPTCoordinate.Y == coordinate && currentUnit == countPerMinuteUnit {
            return _bpmPlotRange
        }
        
        return newRange
    }
    
    func scatterPlot(plot: CPTScatterPlot, plotSymbolWasSelectedAtRecordIndex idx: UInt, withEvent event: UIEvent) {
        if let annotation1 = symbolTextAnnotation {
            graph.removeAnnotation(annotation1)
            symbolTextAnnotation = nil
            touchedPoint = nil
        }
        
        switch (plot.identifier) {
        case (let id as String) where id == TDPlotType.Heartrate.rawValue:
            touchedPoint = heartRateSamples[Int(idx)]
            currentUnit = countPerMinuteUnit
        case (let id as String) where id == TDPlotType.Calories.rawValue:
            touchedPoint = energySamples[Int(idx)]
            currentUnit = energyUnit
        case (let id as String) where id == TDPlotType.Steps.rawValue:
            touchedPoint = stepSamples[Int(idx)]
            currentUnit = stepUnit
        case (let id as String) where id == TDPlotType.Distance.rawValue:
            touchedPoint = distanceSamples[Int(idx)]
            currentUnit = distanceUnit
        case (let id as String) where id == TDPlotType.Maxima.rawValue || id == TDPlotType.Minima.rawValue || id == TDPlotType.TouchInteraction.rawValue:
            refreshGraph(TDPlotType.TouchInteraction.rawValue)
            return
        default:
            return
        }
        
        // Setup a style for the annotation
        let hitAnnotationTextStyle = CPTMutableTextStyle()
        hitAnnotationTextStyle.color    = CPTColor.blueColor()
        hitAnnotationTextStyle.fontSize = 16.0
        hitAnnotationTextStyle.fontName = "Helvetica-Bold";
        
        if let x = touchedPoint?.startDate.timeIntervalSinceDate(plotFactory.startDate),
            y = touchedPoint?.quantity.doubleValueForUnit(currentUnit) {
                
                guard let axisSet = graph.axisSet as? CPTXYAxisSet,
                    xAxis = axisSet.xAxis,
                    formatter = xAxis.labelFormatter as? CPTTimeFormatter,
                    time = formatter.stringFromNumber(x) else { return }
                
                let coordString = String(format: "%.0f\n%@", y, time)
                LogMessage("BPM", 0, coordString)
                
                guard let plotSpace = plotSpace else {return}
                
                let textLayer = CPTTextLayer(text:coordString, style:hitAnnotationTextStyle)
                let annotation = CPTPlotSpaceAnnotation(plotSpace:plotSpace, anchorPlotPoint:[x, y])
                annotation.contentLayer   = textLayer
                annotation.displacement   = CGPointMake(2.0, 2.0)
                annotation.contentAnchorPoint = CGPointMake(0, 0)
                self.symbolTextAnnotation = annotation
                self.graph.addAnnotation(annotation)
                
                refreshGraph(TDPlotType.TouchInteraction.rawValue)
        }
    }

    
    //MARK: - Data queries
    
    func createStreamingDistanceQuery() -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let distanceQuery = HKSampleQuery(sampleType: self.distanceType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { _, samples, error in
            
            switch (samples, error) {
            case (let quantitySamples?, nil) :
                self.distanceSamples = quantitySamples as! [HKQuantitySample]
                self.refreshGraph(TDPlotType.Distance.rawValue)
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
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let distanceQuery = HKSampleQuery(sampleType: self.stepType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { _, samples, error in
            
            switch (samples, error) {
            case (let quantitySamples?, nil) :
                self.stepSamples = quantitySamples as! [HKQuantitySample]
                self.refreshGraph(TDPlotType.Steps.rawValue)
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
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let energyQuery = HKSampleQuery(sampleType: self.energyType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { _, samples, error in
            switch (samples, error) {
            case (let quantitySamples?, nil) :
                self.energySamples = quantitySamples as! [HKQuantitySample]
                self.refreshGraph(TDPlotType.Calories.rawValue)
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
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let heartRateQuery = HKSampleQuery(sampleType: self.heartRateType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { _, samples, error in

            switch (samples, error) {
            case (let quantitySamples?, nil) where quantitySamples.count > 0:
                self.heartRateSamples = quantitySamples as! [HKQuantitySample]
                self.savePeakHRValues()
                self.refreshGraph(TDPlotType.Heartrate.rawValue)
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
        return HKQuery.predicateForSamplesWithStartDate(plotFactory.startDate, endDate: plotFactory.endDate, options: .None)
    }
    

    func refreshGraph(identifier: String?) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.HUD?.dismissAnimated(true)
            if let id = identifier {
                self.graphView.hostedGraph?.plotWithIdentifier(id)?.reloadData()
            } else {
                self.graphView.hostedGraph?.reloadData()
            }
        }
    }
    
    func savePeakHRValues() {
        for sample in self.heartRateSamples {
            let hrVal = sample.quantity.doubleValueForUnit(countPerMinuteUnit)
            if hrVal < minHRValue {
                minHRValue = hrVal
            }
            if hrVal > maxHRValue {
                maxHRValue = hrVal
            }
        }
        
        if minHRValue < Double.infinity && maxHRValue > 0 && self.heartRateSamples.count > 2 {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.configurePeakHRLines()
                self.addPeakHRAnnotations()
                guard let axisSet = self.graph.axisSet as? CPTXYAxisSet, y = axisSet.yAxis else { return }
                guard let plotSpace = self.plotSpace else {return}
                let range = CPTPlotRange(location: self.minHRValue, length: self.maxHRValue-self.minHRValue)
                y.visibleRange = range
                self._bpmPlotRange = range.mutableCopy() as! CPTMutablePlotRange
                self._bpmPlotRange.expandRangeByFactor(1.5)
                plotSpace.globalYRange = self._bpmPlotRange
                plotSpace.yRange = range

                self.graphView.hostedGraph?.plotWithIdentifier(TDPlotType.Maxima.rawValue)?.reloadData()
                self.graphView.hostedGraph?.plotWithIdentifier(TDPlotType.Minima.rawValue)?.reloadData()
            }
        }
    }
    
    
    @IBAction func segmentCtrlChanged(sender: UISegmentedControl) {
        touchedPoint = nil
        symbolTextAnnotation = nil
      
        switch sender.selectedSegmentIndex {
        case 0:
            currentUnit = countPerMinuteUnit
            configureGraphForType(.Heartrate)
        case 1:
            currentUnit = energyUnit
            configureGraphForType(.Calories)
        case 2:
            currentUnit = stepUnit
            configureGraphForType(.Steps)
        case 3:
            currentUnit = distanceUnit
            configureGraphForType(.Distance)
        default:
            break
        }
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

