<script>
	import EChartsCustomMap from './EChartsCustomMap.svelte';
	import checkInputs from '@evidence-dev/component-utilities/checkInputs';
	import formatTitle from '@evidence-dev/component-utilities/formatTitle';
	import getColumnSummary from '@evidence-dev/component-utilities/getColumnSummary';

	const numberFormatter = new Intl.NumberFormat('es-ES', {
		minimumFractionDigits: 0,
		maximumFractionDigits: 2
	});

	const DEFAULT_NEGATIVE_COLORS = [
		'#67000d',
		'#a50f15',
		'#cb181d',
		'#ef3b2c',
		'#fb6a4a',
		'#fc9272',
		'#fcbba1',
		'#fee0d2'
	];

	const DEFAULT_POSITIVE_COLORS = [
		'#edf8fb',
		'#ccece6',
		'#99d8c9',
		'#66c2a4',
		'#41ae76',
		'#238b45',
		'#006d2c',
		'#00441b'
	];

	const DEFAULT_ZERO_COLOR = '#ffffff';
	const DIVERGING_STEPS = 32;

	const normalizeHex = (input) => {
		if (typeof input !== 'string') {
			return null;
		}
		let hex = input.trim();
		if (!hex) {
			return null;
		}
		if (hex.startsWith('#')) {
			hex = hex.slice(1);
		}
		if (hex.length === 3) {
			hex = hex
				.split('')
				.map((char) => char + char)
				.join('');
		}
		if (hex.length !== 6) {
			return null;
		}
		if (!/^[0-9a-fA-F]{6}$/.test(hex)) {
			return null;
		}
		return `#${hex.toLowerCase()}`;
	};

	const hexToRgb = (input) => {
		const normalized = normalizeHex(input);
		if (!normalized) {
			return { r: 0, g: 0, b: 0 };
		}
		const value = parseInt(normalized.slice(1), 16);
		return {
			r: (value >> 16) & 255,
			g: (value >> 8) & 255,
			b: value & 255
		};
	};

	const rgbToHex = ({ r, g, b }) => {
		const toHex = (channel) => {
			const clamped = Math.max(0, Math.min(255, Math.round(channel)));
			return clamped.toString(16).padStart(2, '0');
		};
		return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
	};

	const interpolatePalette = (palette, count) => {
		if (!Array.isArray(palette) || palette.length === 0 || count <= 0) {
			return [];
		}
		if (palette.length === 1) {
			const color = normalizeHex(palette[0]) ?? '#000000';
			return Array(count).fill(color);
		}
		const stops = palette.map((color) => hexToRgb(color));
		const segments = stops.length - 1;
		if (count === 1) {
			return [rgbToHex(stops[stops.length - 1])];
		}
		const result = [];
		for (let i = 0; i < count; i++) {
			const t = i / (count - 1);
			const scaled = t * segments;
			const index = Math.min(Math.floor(scaled), segments - 1);
			const localT = scaled - index;
			const start = stops[index];
			const end = stops[index + 1] ?? start;
			result.push(
				rgbToHex({
					r: start.r + (end.r - start.r) * localT,
					g: start.g + (end.g - start.g) * localT,
					b: start.b + (end.b - start.b) * localT
				})
			);
		}
		return result;
	};

	export let mapName = undefined;
	export let mapJson = undefined;

	export let data = undefined;

	export let region = undefined;
	export let value = undefined;

	export let min = undefined;
	export let max = undefined;

	export let title = undefined;
	export let subtitle = undefined;

	export let link = undefined;
	let hasLink = link !== undefined;

	let chartType = 'Custom Map';
	let error;

	let config;

	// color palettes
	export let colorScale = 'blue';
	export let colorPalette = undefined;
	let colorArray;
	$: {
		if (Array.isArray(colorPalette) && colorPalette.length > 0) {
			colorArray = colorPalette;
		} else if (colorScale === 'green') {
			colorArray = [
				'#f7fcfd',
				'#e5f5f9',
				'#ccece6',
				'#99d8c9',
				'#66c2a4',
				'#41ae76',
				'#238b45',
				'#006d2c',
				'#00441b'
			];
		} else if (colorScale === 'red') {
			colorArray = [
				'#fff5f0',
				'#fee0d2',
				'#fcbba1',
				'#fc9272',
				'#fb6a4a',
				'#ef3b2c',
				'#cb181d',
				'#a50f15',
				'#67000d'
			];
		} else if (colorScale === 'bluegreen') {
			colorArray = [
				'#f7fcf0',
				'#e0f3db',
				'#ccebc5',
				'#a8ddb5',
				'#7bccc4',
				'#4eb3d3',
				'#2b8cbe',
				'#0868ac',
				'#084081'
			];
		} else {
			colorArray = [
				'#f7fbff',
				'#deebf7',
				'#c6dbef',
				'#9ecae1',
				'#6baed6',
				'#4292c6',
				'#2171b5',
				'#08519c',
				'#08306b'
			];
		}
	}

export let diverging = false;
export let negativeColorPalette = undefined;
export let positiveColorPalette = undefined;
export let zeroColor = DEFAULT_ZERO_COLOR;

	export let abbreviations = false;
	export let abbreviationProperty = undefined;
	abbreviations = abbreviations === 'true' || abbreviations === true;
diverging = diverging === 'true' || diverging === true;

	export let nameProperty = abbreviations ? 'abbrev' : 'name';

	let columnSummary;
	let featureNameByCode = {};
	let metricLabel = '';

	$: featureNameByCode =
		mapJson?.features?.reduce((acc, feature) => {
			const code = feature?.properties?.code;
			const nom = feature?.properties?.nom;
			if (code) {
				acc[String(code)] = nom ?? code;
			}
			return acc;
		}, {}) ?? {};

	const tooltipFormatter = (params) => {
		const displayName = params?.data?.displayName ?? params?.name ?? '';
		const value = params?.value;
		const valueText = typeof value === 'number' ? numberFormatter.format(value) : value ?? '';
		return `${displayName}<br/>${metricLabel}: ${valueText}`;
	};
	$: try {
		error = undefined;
		if (!region) {
			throw new Error('region is required');
		} else if (!value) {
			throw new Error('value is required');
		}

		const hasData = Array.isArray(data) && data.length > 0;

		if (!hasData) {
			columnSummary = undefined;
			metricLabel = formatTitle(value, undefined);
			config = {
				title: {
					text: title,
					subtext: subtitle
				},
				tooltip: { formatter: tooltipFormatter },
				visualMap: {
					min: 0,
					max: 0,
					show: false
				},
				series: [
					{
						name: metricLabel,
						type: 'map',
						map: mapName,
						nameProperty: nameProperty,
						data: []
					}
				]
			};
		} else {
			checkInputs(data, [region, value]);

			let numericValues = data
				.map((d) => (typeof d[value] === 'number' ? d[value] : parseFloat(d[value])))
				.filter((v) => Number.isFinite(v));
			let minValue = min ?? (numericValues.length ? Math.min(...numericValues) : 0);
			let maxValue = max ?? (numericValues.length ? Math.max(...numericValues) : 0);
			const negativeRange = minValue < 0 ? Math.abs(minValue) : 0;
			const positiveRange = maxValue > 0 ? Math.abs(maxValue) : 0;
			const shouldUseDiverging = diverging && negativeRange > 0 && positiveRange > 0;
			const effectiveNegativePalette =
				Array.isArray(negativeColorPalette) && negativeColorPalette.length > 0
					? negativeColorPalette
					: DEFAULT_NEGATIVE_COLORS;
			const effectivePositivePalette =
				Array.isArray(positiveColorPalette) && positiveColorPalette.length > 0
					? positiveColorPalette
					: DEFAULT_POSITIVE_COLORS;
			const effectiveZeroColor = normalizeHex(zeroColor) ?? DEFAULT_ZERO_COLOR;
			let visualMapColorArray = colorArray;
			if (shouldUseDiverging) {
				const totalRange = negativeRange + positiveRange;
				const baseSteps = Math.max(2, DIVERGING_STEPS);
				let negativeSteps = Math.round((baseSteps * negativeRange) / totalRange);
				let positiveSteps = baseSteps - negativeSteps;
				if (negativeSteps <= 0) {
					negativeSteps = 1;
				}
				if (positiveSteps <= 0) {
					positiveSteps = 1;
					negativeSteps = Math.max(1, baseSteps - positiveSteps);
				}
				const adjustedTotal = negativeSteps + positiveSteps;
				if (adjustedTotal !== baseSteps) {
					positiveSteps += baseSteps - adjustedTotal;
				}
				const negativeGradient = interpolatePalette(effectiveNegativePalette, negativeSteps);
				const positiveGradient = interpolatePalette(effectivePositivePalette, positiveSteps);
				visualMapColorArray = [...negativeGradient, effectiveZeroColor, ...positiveGradient];
			}

			columnSummary = getColumnSummary(data);

			let mapData = JSON.parse(JSON.stringify(data));
			for (let i = 0; i < data.length; i++) {
				mapData[i].name = data[i][region];
				const rawValue = data[i][value];
				mapData[i].value = typeof rawValue === 'number' ? rawValue : parseFloat(rawValue);
				const maybeCode = mapData[i].name;
				const maybeDisplayName = featureNameByCode[String(maybeCode)] ?? data[i].Provincias;
				if (maybeDisplayName) {
					mapData[i].displayName = maybeDisplayName;
				}
				if (link) {
					mapData[i].link = data[i][link];
				}
			}

			const columnMeta = columnSummary?.[value];
			metricLabel = formatTitle(value, columnMeta?.format);

			config = {
				title: {
					text: title,
					subtext: subtitle,
					padding: 0,
					itemGap: 7,
					textStyle: {
						fontSize: 14,
						color: '#374151'
					},
					subtextStyle: {
						fontSize: 13,
						color: '#4B5563',
						overflow: 'break'
					},
					top: '0%'
				},
				textStyle: {
					fontFamily: 'sans-serif'
				},
				tooltip: {
					trigger: 'item',
					showDelay: 0,
					transitionDuration: 0.2,
					confine: true,
					axisPointer: {
						// Use axis to trigger tooltip
						type: 'shadow' // 'shadow' as default; can also be 'line' or 'shadow'
					},
					padding: 6,
					borderRadius: 4,
					borderWidth: 1,
					borderColor: '#9CA3AF',
					backgroundColor: 'white',
					extraCssText:
						'box-shadow: 0 3px 6px rgba(0,0,0,.15); box-shadow: 0 2px 4px rgba(0,0,0,.12); z-index: 1;',
					textStyle: {
						color: '#111827',
						fontSize: 12,
						fontWeight: 400
					},
					order: 'valueDesc',
					formatter: tooltipFormatter
				},

				visualMap: {
					top: 'middle',
					left: 'left',
					min: minValue,
					max: maxValue,
					itemWidth: 15,
					show: true,
					text: ['Alto', 'Bajo'],
					inRange: {
						color: visualMapColorArray
					},
					calculable: true,
					inverse: false,
					formatter: (value) => numberFormatter.format(value)
				},
				series: [
					{
						name: metricLabel,
						type: 'map',
						zoom: 1.1,
						top: 45,
						roam: false,
						map: mapName,
						nameProperty: nameProperty,
						itemStyle: {
							borderColor: '#9CA3AF',
							areaColor: '#F3F4F6'
						},
						emphasis: {
							itemStyle: {
								areaColor: '#D1D5DB'
							},
							label: {
								show: true,
								color: '#111827',
								formatter: ({ data }) => data?.displayName ?? ''
							}
						},
						select: {
							disabled: false,
							itemStyle: {
								areaColor: '#D1D5DB'
							},
							label: {
								color: '#111827'
							}
						},
						data: mapData
					}
				],
				media: [
					{
						query: {
							maxWidth: 500
						},
						option: {
							series: [
								{
									top: title ? (subtitle ? 48 : 32) : 25,
									zoom: title ? (subtitle ? 0.9 : 1.1) : 1.1
								}
							]
						}
					},
					{
						option: {
							series: [
								{
									top: title ? (subtitle ? 53 : 45) : 35,
									zoom: title ? (subtitle ? 1.1 : 1.1) : 1.1
								}
							]
						}
					}
				]
			};
		}
	} catch (e) {
		error = e?.message ?? String(e);
		config = {
			title: {
				text: title,
				subtext: subtitle
			},
			tooltip: { formatter: tooltipFormatter },
			visualMap: {
				min: 0,
				max: 0,
				show: false
			},
			series: [
				{
					name: metricLabel,
					type: 'map',
					map: mapName,
					nameProperty: nameProperty,
					data: []
				}
			]
		};
	}

	$: data, config;
</script>

	<EChartsCustomMap {config} {data} {hasLink} {mapJson} {mapName}/>

	{#if link}
		{#each data as row}
			{#if row[link] !== undefined}
				<!-- svelte-ignore a11y-missing-content -->
				<a href={row[link]} style="display: none;">{row[link]}</a>
			{/if}
		{/each}
	{/if}
