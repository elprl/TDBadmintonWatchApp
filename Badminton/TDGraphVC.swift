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
    
    private let _heartrateId = "Heartrate"
    private let _distanceId = "Distance"
    private let _stepsId = "Steps"
    private let _energyId = "Active Energy"
    
    var plotSpace : CPTXYPlotSpace?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = MHPrettyDate.prettyDateFromDate(startDate, withFormat: MHPrettyDateFormatNoTime)
        
        toolBar.delegate = self
        
        setupHeartRateGraph()
        
        HUD = JGProgressHUD(style: JGProgressHUDStyle.Light)
        HUD?.showInView(self.view)
        HUD?.dismissAfterDelay(15.0)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
//            var queries = [HKQuery]()
//            queries.append(createStreamingDistanceQuery())
//            queries.append(createStreamingEnergyQuery())
//            queries.append(createStreamingStepQuery())
            let query = createStreamingHeartRateQuery()
            appDelegate.healthStore.executeQuery(query)
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
        plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace
        guard let plotSpace = plotSpace else {return}
        plotSpace.allowsUserInteraction = true
        plotSpace.delegate = self
//        let startLocation = startDate.timeIntervalSince1970
        let length = endDate.timeIntervalSinceDate(startDate)
//        print("Workout length is \(length) seconds")
        plotSpace.xRange = CPTPlotRange(location: 0, length: length)
        plotSpace.yRange = CPTPlotRange(location: 0, length: 250)
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
        //
        //        // Axes
        //        // Label x axis with a fixed interval policy
//        let axisSet = graph.axisSet as! CPTXYAxisSet
//        guard let x = axisSet.xAxis else { return }
//        x.majorIntervalLength   = _minute
//        x.minorTicksPerInterval = 6
//        //        x.majorGridLineStyle    = majorGridLineStyle
//        //        x.minorGridLineStyle    = minorGridLineStyle
//        //        x.axisConstraints       = CPTConstraints.constraintWithRelativeOffset(0.5)
//        //
//        let lineCap = CPTLineCap.sweptArrowPlotLineCap()
//        lineCap.size = CGSizeMake(0.625, 0.625)
//        lineCap.lineStyle = x.axisLineStyle
//        lineCap.fill      = CPTFill(color:CPTColor.redColor())
//        x.axisLineCapMax  = lineCap
//        
//        x.title       = "Time";
//        x.titleOffset = 4
        
        guard let x = configureXAxisForGraph(graph),
                y = configureBMPYAxisForGraph(graph) else {return }
        //
//        //        // Label y with an automatic label policy.
//        guard let y = axisSet.yAxis else { return }
//        y.labelingPolicy              = CPTAxisLabelingPolicy.Automatic
//        y.minorTicksPerInterval       = 2
//        y.preferredNumberOfMajorTicks = 10
//        //        y.majorGridLineStyle          = majorGridLineStyle
//        //        y.minorGridLineStyle          = minorGridLineStyle
//        //        y.axisConstraints             = CPTConstraints.constraintWithLowerOffset(0.0)
//        //        y.labelOffset                 = 0.25
//        //
//        //        lineCap.lineStyle = y.axisLineStyle
//        ////        lineCap.fill      = CPTFill(color:lineCap.lineStyle?.lineColor)
//        //        y.axisLineCapMax  = lineCap
//        //        y.axisLineCapMin  = lineCap
//        //
//        y.title       = "BPM"
//        y.titleOffset = 8
        
        // Set axes
        graph.axisSet?.axes = [x, y]
        
        let dataLineStyle = CPTMutableLineStyle(style: nil)
        
        // Create heartrate plot
        let heartrateLinePlot = CPTScatterPlot()
        heartrateLinePlot.identifier = _heartrateId
        // Make the data source line use curved interpolation
        heartrateLinePlot.interpolation = CPTScatterPlotInterpolation.Curved
        dataLineStyle.lineWidth = 3.0
        dataLineStyle.lineColor = CPTColor.redColor()
        heartrateLinePlot.dataLineStyle = dataLineStyle;
        heartrateLinePlot.dataSource = self
        heartrateLinePlot.delegate = self
        graph.addPlot(heartrateLinePlot)
        

        
        // Auto scale the plot space to fit the plot data
//        plotSpace.scaleToFitPlots(graph.allPlots())
//        let xRange = plotSpace.xRange.mutableCopy() as! CPTMutablePlotRange
//        let yRange = plotSpace.yRange.mutableCopy() as! CPTMutablePlotRange
//        
//        // Expand the ranges to put some space around the plot
//        xRange.expandRangeByFactor(1.2)
//        yRange.expandRangeByFactor(1.2)
//        plotSpace.xRange = xRange
//        plotSpace.yRange = yRange
//        
//        xRange.expandRangeByFactor(1.025)
//        xRange.location = plotSpace.xRange.location
//        yRange.expandRangeByFactor(1.05)
//        x.visibleAxisRange = plotSpace.xRange
//        y.visibleAxisRange = plotSpace.yRange
//        
//        xRange.expandRangeByFactor(1.2)
//        yRange.expandRangeByFactor(1.05)
//        plotSpace.globalXRange = xRange
//        plotSpace.globalYRange = yRange;
        
        // Add plot symbols
        let symbolLineStyle = CPTMutableLineStyle(style: nil)
        symbolLineStyle.lineColor = CPTColor.whiteColor()
        let plotSymbol = CPTPlotSymbol.diamondPlotSymbol()
        plotSymbol.fill = CPTFill(color:CPTColor.redColor())
        plotSymbol.lineStyle = symbolLineStyle
        plotSymbol.size = CGSizeMake(10, 10)
        heartrateLinePlot.plotSymbol = plotSymbol
        
        // Set plot delegate, to know when symbols have been touched
        // We will display an annotation when a symbol is touched
        heartrateLinePlot.delegate = self
        heartrateLinePlot.plotSymbolMarginForHitDetection = 5.0
        
        // Add legend
        let legend = CPTLegend(graph:graph)
        legend.numberOfRows = 1
        legend.textStyle = x.titleTextStyle
        legend.fill = CPTFill(color:CPTColor.purpleColor())
        legend.borderLineStyle = x.axisLineStyle
        legend.cornerRadius = 5.0
        
        graph.legend = legend
        graph.legendAnchor = CPTRectAnchor.Bottom
        graph.legendDisplacement = CGPointMake( 0.0, 2.0 )
        
        self.graphView.hostedGraph = graph
    }
    
    func configureXAxisForGraph(graph: CPTXYGraph) -> CPTXYAxis? {
        guard let axisSet = graph.axisSet as? CPTXYAxisSet, x = axisSet.xAxis else { return nil }

//        let startLocation = startDate.timeIntervalSince1970
        let length = endDate.timeIntervalSinceDate(startDate)
        let xAxisRange = CPTPlotRange(location: 0, length: length)
        x.visibleAxisRange = xAxisRange
        x.majorIntervalLength = _minute

        x.minorTicksPerInterval = 4
//        x.majorTickLineStyle = lineStyle;
//        x.minorTickLineStyle = lineStyle;
//        x.axisLineStyle = lineStyle;
        x.minorTickLength = CGFloat(5)
        x.majorTickLength = CGFloat(7)
//        x.orthogonalCoordinateDecimal = 0
        x.title = "Time";
//        x.titleOffset = 47
//        x.labelRotation=M_PI/4;
//        x.labelingPolicy = .None
//        let customTickLocations = [3*_hour, 6*_hour, 9*_hour, 12*_hour, 15*_hour, 18*_hour, 21*_hour, _day]
//        let xAxisLabels = ["03:00","06:00","9:00","12:00","15:00","18:00","21:00","00:00"]
//        var labelLocation = 0
//        var customLabels = Set<CPTAxisLabel>()
//        for tickLocation in customTickLocations {
//            let newLabel = CPTAxisLabel(text: xAxisLabels[labelLocation++], textStyle:x.labelTextStyle)
//            newLabel.tickLocation = tickLocation
//            newLabel.offset = x.labelOffset + x.majorTickLength;
////            newLabel.rotation = M_PI/4;
//            customLabels.insert(newLabel)
//        }
//        x.axisLabels =  customLabels
        
        //        let lineCap = CPTLineCap.sweptArrowPlotLineCap()
        //        lineCap.size = CGSizeMake(0.625, 0.625)
        //        lineCap.lineStyle = x.axisLineStyle
        //        lineCap.fill      = CPTFill(color:CPTColor.redColor())
        //        x.axisLineCapMax  = lineCap
        
        return x
    }
    
    func configureBMPYAxisForGraph(graph: CPTXYGraph) -> CPTXYAxis? {
        guard let axisSet = graph.axisSet as? CPTXYAxisSet, y = axisSet.yAxis else { return nil }

        y.labelingPolicy = CPTAxisLabelingPolicy.Automatic
        y.minorTicksPerInterval = 2
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
        y.titleOffset = 8
        
        return y
    }
    
    func changeGraphToSteps() {
        guard let graph = self.graphView.hostedGraph else { return }
        guard let plots = self.graphView.hostedGraph?.allPlots() else {return}
        for plot in plots {
            graph.removePlot(plot)
        }
//        // Create distance plot
//        let distanceLinePlot = CPTScatterPlot()
//        distanceLinePlot.identifier = _distanceId
//        dataLineStyle.lineWidth = 2.0
//        dataLineStyle.lineColor = CPTColor.blueColor()
//        distanceLinePlot.dataLineStyle = dataLineStyle
//        distanceLinePlot.dataSource    = self
//        distanceLinePlot.delegate = self
//        graph.addPlot(distanceLinePlot)
        
        // Create steps plot
        let stepsLinePlot = CPTScatterPlot()
        stepsLinePlot.identifier = _stepsId
        let dataLineStyle = CPTMutableLineStyle(style: nil)
        dataLineStyle.lineColor  = CPTColor.yellowColor()
        stepsLinePlot.dataLineStyle = dataLineStyle
        stepsLinePlot.dataSource    = self
        stepsLinePlot.delegate = self
        graph.addPlot(stepsLinePlot)
        
//        // Create energy calorie plot
//        let energyLinePlot = CPTScatterPlot()
//        energyLinePlot.identifier = _energyId
//        dataLineStyle.lineColor  = CPTColor.orangeColor()
//        energyLinePlot.dataLineStyle = dataLineStyle
//        energyLinePlot.dataSource    = self
//        energyLinePlot.delegate = self
//        graph.addPlot(energyLinePlot)
        
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
        let lineCap = CPTLineCap.sweptArrowPlotLineCap()
        lineCap.size = CGSizeMake(0.625, 0.625)
        lineCap.lineStyle = x.axisLineStyle
        lineCap.fill      = CPTFill(color:CPTColor.redColor())
        x.axisLineCapMax  = lineCap
        
        x.title       = "Time";
        x.titleOffset = 4
        //
        //        // Label y with an automatic label policy.
        guard let y = axisSet.yAxis else { return }
        y.labelingPolicy              = CPTAxisLabelingPolicy.Automatic
        y.minorTicksPerInterval       = 2
        y.preferredNumberOfMajorTicks = 10
        //        y.majorGridLineStyle          = majorGridLineStyle
        //        y.minorGridLineStyle          = minorGridLineStyle
//                y.axisConstraints             = CPTConstraints.constraintWithLowerOffset(0.0)
//                y.labelOffset                 = 0.25
        //
        //        lineCap.lineStyle = y.axisLineStyle
        ////        lineCap.fill      = CPTFill(color:lineCap.lineStyle?.lineColor)
        //        y.axisLineCapMax  = lineCap
        //        y.axisLineCapMin  = lineCap
        //
        y.title       = "Steps"
        y.titleOffset = 8
        
        // Set axes
        graph.axisSet?.axes = [x, y]
        
        // Auto scale the plot space to fit the plot data
        guard let plotSpace = plotSpace else {return}
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
        yRange.expandRangeByFactor(1.05)
        plotSpace.globalXRange = xRange
        plotSpace.globalYRange = yRange;

        
        HUD = JGProgressHUD(style: JGProgressHUDStyle.Light)
        HUD?.showInView(self.view)
        HUD?.dismissAfterDelay(15.0)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            let query = createStreamingStepQuery()
            appDelegate.healthStore.executeQuery(query)
        }
    }
    
    func changeGraphToEnergy() {
        guard let plots = self.graphView.hostedGraph?.allPlots() else {return}
        for plot in plots {
            self.graphView.hostedGraph?.removePlot(plot)
        }
        
        // Create energy calorie plot
        let energyLinePlot = CPTScatterPlot()
        energyLinePlot.identifier = _energyId
        let dataLineStyle = CPTMutableLineStyle(style: nil)
        dataLineStyle.lineColor  = CPTColor.orangeColor()
        energyLinePlot.dataLineStyle = dataLineStyle
        energyLinePlot.dataSource    = self
        energyLinePlot.delegate = self
        self.graphView.hostedGraph?.addPlot(energyLinePlot)
        
        //        // Axes
        //        // Label x axis with a fixed interval policy
        let axisSet = self.graphView.hostedGraph?.axisSet as! CPTXYAxisSet
        guard let x = axisSet.xAxis else { return }
        x.majorIntervalLength   = _minute
        x.minorTicksPerInterval = 6
        //        x.majorGridLineStyle    = majorGridLineStyle
        //        x.minorGridLineStyle    = minorGridLineStyle
        //        x.axisConstraints       = CPTConstraints.constraintWithRelativeOffset(0.5)
        //
        let lineCap = CPTLineCap.sweptArrowPlotLineCap()
        lineCap.size = CGSizeMake(0.625, 0.625)
        lineCap.lineStyle = x.axisLineStyle
        lineCap.fill      = CPTFill(color:CPTColor.redColor())
        x.axisLineCapMax  = lineCap
        
        x.title       = "Time";
        x.titleOffset = 4
        //
        //        // Label y with an automatic label policy.
        guard let y = axisSet.yAxis else { return }
        y.labelingPolicy              = CPTAxisLabelingPolicy.Automatic
        y.minorTicksPerInterval       = 2
        y.preferredNumberOfMajorTicks = 10
        //        y.majorGridLineStyle          = majorGridLineStyle
        //        y.minorGridLineStyle          = minorGridLineStyle
        y.axisConstraints             = CPTConstraints.constraintWithLowerOffset(0.0)
        y.labelOffset                 = 0.25
        //
        //        lineCap.lineStyle = y.axisLineStyle
        ////        lineCap.fill      = CPTFill(color:lineCap.lineStyle?.lineColor)
        //        y.axisLineCapMax  = lineCap
        //        y.axisLineCapMin  = lineCap
        //
        y.title       = "Calories"
        y.titleOffset = 8
        
        // Set axes
        self.graphView.hostedGraph?.axisSet?.axes = [x, y]
        
        HUD = JGProgressHUD(style: JGProgressHUDStyle.Light)
        HUD?.showInView(self.view)
        HUD?.dismissAfterDelay(15.0)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            let query = createStreamingEnergyQuery()
            appDelegate.healthStore.executeQuery(query)
        }
    }
    
    func numberOfRecordsForPlot(plot: CPTPlot) -> UInt {
        var count : UInt = 0
        
        switch (plot.identifier) {
        case (let id as String) where id == _heartrateId:
            count = UInt(heartRateSamples.count)
            print("heartRateSamples sample count = \(count)")
        case (let id as String) where id == _energyId:
            count = UInt(energySamples.count)
            print("energySamples sample count = \(count)")
        case (let id as String) where id == _stepsId:
            count = UInt(stepSamples.count)
            print("stepSamples sample count = \(count)")
        case (let id as String) where id == _distanceId:
            count = UInt(distanceSamples.count)
            print("distanceSamples sample count = \(count)")
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
        case (let id as String, x) where id == _heartrateId:
            quant = heartRateSamples[Int(idx)]
            let seconds = quant.startDate.timeIntervalSinceDate(startDate)
            return seconds
        case (let id as String, y) where id == _heartrateId:
            quant = heartRateSamples[Int(idx)]
            let dValue = quant.quantity.doubleValueForUnit(countPerMinuteUnit)
            let seconds = quant.startDate.timeIntervalSinceDate(startDate)
            print(String(format:"(%.0fs, %.0fbpm)", seconds, dValue))
            return dValue
        case (let id as String, x) where id == _energyId:
            quant = energySamples[Int(idx)]
            let seconds = quant.startDate.timeIntervalSinceDate(startDate)
            return seconds
        case (let id as String, y) where id == _energyId:
            quant = energySamples[Int(idx)]
            let dValue = quant.quantity.doubleValueForUnit(energyUnit)
            let seconds = quant.startDate.timeIntervalSinceDate(startDate)
            print(String(format:"(%.0fs, %.0fcal)", seconds, dValue))
            return dValue
        case (let id as String, x) where id == _stepsId:
            quant = stepSamples[Int(idx)]
            let seconds = quant.startDate.timeIntervalSinceDate(startDate)
            return seconds
        case (let id as String, y) where id == _stepsId:
            quant = stepSamples[Int(idx)]
            let dValue = quant.quantity.doubleValueForUnit(stepUnit)
            let seconds = quant.startDate.timeIntervalSinceDate(startDate)
            print(String(format:"(%.0fs, %.0fsteps)", seconds, dValue))
            return dValue
        case (let id as String, x) where id == _distanceId:
            quant = distanceSamples[Int(idx)]
            let seconds = quant.startDate.timeIntervalSinceDate(startDate)
            return seconds
        case (let id as String, y) where id == _distanceId:
            quant = distanceSamples[Int(idx)]
            let dValue = quant.quantity.doubleValueForUnit(distanceUnit)
            let seconds = quant.startDate.timeIntervalSinceDate(startDate)
            print(String(format:"(%.0fs, %.0fm)", seconds, dValue))
            return dValue
        default:
            return nil
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
            if let id = identifier {
                self.graphView.hostedGraph?.plotWithIdentifier(id)?.reloadData()
            } else {
                self.graphView.hostedGraph?.reloadData()
            }
        }
    }
    
    
    @IBAction func segmentCtrlChanged(sender: UISegmentedControl) {
        changeGraphToEnergy()
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