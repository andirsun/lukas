import {
  Bar,
  CartesianGrid,
  ComposedChart,
  Line,
  Pie,
  PieChart,
  ResponsiveContainer,
  XAxis,
  YAxis,
} from "recharts";
import { TREND_MARGIN, X_AXIS_HEIGHT, Y_AXIS_WIDTH } from "./chart-geometry.ts";

/**
 * The Recharts drawings of the insights screen, in their own module so the chart library is
 * fetched only when insights open (`React.lazy` in CategoryDonut and TrendChart), never on home.
 * They draw only: the figures, the words and the tables for screen readers live in the
 * components around them, so every drawing here is decorative (`aria-hidden` by its caller) and
 * Recharts' keyboard layer is off. Colors are tokens: category tints come in as data, the rest
 * is set by class in app.css (`.lk-donut`, `.lk-trend-*`), which also follows the theme.
 */

export interface DonutSlice {
  id: string;
  value: number;
  /** The category's tint (`categoryLook`). */
  fill: string;
}

export interface Motion {
  /** Draw with the entrance animation (off under reduced motion). */
  animate: boolean;
  /** How long it takes, in ms (from the `--hop` token). */
  durationMs: number;
}

/** A donut of `size` px: its sectors sweep in clockwise from the top. */
export function DonutChart({
  slices,
  size,
  animate,
  durationMs,
}: { slices: DonutSlice[]; size: number } & Motion) {
  return (
    <PieChart width={size} height={size} accessibilityLayer={false} className="lk-donut">
      <Pie
        data={slices}
        dataKey="value"
        nameKey="id"
        cx="50%"
        cy="50%"
        innerRadius={Math.round(size * 0.33)}
        outerRadius={Math.round(size / 2) - 4}
        startAngle={90}
        endAngle={-270}
        paddingAngle={slices.length > 1 ? 2 : 0}
        cornerRadius={slices.length > 1 ? 5 : 0}
        stroke="none"
        rootTabIndex={-1}
        isAnimationActive={animate}
        animationBegin={0}
        animationDuration={durationMs}
        animationEasing="ease-out"
      />
    </PieChart>
  );
}

export interface TrendPoint {
  month: string;
  /** The axis label (`oct`). */
  label: string;
  income: number;
  expenses: number;
  /** `null` for a month without any budget: the line leaves a gap there. */
  budget: number | null;
}

/**
 * Income and expense bars per month that rise from the axis, the budget as a dashed straight line
 * with a dot per month that has one (months without a budget leave a gap), and a y-axis in
 * compact amounts (`formatTick`). Selecting a month is TrendChart's (its tap targets lie over this).
 */
export function TrendBars({
  points,
  height,
  animate,
  durationMs,
  formatTick,
}: {
  points: TrendPoint[];
  height: number;
  formatTick(value: number): string;
} & Motion) {
  const withBudget = points.some((p) => p.budget !== null);
  return (
    <ResponsiveContainer width="100%" height={height} initialDimension={{ width: 320, height }}>
      <ComposedChart
        data={points}
        accessibilityLayer={false}
        margin={TREND_MARGIN}
        barGap={3}
        barCategoryGap="22%"
        className="lk-trend"
      >
        <CartesianGrid vertical={false} />
        <XAxis
          dataKey="label"
          axisLine={false}
          tickLine={false}
          interval="preserveStartEnd"
          minTickGap={4}
          height={X_AXIS_HEIGHT}
        />
        <YAxis
          width={Y_AXIS_WIDTH}
          axisLine={false}
          tickLine={false}
          tickCount={4}
          allowDecimals={false}
          domain={[0, "auto"]}
          tickFormatter={formatTick}
          tick={{ className: "lk-trend-y-tick" }}
        />
        <Bar
          dataKey="income"
          className="lk-trend-income"
          radius={[6, 6, 0, 0]}
          maxBarSize={18}
          isAnimationActive={animate}
          animationBegin={0}
          animationDuration={durationMs}
          animationEasing="ease-out"
        />
        <Bar
          dataKey="expenses"
          className="lk-trend-expenses"
          radius={[6, 6, 0, 0]}
          maxBarSize={18}
          isAnimationActive={animate}
          animationBegin={animate ? 80 : 0}
          animationDuration={durationMs}
          animationEasing="ease-out"
        />
        {withBudget && (
          <Line
            dataKey="budget"
            type="linear"
            connectNulls={false}
            className="lk-trend-budget"
            dot={{ r: 3, className: "lk-trend-budget-dot" }}
            activeDot={false}
            strokeWidth={2}
            strokeDasharray="5 4"
            isAnimationActive={animate}
            animationBegin={animate ? durationMs / 2 : 0}
            animationDuration={durationMs}
            animationEasing="ease-out"
          />
        )}
      </ComposedChart>
    </ResponsiveContainer>
  );
}
