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
    
    let energyUnit = HKUnit.smallCalorie()
    let distanceUnit = HKUnit.meter()
    let stepUnit = HKUnit.count()
    let countPerMinuteUnit = HKUnit(from: "count/min")
    var currentUnit = HKUnit(from: "count/min")
    
    let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
    let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    
    var energySamples: [HKQuantitySample] = []
    var distanceSamples: [HKQuantitySample] = []
    var stepSamples: [HKQuantitySample] = []
    var heartRateSamples: [HKQuantitySample] = []
    
    private let _minute : UInt = 60
    private let _hour : UInt = 60 * 60
    private let _day : UInt = 60 * 60 * 24
    
    let plotFactory = TDCorePlotFactory(startDate: Date(), endDate: Date())
    
    private var _bpmPlotRange = CPTMutablePlotRange(location: -20, length: 250)
    
    var plotSpace : CPTXYPlotSpace?
    let graph = CPTXYGraph(frame: CGRect.zero)
    var maxHRValue = Double(0)
    var minHRValue = Double.infinity
    var touchedPoint : HKQuantitySample?
    var symbolTextAnnotation : CPTPlotSpaceAnnotation?
    
    //MARK: - Lifecycle events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = MHPrettyDate.prettyDate(from: plotFactory.startDate, with: MHPrettyDateFormatNoTime)
        
        toolBar.delegate = self
        
        configureGraph()
        configureGraphForType(type: .Heartrate)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let sbViews = self.navigationController?.navigationBar.subviews {
            for view in sbViews {
                if view is UIImageView {
                    view.isHidden = true
                    return
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let sbViews = self.navigationController?.navigationBar.subviews {
            for view in sbViews {
                if view is UIImageView {
                    view.isHidden = false
                    return
                }
            }
        }
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    //MARK: - Configured Graph
    
    func configureGraph() {
        // create graph
        graph.title = "Workout"
        graph.paddingLeft = 0
        graph.paddingTop = 0
        graph.paddingRight = 0
        graph.paddingBottom = 0
        
        let theme = CPTTheme(named: CPTThemeName.plainWhiteTheme)
        graph.apply(theme)
        
        plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace
        plotSpace?.allowsUserInteraction = true
        plotSpace?.delegate = self
        
        self.graphView.hostedGraph = graph
    }
  
    
    func configureGraphForType(type: TDPlotType) {
        plotFactory.resetPlots(graph: graph)
        
        // Create energy calorie plot
        guard let energyLinePlot = plotFactory.createCorePlotForType(type: type) else {return}
        energyLinePlot.dataSource = self
        energyLinePlot.delegate = self
        graph.add(energyLinePlot)
        configureTouchPlot()

        guard let x = plotFactory.configureTimeXAxisForGraph(graph: graph),
            let y = plotFactory.createAxisForType(graph: graph, type:type) else { return }
        
        // Set axes
        graph.axisSet?.axes = [x, y]
        
        HUD = JGProgressHUD(style: JGProgressHUDStyle.light)
        HUD?.show(in: self.view)
        HUD?.dismiss(afterDelay: 15.0)
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            var query : HKQuery?
            switch type {
            case .Heartrate:
                if heartRateSamples.count > 0 {
                    savePeakHRValues()
                    refreshGraph(identifier: TDPlotType.Heartrate.rawValue)
                } else {
                    query = createStreamingHeartRateQuery()
                }
            case .Calories:
                if energySamples.count > 0 {
                    refreshGraph(identifier: TDPlotType.Calories.rawValue)
                } else {
                    query = createStreamingEnergyQuery()
                }
            case .Steps:
                if stepSamples.count > 0 {
                    refreshGraph(identifier: TDPlotType.Steps.rawValue)
                } else {
                    query = createStreamingStepQuery()
                }
            case .Distance:
                if distanceSamples.count > 0 {
                    refreshGraph(identifier: TDPlotType.Distance.rawValue)
                } else {
                    query = createStreamingDistanceQuery()
                }
            default:
                query = createStreamingHeartRateQuery()
            }
            
            if let query = query {
                appDelegate.healthStore.execute(query)
            }
        }
    }
    
    
    func configureTouchPlot() {
        guard let touchPlot = plotFactory.createCorePlotForType(type: .TouchInteraction) else {return}
        touchPlot.dataSource = self
        touchPlot.delegate = self
        self.graph.add(touchPlot)
    }
    
    func configurePeakHRLines() {
        guard let maxLine = plotFactory.createCorePlotForType(type: .Maxima),
            let minLine = plotFactory.createCorePlotForType(type: .Minima) else {return}

        maxLine.dataSource = self
        maxLine.delegate = self
        minLine.dataSource = self
        minLine.delegate = self
        
        graph.add(maxLine)
        graph.add(minLine)
    }
    
    
    func addPeakHRAnnotations() {
        let annotationTextStyleTop = CPTMutableTextStyle()
        annotationTextStyleTop.color = CPTColor.red()
        annotationTextStyleTop.fontSize = 16.0
        annotationTextStyleTop.fontName = "Helvetica-Bold"
        
        let annotationTextStyleBottom = CPTMutableTextStyle()
        annotationTextStyleBottom.color = CPTColor.orange()
        annotationTextStyleBottom.fontSize = 16.0
        annotationTextStyleBottom.fontName = "Helvetica-Bold"
        
        guard let plotSpace = plotSpace else {return}
        let maxPoint = CPTPlotSpaceAnnotation(plotSpace: plotSpace, anchorPlotPoint: [0.0, NSNumber(value: maxHRValue)])
        maxPoint.contentLayer = CPTTextLayer(text:String(format: "Max %.0f bpm", maxHRValue), style:annotationTextStyleTop)
        maxPoint.displacement = CGPoint(x: 4.0, y: 0.0)
        maxPoint.contentAnchorPoint = CGPoint.zero
        
        let minPoint = CPTPlotSpaceAnnotation(plotSpace: plotSpace, anchorPlotPoint: [0.0, NSNumber(value: minHRValue)])
        minPoint.contentLayer = CPTTextLayer(text:String(format: "Min %.0f bpm", minHRValue), style:annotationTextStyleBottom)
        minPoint.displacement = CGPoint(x: 4.0, y: 0.0)
        minPoint.contentAnchorPoint = CGPoint(x: 0, y: 1)
        
        graph.addAnnotation(maxPoint)
        graph.addAnnotation(minPoint)
    }
    
    //MARK: - CPTPlotDataSource events
    
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        var count : UInt = 0
        
        switch (plot.identifier) {
        case (let id as String) where id == TDPlotType.Heartrate.rawValue:
            count = UInt(heartRateSamples.count)
            debugPrint("heartRateSamples sample count = \(count)")
        case (let id as String) where id == TDPlotType.Calories.rawValue:
            count = UInt(energySamples.count)
            debugPrint("energySamples sample count = \(count)")
        case (let id as String) where id == TDPlotType.Steps.rawValue:
            count = UInt(stepSamples.count)
            debugPrint("stepSamples sample count = \(count)")
        case (let id as String) where id == TDPlotType.Distance.rawValue:
            count = UInt(distanceSamples.count)
            debugPrint("distanceSamples sample count = \(count)")
        case (let id as String) where id == TDPlotType.Maxima.rawValue || id == TDPlotType.Minima.rawValue:
            count = 2
        case (let id as String) where id == TDPlotType.TouchInteraction.rawValue && touchedPoint != nil:
            count = 3
        default:
            return count
        }
        
        return count
    }
    
    
    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        let x = UInt(CPTScatterPlotField.X.rawValue)
        let y = UInt(CPTScatterPlotField.Y.rawValue)
        
        var quant : HKQuantitySample
        
        switch (plot.identifier, fieldEnum) {
        case (let id as String, x) where id == TDPlotType.Heartrate.rawValue:
            quant = heartRateSamples[Int(idx)]
            let seconds = quant.startDate.timeIntervalSince(plotFactory.startDate)
            return seconds
        case (let id as String, y) where id == TDPlotType.Heartrate.rawValue:
            quant = heartRateSamples[Int(idx)]
            let dValue = quant.quantity.doubleValue(for: countPerMinuteUnit)
            let seconds = quant.startDate.timeIntervalSince(plotFactory.startDate)
            debugPrint(String(format:"(%.0fs, %.0fbpm)", seconds, dValue))
            return dValue
        case (let id as String, x) where id == TDPlotType.Calories.rawValue:
            quant = energySamples[Int(idx)]
            let seconds = quant.startDate.timeIntervalSince(plotFactory.startDate)
            return seconds
        case (let id as String, y) where id == TDPlotType.Calories.rawValue:
            quant = energySamples[Int(idx)]
            let dValue = quant.quantity.doubleValue(for: energyUnit)
            let seconds = quant.startDate.timeIntervalSince(plotFactory.startDate)
            debugPrint(String(format:"(%.0fs, %.0fcal)", seconds, dValue))
            return dValue
        case (let id as String, x) where id == TDPlotType.Steps.rawValue:
            quant = stepSamples[Int(idx)]
            let seconds = quant.startDate.timeIntervalSince(plotFactory.startDate)
            return seconds
        case (let id as String, y) where id == TDPlotType.Steps.rawValue:
            quant = stepSamples[Int(idx)]
            let dValue = quant.quantity.doubleValue(for: stepUnit)
            let seconds = quant.startDate.timeIntervalSince(plotFactory.startDate)
            debugPrint(String(format:"(%.0fs, %.0fsteps)", seconds, dValue))
            return dValue
        case (let id as String, x) where id == TDPlotType.Distance.rawValue:
            quant = distanceSamples[Int(idx)]
            let seconds = quant.startDate.timeIntervalSince(plotFactory.startDate)
            return seconds
        case (let id as String, y) where id == TDPlotType.Distance.rawValue:
            quant = distanceSamples[Int(idx)]
            let dValue = quant.quantity.doubleValue(for: distanceUnit)
            let seconds = quant.startDate.timeIntervalSince(plotFactory.startDate)
            debugPrint(String(format:"(%.0fs, %.0fm)", seconds, dValue))
            return dValue
        case (let id as String, x) where id == TDPlotType.Maxima.rawValue || id == TDPlotType.Minima.rawValue:
            if idx == 0 {
                return 0
            } else {
                return plotFactory.endDate.timeIntervalSince(plotFactory.startDate)
            }
        case (let id as String, y) where id == TDPlotType.Maxima.rawValue:
            return maxHRValue
        case (let id as String, y) where id == TDPlotType.Minima.rawValue:
            return minHRValue
        case (let id as String, x) where id == TDPlotType.TouchInteraction.rawValue && touchedPoint != nil:
            return touchedPoint?.startDate.timeIntervalSince(plotFactory.startDate)
        case (let id as String, y) where id == TDPlotType.TouchInteraction.rawValue && touchedPoint != nil:
            let bpm = touchedPoint?.quantity.doubleValue(for: currentUnit)
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
    
    func plotSpace(_ space: CPTPlotSpace, shouldScaleBy interactionScale: CGFloat, aboutPoint interactionPoint: CGPoint) -> Bool {
        return true
    }
    
    func plotSpace(_ space: CPTPlotSpace, willChangePlotRangeTo newRange: CPTPlotRange, for coordinate: CPTCoordinate) -> CPTPlotRange? {
        if CPTCoordinate.Y == coordinate && currentUnit == countPerMinuteUnit {
            return _bpmPlotRange
        }
        
        return newRange
    }
    
    func scatterPlot(_ plot: CPTScatterPlot, plotSymbolWasSelectedAtRecord idx: UInt, with event: UIEvent) {
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
            refreshGraph(identifier: TDPlotType.TouchInteraction.rawValue)
            return
        default:
            return
        }
        
        // Setup a style for the annotation
        let hitAnnotationTextStyle = CPTMutableTextStyle()
        hitAnnotationTextStyle.color    = CPTColor.blue()
        hitAnnotationTextStyle.fontSize = 16.0
        hitAnnotationTextStyle.fontName = "Helvetica-Bold";
        
        if let x = touchedPoint?.startDate.timeIntervalSince(plotFactory.startDate),
            let y = touchedPoint?.quantity.doubleValue(for: currentUnit) {
                
                guard let axisSet = graph.axisSet as? CPTXYAxisSet,
                    let xAxis = axisSet.xAxis,
                    let formatter = xAxis.labelFormatter as? CPTTimeFormatter,
                    let time = formatter.string(from: NSNumber(value: x)) else { return }
                
                let coordString = String(format: "%.0f\n%@", y, time)
                debugPrint(coordString)
                
                guard let plotSpace = plotSpace else {return}
                
                let textLayer = CPTTextLayer(text:coordString, style:hitAnnotationTextStyle)
            let annotation = CPTPlotSpaceAnnotation(plotSpace:plotSpace, anchorPlotPoint:[NSNumber(value: x), NSNumber(value: y)])
                annotation.contentLayer   = textLayer
            annotation.displacement   = CGPoint(x: 2.0, y: 2.0)
                annotation.contentAnchorPoint = CGPoint.zero
                self.symbolTextAnnotation = annotation
                self.graph.addAnnotation(annotation)
                
            refreshGraph(identifier: TDPlotType.TouchInteraction.rawValue)
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
                self.refreshGraph(identifier: TDPlotType.Distance.rawValue)
            case (_, _?):
                print(error!.localizedDescription)
                fallthrough
            default:
                self.HUD?.textLabel.text = "No Distance Data"
                self.HUD?.dismiss(afterDelay: 5.0)
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
                self.refreshGraph(identifier: TDPlotType.Steps.rawValue)
            case (_, _?):
                print(error!.localizedDescription)
                fallthrough
            default:
                self.HUD?.textLabel.text = "No Step Data"
                self.HUD?.dismiss(afterDelay: 5.0)
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
                self.refreshGraph(identifier: TDPlotType.Calories.rawValue)
            case (_, _?):
                print(error!.localizedDescription)
                fallthrough
            default:
                self.HUD?.textLabel.text = "No Energy Data"
                self.HUD?.dismiss(afterDelay: 5.0)
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
                self.refreshGraph(identifier: TDPlotType.Heartrate.rawValue)
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
        return HKQuery.predicateForSamples(withStart: plotFactory.startDate, end: plotFactory.endDate, options: HKQueryOptions(rawValue: 0))
    }
    

    func refreshGraph(identifier: String?) {
        DispatchQueue.main.async() {
            self.HUD?.dismiss(animated: true)
            if let id = identifier {
                self.graphView.hostedGraph?.plot(withIdentifier: id as NSCopying)?.reloadData()
            } else {
                self.graphView.hostedGraph?.reloadData()
            }
        }
    }
    
    func savePeakHRValues() {
        for sample in self.heartRateSamples {
            let hrVal = sample.quantity.doubleValue(for: countPerMinuteUnit)
            if hrVal < minHRValue {
                minHRValue = hrVal
            }
            if hrVal > maxHRValue {
                maxHRValue = hrVal
            }
        }
        
        if minHRValue < Double.infinity && maxHRValue > 0 && self.heartRateSamples.count > 2 {
            DispatchQueue.main.async() {
                self.configurePeakHRLines()
                self.addPeakHRAnnotations()
                guard let axisSet = self.graph.axisSet as? CPTXYAxisSet, let y = axisSet.yAxis else { return }
                guard let plotSpace = self.plotSpace else {return}
                let range = CPTPlotRange(location: NSNumber(value: self.minHRValue), length: NSNumber(value: self.maxHRValue-self.minHRValue))
                y.visibleRange = range
                self._bpmPlotRange = range.mutableCopy() as! CPTMutablePlotRange
                self._bpmPlotRange.expand(byFactor: 1.5)
                plotSpace.globalYRange = self._bpmPlotRange
                plotSpace.yRange = range

                self.graphView.hostedGraph?.plot(withIdentifier: TDPlotType.Maxima.rawValue as NSCopying)?.reloadData()
                self.graphView.hostedGraph?.plot(withIdentifier: TDPlotType.Minima.rawValue as NSCopying)?.reloadData()
            }
        }
    }
    
    
    @IBAction func segmentCtrlChanged(sender: UISegmentedControl) {
        touchedPoint = nil
        symbolTextAnnotation = nil
      
        switch sender.selectedSegmentIndex {
        case 0:
            currentUnit = countPerMinuteUnit
            configureGraphForType(type: .Heartrate)
        case 1:
            currentUnit = energyUnit
            configureGraphForType(type: .Calories)
        case 2:
            currentUnit = stepUnit
            configureGraphForType(type: .Steps)
        case 3:
            currentUnit = distanceUnit
            configureGraphForType(type: .Distance)
        default:
            break
        }
    }
    
    func displayNoData() {
        DispatchQueue.main.async() {
            guard let hud = self.HUD else {return}
            if !hud.isVisible {
                self.HUD = JGProgressHUD(style: .light)
                self.HUD?.show(in: self.view)
            }
            self.HUD?.setProgress(1.0, animated: true)
            self.HUD?.dismiss(afterDelay: 15.0)
            self.HUD?.textLabel.text = "No Heartrate Data"
        }
    }
}

