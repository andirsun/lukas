import type { ReactNode } from "react";
import {
  Bar,
  CartesianGrid,
  ComposedChart,
  Line,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

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
  budget: number;
}

/**
 * Income and expense bars per month that rise from the axis, and the budget as a dashed line
 * drawn after them. Tapping or hovering a month shows its figures (`tooltip`).
 */
export function TrendBars({
  points,
  height,
  animate,
  durationMs,
  tooltip,
}: {
  points: TrendPoint[];
  height: number;
  tooltip(point: TrendPoint): ReactNode;
} & Motion) {
  const withBudget = points.some((p) => p.budget > 0);
  return (
    <ResponsiveContainer width="100%" height={height} initialDimension={{ width: 320, height }}>
      <ComposedChart
        data={points}
        accessibilityLayer={false}
        margin={{ top: 8, right: 4, bottom: 0, left: 4 }}
        barGap={3}
        barCategoryGap="22%"
        className="lk-trend"
      >
        <CartesianGrid vertical={false} />
        <XAxis dataKey="label" axisLine={false} tickLine={false} interval={0} height={24} />
        <YAxis hide domain={[0, "auto"]} />
        <Tooltip
          isAnimationActive={false}
          content={({ active, payload }) => {
            const point = payload?.[0]?.payload as TrendPoint | undefined;
            return active && point ? tooltip(point) : null;
          }}
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
            type="monotone"
            className="lk-trend-budget"
            dot={false}
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
