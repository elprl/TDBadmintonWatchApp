//
//  TDCorePlotFactory.swift
//  Badminton
//
//  Created by Paul Leo on 28/01/2016.
//  Copyright © 2016 TapDigital Ltd. All rights reserved.
//

import Foundation
import UIKit
import CorePlot

enum TDPlotType : String {
    case Heartrate = "Heartrate"
    case Calories = "Active Energy"
    case Steps = "Steps"
    case Distance = "Distance"
    case Maxima = "maxLine"
    case Minima = "minLine"
    case TouchInteraction = "touchLine"
}

protocol TDCorePlotFactoryProtocol {
    func createCorePlotForType(type: TDPlotType) -> CPTPlot?
    func createAxisForType(graph: CPTGraph, type: TDPlotType) -> CPTXYAxis?
}

class TDCorePlotFactory : TDCorePlotFactoryProtocol {
    let dataLineStyle = CPTMutableLineStyle()
    var startDate = NSDate()
    var endDate = NSDate()
    
    init(startDate: NSDate, endDate: NSDate) {
        self.startDate = startDate
        self.endDate = endDate
    }

    func createCorePlotForType(type: TDPlotType) -> CPTPlot? {
        if type == TDPlotType.Heartrate {
            let heartrateLinePlot = CPTScatterPlot()
            heartrateLinePlot.identifier = TDPlotType.Heartrate.rawValue
            heartrateLinePlot.interpolation = CPTScatterPlotInterpolation.Linear
            dataLineStyle.lineWidth = 3.0
            dataLineStyle.lineColor = CPTColor(CGColor: UIColor(red:1, green:0.45, blue:0.45, alpha:1).CGColor)
            heartrateLinePlot.dataLineStyle = dataLineStyle;
            let areaFill = CPTFill(color: dataLineStyle.lineColor?.colorWithAlphaComponent(0.3))
            heartrateLinePlot.areaFill = areaFill
            heartrateLinePlot.areaBaseValue = 4.0
            
            // Add plot symbols
            let plotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
            let lineStyle = CPTMutableLineStyle()
            lineStyle.lineColor = CPTColor.whiteColor()
            plotSymbol.lineStyle = lineStyle
            plotSymbol.fill = CPTFill(color: CPTColor.redColor())
            plotSymbol.size = CGSizeMake(3, 3)
            heartrateLinePlot.plotSymbol = plotSymbol
            heartrateLinePlot.plotSymbolMarginForHitDetection = 5.0
            
            return heartrateLinePlot
        }
        
        if type == TDPlotType.Steps {
            let stepsLinePlot = CPTScatterPlot()
            stepsLinePlot.identifier = TDPlotType.Steps.rawValue
            stepsLinePlot.interpolation = CPTScatterPlotInterpolation.Stepped
            dataLineStyle.lineWidth = 3.0
            dataLineStyle.lineColor  = CPTColor.brownColor()
            stepsLinePlot.dataLineStyle = dataLineStyle
            let areaFill = CPTFill(color: dataLineStyle.lineColor?.colorWithAlphaComponent(0.3))
            stepsLinePlot.areaFill = areaFill
            stepsLinePlot.areaBaseValue = 4.0
            return stepsLinePlot
        }
        
        if type == TDPlotType.Calories {
            let energyLinePlot = CPTScatterPlot()
            energyLinePlot.identifier = TDPlotType.Calories.rawValue
            energyLinePlot.interpolation = CPTScatterPlotInterpolation.Curved
            dataLineStyle.lineWidth = 3.0
            dataLineStyle.lineColor  = CPTColor.orangeColor()
            energyLinePlot.dataLineStyle = dataLineStyle
            
            let areaFill = CPTFill(color: dataLineStyle.lineColor?.colorWithAlphaComponent(0.3))
            energyLinePlot.areaFill = areaFill
            energyLinePlot.areaBaseValue = 4.0
            return energyLinePlot
        }
        
        if type == TDPlotType.Distance {
            let distanceLinePlot = CPTScatterPlot()
            distanceLinePlot.identifier = TDPlotType.Distance.rawValue
            distanceLinePlot.interpolation = CPTScatterPlotInterpolation.Stepped
            dataLineStyle.lineWidth = 3.0
            dataLineStyle.lineColor  = CPTColor.greenColor()
            distanceLinePlot.dataLineStyle = dataLineStyle
            
            let areaFill = CPTFill(color: dataLineStyle.lineColor?.colorWithAlphaComponent(0.3))
            distanceLinePlot.areaFill = areaFill
            distanceLinePlot.areaBaseValue = 4.0
            return distanceLinePlot
        }
        
        return nil
    }
    
    func createAxisForType(graph: CPTGraph, type: TDPlotType) -> CPTXYAxis? {
        if type == TDPlotType.Heartrate {
            guard let axisSet = graph.axisSet as? CPTXYAxisSet,
                yBpm = axisSet.yAxis,
                plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace else { return nil }
            
            yBpm.labelingPolicy = CPTAxisLabelingPolicy.Automatic
            let yVisAxisRange = CPTPlotRange(location: 0, length: 200)
            yBpm.visibleAxisRange = yVisAxisRange
            let exclRangeBottom = CPTPlotRange(location: 0.1, length: Int.min)
            let exclRangeTop = CPTPlotRange(location: 201, length: Int.max)
            yBpm.labelExclusionRanges = [exclRangeBottom, exclRangeTop]
            yBpm.preferredNumberOfMajorTicks = 5
            yBpm.minorTickLength = CGFloat(0)
            yBpm.majorTickLength = CGFloat(6)
            
            plotSpace.yRange = CPTMutablePlotRange(location: -20, length: 250)
            plotSpace.globalYRange = CPTPlotRange(location: -50, length: 300);
            
            // Grid line styles
            let majorGridLineStyle = CPTMutableLineStyle(style: nil)
            majorGridLineStyle.lineWidth = 1
            majorGridLineStyle.lineColor = CPTColor.lightGrayColor().colorWithAlphaComponent(0.5)
            //        majorGridLineStyle.dashPattern = [10,10]  //dashed line
            yBpm.majorGridLineStyle = majorGridLineStyle
            let length = endDate.timeIntervalSinceDate(startDate)
            yBpm.gridLinesRange = CPTPlotRange(location: 0.0, length: length)
            
            yBpm.axisConstraints = CPTConstraints.constraintWithLowerOffset(50.0)
            yBpm.title = "bpm"
            //        y.titleOffset = 8
            let numbFormatter = NSNumberFormatter()
            numbFormatter.generatesDecimalNumbers = false
            numbFormatter.numberStyle = .DecimalStyle
            yBpm.labelFormatter = numbFormatter
            
            return yBpm
        }
        
        if type == TDPlotType.Steps {
            guard let axisSet = graph.axisSet as? CPTXYAxisSet, ySteps = axisSet.yAxis else { return nil }

            ySteps.visibleRange = nil
            ySteps.visibleAxisRange = nil
            
            ySteps.labelingPolicy = CPTAxisLabelingPolicy.Automatic
            let exclRangeBottom = CPTPlotRange(location: 0, length: Int.min)
            ySteps.labelExclusionRanges = [exclRangeBottom]
            ySteps.preferredNumberOfMajorTicks = 5
            ySteps.minorTickLength = CGFloat(0)
            ySteps.majorTickLength = CGFloat(6)
            
            ySteps.axisConstraints = CPTConstraints.constraintWithLowerOffset(50.0)
            ySteps.title = "Steps"
            
            return ySteps
        }
        
        return nil

    }
    
    func configureTimeXAxisForGraph(graph: CPTXYGraph) -> CPTXYAxis? {
        guard let axisSet = graph.axisSet as? CPTXYAxisSet,
            x = axisSet.xAxis,
            plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace else { return nil }

        let length = endDate.timeIntervalSinceDate(startDate)
        LogMessage("BPM", 0, "Workout length is \(length) seconds")
        plotSpace.xRange = CPTPlotRange(location: 0, length: length)
        let xRange = plotSpace.xRange.mutableCopy() as! CPTMutablePlotRange
        
        // Expand the ranges to put some space around the plot
        xRange.expandRangeByFactor(1.2)
        plotSpace.xRange = xRange
        
        xRange.expandRangeByFactor(1.2)
        plotSpace.globalXRange = xRange
        
        x.labelingPolicy = CPTAxisLabelingPolicy.Automatic
        
        let xAxisRange = CPTPlotRange(location: 0.1, length: length)
        x.visibleAxisRange = xAxisRange
        let exclRangeLeft = CPTPlotRange(location: 0, length: Int.min)
        let exclRangeRight = CPTPlotRange(location: length+1, length: Int.max)
        x.labelExclusionRanges = [exclRangeLeft, exclRangeRight]
        
        //        x.orthogonalPosition = 2.0
        //        x.minorTicksPerInterval = 0
        let dateFormatter = NSDateFormatter()
        //        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateFormat = "H:mm:ss"
        let timeFormatter = CPTTimeFormatter(dateFormatter:dateFormatter)
        timeFormatter.referenceDate = startDate.startOfDay
        x.labelFormatter = timeFormatter

        x.minorTickLength = CGFloat(2)
        x.majorTickLength = CGFloat(6)
        //        x.orthogonalCoordinateDecimal = 0
        x.title = "Elapsed Time";
        //        x.titleOffset = 47
        
        x.axisConstraints = CPTConstraints.constraintWithLowerOffset(50.0)
        
        //        let lineCap = CPTLineCap.sweptArrowPlotLineCap()
        //        lineCap.size = CGSizeMake(0.625, 0.625)
        //        lineCap.lineStyle = x.axisLineStyle
        //        lineCap.fill      = CPTFill(color:CPTColor.redColor())
        //        x.axisLineCapMax  = lineCap
        
        return x
    }

    func resetPlots(graph: CPTGraph) {
        for plot in graph.allPlots() {
            graph.removePlot(plot)
        }
        graph.removeAllAnnotations()
    }
}