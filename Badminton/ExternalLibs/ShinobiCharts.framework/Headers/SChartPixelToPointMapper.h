//
//  SChartPixelToPointMapper.h
//  ShinobiCharts
//
//  Copyright 2014 Scott Logic Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ShinobiChart;
@class SChartPixelToPointMapping;

/**
 * A class capable of mapping a pixel point onto a datapoint, series and
 * suggested pixel point in a ShinobiChart. Intended for use by user
 * crosshairs.
 *
 * This class is responsible for asking each series how far it is from a given
 * point, and ensuring the point is in the correct coordinate space for the
 * series. The chart also has hit-detectors whose responsiblity it is to be
 * asked and to calculate the distance to their series, for a certain point.
 */
@interface SChartPixelToPointMapper : NSObject

/**
 * Map a pixel point with a (possibly nil) initial series.
 *
 * This method will return a `SChartPixelToPointMapping`, which describes the
 * cloeset series, datapoint and suggested pixel point for a given pixel point
 * on the chart.
 *
 * If `initialSeries` is nil, all series on the chart are searched through,
 * otherwise only the datapoints on the given series are searched.
 *
 * `chart` is the ShinobiChart on which to search.
 */
- (SChartPixelToPointMapping *)mappingForPoint:(CGPoint)pixelPoint
                                 onSeries:(SChartMappedSeries *)series
                                  onChart:(ShinobiChart *)chart;

@end
