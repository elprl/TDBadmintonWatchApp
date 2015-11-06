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

class TDGraphVC: UIViewController, CPTScatterPlotDataSource, CPTScatterPlotDelegate, CPTPlotSpaceDelegate {
    @IBOutlet var graphView: CPTGraphHostingView!

    var startDate = NSDate()
    var endDate = NSDate()
    
    let energyUnit = HKUnit.calorieUnit()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create graph
        let graph = CPTXYGraph(frame: CGRectZero)
        graph.title = "Workout"
        graph.paddingLeft = 0
        graph.paddingTop = 0
        graph.paddingRight = 0
        graph.paddingBottom = 0
        
        let theme = CPTTheme(named: kCPTDarkGradientTheme)
        graph.applyTheme(theme)
        
        // Plot area delegate
//        graph.plotAreaFrame?.plotArea?.delegate = self
//        
//        // Setup scatter plot space
        let plotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.allowsUserInteraction = true
        plotSpace.delegate = self
        let startSeconds = startDate.timeIntervalSince1970
        let length = endDate.timeIntervalSince1970 - startSeconds
        NSLog("\(startSeconds)")
        NSLog("\(length)")
        plotSpace.xRange = CPTPlotRange(location: 0, length: length)
        plotSpace.yRange = CPTPlotRange(location: 0, length: 200)
//
//        // Grid line styles
//        let majorGridLineStyle = CPTMutableLineStyle(style: nil)
//        majorGridLineStyle.lineWidth = 1
//        majorGridLineStyle.lineColor = CPTColor.grayColor()
//        
//        let minorGridLineStyle = CPTMutableLineStyle(style: nil)
//        minorGridLineStyle.lineWidth = 1
//        minorGridLineStyle.lineColor = CPTColor.lightGrayColor()
//        
//        let redLineStyle = CPTMutableLineStyle(style: nil)
//        redLineStyle.lineWidth = 10.0
//        redLineStyle.lineColor = CPTColor.redColor()
//        
//        let lineCap = CPTLineCap.sweptArrowPlotLineCap()
////        lineCap.size = CGSizeMake(0.625, 0.625)
//        
//        // Axes
//        // Label x axis with a fixed interval policy
        let axisSet = graph.axisSet as! CPTXYAxisSet
        guard let x = axisSet.xAxis else { return }
        x.majorIntervalLength   = _minute
        x.minorTicksPerInterval = 6
//        x.majorGridLineStyle    = majorGridLineStyle
//        x.minorGridLineStyle    = minorGridLineStyle
//        x.axisConstraints       = CPTConstraints.constraintWithRelativeOffset(0.5)
//        
//        lineCap.lineStyle = x.axisLineStyle
////        lineCap.fill      = CPTFill(color:lineCap.lineStyle?.lineColor)
//        x.axisLineCapMax  = lineCap
//        
        x.title       = "Time";
//        x.titleOffset = 1.25
//        
//        // Label y with an automatic label policy.
        guard let y = axisSet.yAxis else { return }
        y.labelingPolicy              = CPTAxisLabelingPolicy.Automatic
        y.minorTicksPerInterval       = 2
        y.preferredNumberOfMajorTicks = 10
//        y.majorGridLineStyle          = majorGridLineStyle
//        y.minorGridLineStyle          = minorGridLineStyle
//        y.axisConstraints             = CPTConstraints.constraintWithLowerOffset(0.0)
//        y.labelOffset                 = 0.25
//        
//        lineCap.lineStyle = y.axisLineStyle
////        lineCap.fill      = CPTFill(color:lineCap.lineStyle?.lineColor)
//        y.axisLineCapMax  = lineCap
//        y.axisLineCapMin  = lineCap
//        
        y.title       = "BPM"
        y.titleOffset = 1.25

        // Set axes
        graph.axisSet?.axes = [x, y]

        let dataLineStyle = CPTMutableLineStyle(style: nil)
        
        // Create heartrate plot
        let heartrateLinePlot = CPTScatterPlot()
        heartrateLinePlot.identifier = "heartRateType"
        // Make the data source line use curved interpolation
        heartrateLinePlot.interpolation = CPTScatterPlotInterpolation.Curved
        dataLineStyle.lineWidth = 3.0
        dataLineStyle.lineColor = CPTColor.redColor()
        heartrateLinePlot.dataLineStyle = dataLineStyle;
        heartrateLinePlot.dataSource = self
        heartrateLinePlot.delegate = self
        graph.addPlot(heartrateLinePlot)
        
//        // Create distance plot
//        let distanceLinePlot = CPTScatterPlot()
//        distanceLinePlot.identifier = distanceType
//        dataLineStyle.lineWidth = 2.0
//        dataLineStyle.lineColor = CPTColor.blueColor()
//        distanceLinePlot.dataLineStyle = dataLineStyle
//        distanceLinePlot.dataSource    = self
//        graph.addPlot(distanceLinePlot)
//        
//        // Create steps plot
//        let stepsLinePlot = CPTScatterPlot()
//        stepsLinePlot.identifier    = stepType
//        dataLineStyle.lineColor  = CPTColor.yellowColor()
//        stepsLinePlot.dataLineStyle = dataLineStyle
//        stepsLinePlot.dataSource    = self
//        graph.addPlot(stepsLinePlot)
//        
//        // Create energy calorie plot
//        let energyLinePlot = CPTScatterPlot()
//        energyLinePlot.identifier  = energyType
//        dataLineStyle.lineColor  = CPTColor.orangeColor()
//        energyLinePlot.dataLineStyle = dataLineStyle
//        energyLinePlot.dataSource    = self
//        graph.addPlot(energyLinePlot)

        
        // Auto scale the plot space to fit the plot data
        plotSpace.scaleToFitPlots(graph.allPlots())
        let xRange = plotSpace.xRange.mutableCopy() as! CPTMutablePlotRange
        let yRange = plotSpace.yRange.mutableCopy() as! CPTMutablePlotRange

        // Expand the ranges to put some space around the plot
        xRange.expandRangeByFactor(1.2)
        yRange.expandRangeByFactor(1.2)
        plotSpace.xRange = xRange
        plotSpace.yRange = yRange

        xRange.expandRangeByFactor(1.025)
        xRange.location = plotSpace.xRange.location
        yRange.expandRangeByFactor(1.05)
        x.visibleAxisRange = plotSpace.xRange
        y.visibleAxisRange = plotSpace.yRange

        xRange.expandRangeByFactor(1.2)
        yRange.expandRangeByFactor(1.2)
        plotSpace.globalXRange = xRange
        plotSpace.globalYRange = yRange;
        
        // Add plot symbols
        let symbolLineStyle = CPTMutableLineStyle(style: nil)
        symbolLineStyle.lineColor = CPTColor.blueColor()
        let plotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        plotSymbol.fill = CPTFill(color:CPTColor.blueColor())
        plotSymbol.lineStyle = symbolLineStyle
        plotSymbol.size = CGSizeMake(10, 10)
        heartrateLinePlot.plotSymbol = plotSymbol
//
//        // Set plot delegate, to know when symbols have been touched
//        // We will display an annotation when a symbol is touched
//        heartrateLinePlot.delegate = self
//        
//        heartrateLinePlot.plotSymbolMarginForHitDetection = 5.0
//        
//        // Add legend
//        let legend                 = CPTLegend(graph:graph)
//        legend.numberOfRows          = 1
//        legend.textStyle       = x.titleTextStyle
////        legend.fill            = CPTFill(color:CPTColor.purpleColor())
//        legend.borderLineStyle = x.axisLineStyle
//        legend.cornerRadius    = 5.0
//        
//        graph.legend = legend
//        graph.legendAnchor           = CPTRectAnchor.Bottom
//        graph.legendDisplacement     = CGPointMake( 0.0, 2.0 )
        
        self.graphView.hostedGraph = graph
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            let query = createStreamingHeartRateQuery()
            appDelegate.healthStore.executeQuery(query)
        }
    }
    
    
    func numberOfRecordsForPlot(plot: CPTPlot) -> UInt {
        if let plotId = plot.identifier as? String {
            if plotId == "heartRateType" {
                return UInt(heartRateSamples.count)
            } else if plotId == "energyType" {
                return UInt(energySamples.count)
            } else if plotId == "stepType" {
                return UInt(stepSamples.count)
            } else if plotId ==  "distanceType" {
                return UInt(distanceSamples.count)
            }
        }
        return 0
    }
    
    
    func numberForPlot(plot: CPTPlot, field fieldEnum: UInt, recordIndex idx: UInt) -> AnyObject? {
       if let plotId = plot.identifier as? String {
            if plotId == "heartRateType" {
                let quant = heartRateSamples[Int(idx)]
                if fieldEnum == UInt(CPTScatterPlotField.X.rawValue) {
                    let seconds = quant.startDate.timeIntervalSinceDate(startDate)
                    NSLog("x value : \(seconds)")
                    return seconds
                } else {
                    let dValue = quant.quantity.doubleValueForUnit(countPerMinuteUnit)
                    NSLog("y value : \(dValue)")
                    return dValue
                }
            } else if plotId == "energyType" {
                let quant = energySamples[Int(idx)]
                let dValue = quant.quantity.doubleValueForUnit(energyUnit)
                return dValue
            } else if plotId == "stepType" {
                let quant = stepSamples[Int(idx)]
                let dValue = quant.quantity.doubleValueForUnit(stepUnit)
                return dValue
            } else if plotId ==  "distanceType" {
                let quant = distanceSamples[Int(idx)]
                let dValue = quant.quantity.doubleValueForUnit(distanceUnit)
                return dValue
            }
        }
        return nil
    }
    
    //MARK: Data queries
    
    func createStreamingDistanceQuery() -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples()
        
        let distanceQuery = HKAnchoredObjectQuery(type: self.distanceType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) -> Void in

            if error == nil {
                if let quantitySamples = samples as? [HKQuantitySample] {
                    self.distanceSamples = quantitySamples
                    self.refreshGraph()
                }
            } else {
                NSLog(error!.localizedDescription)
            }
        }
        
        return distanceQuery
    }

    
    func createStreamingStepQuery() -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples()
        
        let distanceQuery = HKAnchoredObjectQuery(type: self.stepType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) -> Void in

            if error == nil {
                if let quantitySamples = samples as? [HKQuantitySample] {
                    self.stepSamples = quantitySamples
                    self.refreshGraph()
                }
            } else {
                NSLog(error!.localizedDescription)
            }
        }
        
        return distanceQuery
    }
    
    
    func createStreamingEnergyQuery() -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples()
        
        let energyQuery = HKAnchoredObjectQuery(type: self.energyType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) -> Void in
            if error == nil {
                if let quantitySamples = samples as? [HKQuantitySample] {
                    self.energySamples = quantitySamples
                    self.refreshGraph()
                }
            } else {
                NSLog(error!.localizedDescription)
            }
        }
        
        return energyQuery
    }
    
    
    func createStreamingHeartRateQuery() -> HKQuery {
        let predicate = self.predicateFromWorkoutSamples()
        
        let heartRateQuery = HKAnchoredObjectQuery(type: self.heartRateType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) -> Void in
            if error == nil {
                if let quantitySamples = samples as? [HKQuantitySample] {
                    self.heartRateSamples = quantitySamples
                    self.refreshGraph()
                }
            } else {
                NSLog(error!.localizedDescription)
            }
        }
        
        return heartRateQuery
    }
    
    func predicateFromWorkoutSamples() -> NSPredicate {
        return HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .None)
    }
    

    func refreshGraph() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.graphView.hostedGraph?.reloadData()
        }
    }
}