/**
 * Where the trend's plot sits inside its chart, shared by the chart (charts.tsx, loaded lazily)
 * and the screen around it (TrendChart: the selected month's band and the tap targets), so the
 * screen can place them without loading the chart's code.
 */

/** The y-axis' width, in px: the plot starts after it. */
export const Y_AXIS_WIDTH = 44;
/** The plot's margins inside the chart, in px. */
export const TREND_MARGIN = { top: 8, right: 4, bottom: 0, left: 0 } as const;
/** The x-axis' height, in px, under the plot. */
export const X_AXIS_HEIGHT = 24;
