// import { useEffect, useRef, type HtmlHTMLAttributes } from 'react';
// import { Chart } from '@antv/g2';
// import * as d3 from 'd3-voronoi';
// import type {
//   DeviceCoordinate,
//   VoronoiPolygon,
// } from '@/features/brand/types/visualizationTypes';
// import { cn } from '@/shared/lib';

// type VoronoiChartProps = {
//   devices: DeviceCoordinate[];
//   width?: number;
//   height?: number;
// } & HtmlHTMLAttributes<HTMLDivElement>;

// export const VoronoiChart = ({
//   devices,
//   width = 800,
//   height = 600,
//   className,
// }: VoronoiChartProps) => {
//   const chartRef = useRef<HTMLDivElement>(null);
//   const chartInstanceRef = useRef<Chart | null>(null);

//   useEffect(() => {
//     if (!chartRef.current || devices.length === 0) return;

//     // Clear existing chart
//     if (chartInstanceRef.current) {
//       chartInstanceRef.current.destroy();
//     }

//     // Create Voronoi layout
//     const layout = (data: DeviceCoordinate[]): VoronoiPolygon[] => {
//       return d3
//         .voronoi()
//         .x((d: any) => d.x)
//         .y((d: any) => d.y)
//         .extent([
//           [0, 0],
//           [width, height],
//         ])
//         .polygons(data)
//         .map((polygon) => {
//           if (!polygon) return null;
//           return {
//             x: polygon.map((point) => point[0]),
//             y: polygon.map((point) => point[1]),
//             // @ts-ignore - d3-voronoi attaches data to polygon
//             data: polygon.data,
//           };
//         })
//         .filter((p): p is VoronoiPolygon => p !== null);
//     };

//     const voronoiData = layout(devices);

//     // Create G2 Chart
//     const chart = new Chart({
//       container: chartRef.current,
//       autoFit: true,
//       paddingLeft: 0,
//       paddingRight: 0,
//       paddingTop: 0,
//       paddingBottom: 0,
//     });

//     // Draw Voronoi Cells
//     chart
//       .polygon()
//       .data(voronoiData)
//       .encode('x', 'x')
//       .encode('y', 'y')
//       .encode('color', (d) => {
//         if (d.data.status === 'offline') return '#d9d9d9';
//         return d.data.device_type === 'esp32' ? '#52c41a' : '#1677ff';
//       })
//       .scale('x', { domain: [0, width] })
//       .scale('y', { domain: [0, height] })
//       .scale('color', {
//         type: 'ordinal',
//         domain: ['#52c41a', '#1677ff', '#d9d9d9'],
//         range: ['#52c41a', '#1677ff', '#d9d9d9'],
//       })
//       .axis(false)
//       .style('stroke', '#fff')
//       .style('strokeWidth', 2)
//       .style('fillOpacity', 0.25)
//       .tooltip({
//         title: (d) => d.data.device_name,
//         items: [
//           {
//             name: 'Device ID',
//             value: (d) => d.data.device_id,
//           },
//           {
//             name: 'Type',
//             value: (d) => d.data.device_type.toUpperCase(),
//           },
//           {
//             name: 'Status',
//             value: (d) => d.data.status.toUpperCase(),
//           },
//           {
//             name: 'Signal',
//             value: (d) => `${d.data.signal_strength || 0}%`,
//           },
//         ],
//       });

//     // Draw Device Points
//     chart
//       .point()
//       .data(devices)
//       .encode('x', 'x')
//       .encode('y', 'y')
//       .encode('color', (d) => {
//         if (d.status === 'offline') return '#d9d9d9';
//         return d.device_type === 'esp32' ? '#52c41a' : '#1677ff';
//       })
//       .encode('size', 10)
//       .encode('shape', 'point')
//       .scale('x', { domain: [0, width] })
//       .scale('y', { domain: [0, height] })
//       .style('stroke', '#fff')
//       .style('strokeWidth', 2)
//       .tooltip(false);

//     // Render
//     chart.render();

//     chartInstanceRef.current = chart;

//     return () => {
//       chart.destroy();
//     };
//   }, [devices, width, height]);

//   return (
//     <div
//       ref={chartRef}
//       style={{ width: '100%', height: '100%' }}
//       className={cn('', className)}
//     />
//   );
// };
