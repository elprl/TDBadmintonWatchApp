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
    var startDate = Date()
    var endDate = Date()
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }

    func createCorePlotForType(type: TDPlotType) -> CPTPlot? {
        if type == TDPlotType.Heartrate {
            let heartrateLinePlot = CPTScatterPlot()
            heartrateLinePlot.identifier = NSString.init(string: type.rawValue)
            heartrateLinePlot.interpolation = CPTScatterPlotInterpolation.linear
            let dataLineStyle = CPTMutableLineStyle()
            dataLineStyle.lineWidth = 3.0
            dataLineStyle.lineColor = CPTColor(componentRed:1, green:0.45, blue:0.45, alpha:1)
            heartrateLinePlot.dataLineStyle = dataLineStyle;
            let areaFill = CPTFill(color: CPTColor(componentRed: 1, green:0.96, blue:0.96, alpha:1))
            heartrateLinePlot.areaFill = areaFill
            heartrateLinePlot.areaBaseValue = 4.0
            
            // Add plot symbols
            let plotSymbol = CPTPlotSymbol.ellipse()
            let lineStyle = CPTMutableLineStyle()
            lineStyle.lineColor = CPTColor.white()
            plotSymbol.lineStyle = lineStyle
            plotSymbol.fill = CPTFill(color: dataLineStyle.lineColor!)
            plotSymbol.size = CGSize(width: 3, height: 3)
            heartrateLinePlot.plotSymbol = plotSymbol
            heartrateLinePlot.plotSymbolMarginForHitDetection = 5.0
            
            return heartrateLinePlot
        }
        
        if type == TDPlotType.Steps {
            let stepsLinePlot = CPTScatterPlot()
            stepsLinePlot.identifier = NSString.init(string: type.rawValue)
            stepsLinePlot.interpolation = CPTScatterPlotInterpolation.stepped
            let dataLineStyle = CPTMutableLineStyle()
            dataLineStyle.lineWidth = 3.0
            dataLineStyle.lineColor  = CPTColor.brown()
            stepsLinePlot.dataLineStyle = dataLineStyle
            let areaFill = CPTFill(color: CPTColor(componentRed:1, green:0.95, blue:0.33, alpha:1))
            stepsLinePlot.areaFill = areaFill
            stepsLinePlot.areaBaseValue = 4.0
            
            // Add plot symbols
            let plotSymbol = CPTPlotSymbol.ellipse()
            let lineStyle = CPTMutableLineStyle()
            lineStyle.lineColor = CPTColor.white()
            plotSymbol.lineStyle = lineStyle
            plotSymbol.fill = CPTFill(color: dataLineStyle.lineColor!)
            plotSymbol.size = CGSize(width: 3, height: 3)
            stepsLinePlot.plotSymbol = plotSymbol
            stepsLinePlot.plotSymbolMarginForHitDetection = 5.0
            
            return stepsLinePlot
        }
        
        if type == TDPlotType.Calories {
            let energyLinePlot = CPTScatterPlot()
            energyLinePlot.identifier = NSString.init(string: type.rawValue)
            energyLinePlot.interpolation = CPTScatterPlotInterpolation.curved
            let dataLineStyle = CPTMutableLineStyle()
            dataLineStyle.lineWidth = 3.0
            dataLineStyle.lineColor  = CPTColor.orange()
            energyLinePlot.dataLineStyle = dataLineStyle
            
            let areaFill = CPTFill(color: CPTColor(componentRed:1, green:0.66, blue:0.11, alpha:1))
            energyLinePlot.areaFill = areaFill
            energyLinePlot.areaBaseValue = 4.0
            
            // Add plot symbols
            let plotSymbol = CPTPlotSymbol.ellipse()
            let lineStyle = CPTMutableLineStyle()
            lineStyle.lineColor = CPTColor.white()
            plotSymbol.lineStyle = lineStyle
            plotSymbol.fill = CPTFill(color: dataLineStyle.lineColor!)
            plotSymbol.size = CGSize(width: 3, height: 3)
            energyLinePlot.plotSymbol = plotSymbol
            energyLinePlot.plotSymbolMarginForHitDetection = 5.0
            
            return energyLinePlot
        }
        
        if type == TDPlotType.Distance {
            let distanceLinePlot = CPTScatterPlot()
            distanceLinePlot.identifier = NSString.init(string: type.rawValue)
            distanceLinePlot.interpolation = CPTScatterPlotInterpolation.stepped
            let dataLineStyle = CPTMutableLineStyle()
            dataLineStyle.lineWidth = 3.0
            dataLineStyle.lineColor  = CPTColor.green()
            distanceLinePlot.dataLineStyle = dataLineStyle
            
            let areaFill = CPTFill(color: CPTColor(componentRed:0.61, green:0.99, blue:0.11, alpha:1))
            distanceLinePlot.areaFill = areaFill
            distanceLinePlot.areaBaseValue = 4.0
            
            // Add plot symbols
            let plotSymbol = CPTPlotSymbol.ellipse()
            let lineStyle = CPTMutableLineStyle()
            lineStyle.lineColor = CPTColor.white()
            plotSymbol.lineStyle = lineStyle
            plotSymbol.fill = CPTFill(color: dataLineStyle.lineColor!)
            plotSymbol.size = CGSize(width: 3, height: 3)
            distanceLinePlot.plotSymbol = plotSymbol
            distanceLinePlot.plotSymbolMarginForHitDetection = 5.0
            
            return distanceLinePlot
        }
        
        if type == TDPlotType.TouchInteraction {
            let touchPlot = CPTScatterPlot()
            touchPlot.interpolation = CPTScatterPlotInterpolation.histogram
            touchPlot.identifier = NSString.init(string: type.rawValue)
            
            let touchPlotColor = CPTColor.blue
            
            let savingsPlotLineStyle = CPTMutableLineStyle()
            savingsPlotLineStyle.lineColor = touchPlotColor()
            savingsPlotLineStyle.lineFill = CPTFill(color: CPTColor.white())
            savingsPlotLineStyle.lineWidth = 1.0
            
            let touchPlotSymbol = CPTPlotSymbol.ellipse()
            touchPlotSymbol.fill = CPTFill(color: touchPlotColor())
            touchPlotSymbol.lineStyle = savingsPlotLineStyle
            touchPlotSymbol.size = CGSize(width: 10.0, height: 10.0)
            touchPlot.plotSymbol = touchPlotSymbol
            
            let dataLineStyle = CPTMutableLineStyle()
            dataLineStyle.lineColor = touchPlotColor()
            dataLineStyle.lineWidth = 2.0
            touchPlot.dataLineStyle = dataLineStyle
            
            return touchPlot
        }
        
        if type == TDPlotType.Maxima {
            let maxLine = CPTScatterPlot()
            maxLine.identifier = NSString.init(string: type.rawValue)
            
            let dataLineStyle = CPTMutableLineStyle()
            dataLineStyle.dashPattern = [3,3]  //dashed line
            dataLineStyle.lineWidth = 1
            dataLineStyle.lineColor = CPTColor.red()
            maxLine.dataLineStyle = dataLineStyle
            
            return maxLine
        }
        
        if type == TDPlotType.Minima {
            let minLine = CPTScatterPlot()
            minLine.identifier = NSString.init(string: type.rawValue)
            
            let dataLineStyle = CPTMutableLineStyle()
            dataLineStyle.dashPattern = [3,3]  //dashed line
            dataLineStyle.lineWidth = 1
            dataLineStyle.lineColor = CPTColor.orange()
            minLine.dataLineStyle = dataLineStyle
            
            return minLine
        }
        
        return nil
    }
    
    func createAxisForType(graph: CPTGraph, type: TDPlotType) -> CPTXYAxis? {
        if type == TDPlotType.Heartrate {
            guard let axisSet = graph.axisSet as? CPTXYAxisSet,
                let yBpm = axisSet.yAxis,
                let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace else { return nil }
            
            yBpm.labelingPolicy = CPTAxisLabelingPolicy.automatic
            let yVisAxisRange = CPTPlotRange(location: 0, length: 200)
            yBpm.visibleAxisRange = yVisAxisRange
            let exclRangeBottom = CPTPlotRange(location: 0.1, length: NSNumber(value: Int.min))
            let exclRangeTop = CPTPlotRange(location: 201, length: NSNumber(value: Int.max))
            yBpm.labelExclusionRanges = [exclRangeBottom, exclRangeTop]
            yBpm.preferredNumberOfMajorTicks = 5
            yBpm.minorTickLength = CGFloat(0)
            yBpm.majorTickLength = CGFloat(6)
            
            plotSpace.yRange = CPTMutablePlotRange(location: -20, length: 250)
            plotSpace.globalYRange = CPTPlotRange(location: -50, length: 300);
            
            // Grid line styles
            let majorGridLineStyle = CPTMutableLineStyle(style: nil)
            majorGridLineStyle.lineWidth = 1
            majorGridLineStyle.lineColor = CPTColor(componentRed:0.82, green:0.82, blue:0.82, alpha:1)
            //        majorGridLineStyle.dashPattern = [10,10]  //dashed line
            yBpm.majorGridLineStyle = majorGridLineStyle
            let length = endDate.timeIntervalSince(startDate)
            yBpm.gridLinesRange = CPTPlotRange(location: 0.0, length: NSNumber(value: length))
            
            yBpm.axisConstraints = CPTConstraints.constraint(withLowerOffset: 50.0)
            yBpm.title = "bpm"
            //        y.titleOffset = 8
            let numbFormatter = NumberFormatter()
            numbFormatter.generatesDecimalNumbers = false
            numbFormatter.numberStyle = .decimal
            yBpm.labelFormatter = numbFormatter
            
            return yBpm
        }
        
        if type == TDPlotType.Steps {
            guard let axisSet = graph.axisSet as? CPTXYAxisSet,
                let ySteps = axisSet.yAxis,
                let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace else { return nil }

            ySteps.visibleRange = nil
            ySteps.visibleAxisRange = nil
            
            plotSpace.yRange = CPTMutablePlotRange(location: 0, length: 250)
            plotSpace.globalYRange = CPTPlotRange(location: -50, length: 300);
            
            ySteps.labelingPolicy = CPTAxisLabelingPolicy.automatic
            let exclRangeBottom = CPTPlotRange(location: 0, length: NSNumber(value: Int.min))
            ySteps.labelExclusionRanges = [exclRangeBottom]
            ySteps.preferredNumberOfMajorTicks = 5
            ySteps.minorTickLength = CGFloat(0)
            ySteps.majorTickLength = CGFloat(6)
            
            ySteps.axisConstraints = CPTConstraints.constraint(withLowerOffset: 50.0)
            ySteps.title = "Steps"
            
            return ySteps
        }
        
        if type == TDPlotType.Calories {
            guard let axisSet = graph.axisSet as? CPTXYAxisSet,
                let yCalories = axisSet.yAxis,
                let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace else { return nil }
            
            let range = CPTMutablePlotRange(location: 0, length: 1000)
            yCalories.visibleRange = range
            yCalories.visibleAxisRange = range
            
            plotSpace.yRange = range
            plotSpace.globalYRange = CPTPlotRange(location: -50, length: 1200);
            
            yCalories.labelingPolicy = CPTAxisLabelingPolicy.automatic
            let exclRangeBottom = CPTPlotRange(location: 0, length: NSNumber(value: Int.min))
            yCalories.labelExclusionRanges = [exclRangeBottom]
            yCalories.preferredNumberOfMajorTicks = 5
            yCalories.minorTickLength = CGFloat(0)
            yCalories.majorTickLength = CGFloat(6)
            
            yCalories.axisConstraints = CPTConstraints.constraint(withLowerOffset: 50.0)
            yCalories.title = "Calories"
            
            return yCalories
        }
        
        if type == TDPlotType.Distance {
            guard let axisSet = graph.axisSet as? CPTXYAxisSet,
                let yDistance = axisSet.yAxis,
                let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace else { return nil }
            
            yDistance.visibleRange = nil
            yDistance.visibleAxisRange = nil
            
            plotSpace.yRange = CPTMutablePlotRange(location: 0, length: 250)
            plotSpace.globalYRange = CPTPlotRange(location: -50, length: 300);
            
            yDistance.labelingPolicy = CPTAxisLabelingPolicy.automatic
            let exclRangeBottom = CPTPlotRange(location: 0, length: NSNumber(value: Int.min))
            yDistance.labelExclusionRanges = [exclRangeBottom]
            yDistance.preferredNumberOfMajorTicks = 5
            yDistance.minorTickLength = CGFloat(0)
            yDistance.majorTickLength = CGFloat(6)
            
            yDistance.axisConstraints = CPTConstraints.constraint(withLowerOffset: 50.0)
            yDistance.title = "Distance (m)"
            
            return yDistance
        }
        
        return nil

    }
    
    func configureTimeXAxisForGraph(graph: CPTXYGraph) -> CPTXYAxis? {
        guard let axisSet = graph.axisSet as? CPTXYAxisSet,
            let x = axisSet.xAxis,
            let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace else { return nil }

        let length = endDate.timeIntervalSince(startDate)
        debugPrint("Workout length is \(length) seconds")
        plotSpace.xRange = CPTPlotRange(location: 0, length: NSNumber(value: length))
        let xRange = plotSpace.xRange.mutableCopy() as! CPTMutablePlotRange
        
        // Expand the ranges to put some space around the plot
        xRange.expand(byFactor: 1.2)
        plotSpace.xRange = xRange
        
        xRange.expand(byFactor: 1.2)
        plotSpace.globalXRange = xRange
        
        x.labelingPolicy = CPTAxisLabelingPolicy.automatic
        
        let xAxisRange = CPTPlotRange(location: 0.1, length: NSNumber(value: length))
        x.visibleAxisRange = xAxisRange
        let exclRangeLeft = CPTPlotRange(location: 0, length: NSNumber(value: Int.min))
        let exclRangeRight = CPTPlotRange(location: NSNumber(value: length+1), length: NSNumber(value: Int.max))
        x.labelExclusionRanges = [exclRangeLeft, exclRangeRight]
        
        //        x.orthogonalPosition = 2.0
        //        x.minorTicksPerInterval = 0
        let dateFormatter = DateFormatter()
        //        dateFormatter.dateStyle = DateFormatterStyle.ShortStyle
        dateFormatter.dateFormat = "H:mm:ss"
        let timeFormatter = CPTTimeFormatter(dateFormatter:dateFormatter)
        timeFormatter.referenceDate = Calendar.current.startOfDay(for: startDate) // startDate.startOfDay
        x.labelFormatter = timeFormatter

        x.minorTickLength = CGFloat(2)
        x.majorTickLength = CGFloat(6)
        //        x.orthogonalCoordinateDecimal = 0
        x.title = "Elapsed Time";
        //        x.titleOffset = 47
        
        x.axisConstraints = CPTConstraints.constraint(withLowerOffset: 50.0)
        
        //        let lineCap = CPTLineCap.sweptArrowPlotLineCap()
        //        lineCap.size = CGSizeMake(0.625, 0.625)
        //        lineCap.lineStyle = x.axisLineStyle
        //        lineCap.fill      = CPTFill(color:CPTColor.redColor())
        //        x.axisLineCapMax  = lineCap
        
        return x
    }

    func resetPlots(graph: CPTGraph) {
        for plot in graph.allPlots() {
            graph.remove(plot)
        }
        graph.removeAllAnnotations()
    }
}
