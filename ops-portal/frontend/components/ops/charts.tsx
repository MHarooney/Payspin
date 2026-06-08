'use client';

import {
  ArcElement,
  BarElement,
  CategoryScale,
  Chart as ChartJS,
  ChartData,
  ChartOptions,
  Filler,
  Legend,
  LinearScale,
  LineElement,
  PointElement,
  Tooltip,
} from 'chart.js';
import { Bar, Doughnut, Line } from 'react-chartjs-2';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  LineElement,
  PointElement,
  ArcElement,
  Filler,
  Tooltip,
  Legend,
);

ChartJS.defaults.color = '#8b93a7';
ChartJS.defaults.borderColor = '#2a2838';
ChartJS.defaults.font.family = "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif";
ChartJS.defaults.font.size = 11;

export const C = {
  accent: '#07d8dd',
  brand: '#fc00ff',
  blue: '#3b82f6',
  amber: '#f5a623',
  red: '#ff4d4f',
  purple: '#6b4ec4',
};

const grid = { grid: { color: '#1e1d2b' } };

const baseOptions = (showLegend = false): ChartOptions =>
  ({
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: showLegend, position: 'bottom' } },
    scales: { x: grid, y: { ...grid, beginAtZero: true } },
  }) as ChartOptions;

export function BarChart({
  data,
  options,
}: {
  data: ChartData<'bar'>;
  options?: ChartOptions<'bar'>;
}) {
  return <Bar data={data} options={(options ?? baseOptions()) as ChartOptions<'bar'>} />;
}

export function LineChart({
  data,
  options,
  legend,
}: {
  data: ChartData<'line'>;
  options?: ChartOptions<'line'>;
  legend?: boolean;
}) {
  return <Line data={data} options={(options ?? baseOptions(legend)) as ChartOptions<'line'>} />;
}

export function DoughnutChart({ data }: { data: ChartData<'doughnut'> }) {
  const options: ChartOptions<'doughnut'> = {
    responsive: true,
    maintainAspectRatio: false,
    cutout: '62%',
    plugins: { legend: { position: 'bottom' } },
  };
  return <Doughnut data={data} options={options} />;
}

export function line(label: string, values: number[], color: string, fill = true): ChartData<'line'>['datasets'][0] {
  return {
    label,
    data: values,
    borderColor: color,
    backgroundColor: color + '22',
    fill,
    tension: 0.35,
    borderWidth: 2,
    pointRadius: 0,
    pointHoverRadius: 4,
  };
}
