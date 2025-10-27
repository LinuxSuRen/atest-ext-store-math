<template>
  <section style="height: 100%;">
    <h3>函数绘图</h3>

    <div style="margin-bottom: 10px;">
      <label style="margin-right: 10px;">
        <input type="radio" v-model="mode" value="2d" @change="switchMode"> 2D
      </label>
      <label>
        <input type="radio" v-model="mode" value="3d" @change="switchMode"> 3D
      </label>
    </div>

    <input
      v-model="expr"
      :placeholder="mode === '2d' ? '例如 3*x' : '例如 sin(x)*cos(y)'"
      style="width:100%;padding:4px;text-align: center;"
    />
    <button @click="plot">绘制</button>
    <select v-if="mode === '2d'" @change="expr = $event.target.value;plot()">
      <option value="sqrt(2^2 - x^2),-sqrt(2^2 - x^2)">圆</option>
      <option value="2,-2;2,-2">正方形</option>
      <option value="0.1*x^2-4">抛物线</option>
      <option value="log(x)">对数</option>
      <option value="x^2">二次函数</option>
      <option value="sin(x),cos(x)">三角函数</option>
      <option value="exp(-x^2)">高斯函数</option>
      <option value="floor(x),ceil(x),round(x)">取整函数</option>
    </select>
    <select v-else @change="expr = $event.target.value;plot()">
      <option value="sin(x)*cos(y)">正弦余弦波</option>
      <option value="x^2 + y^2">抛物面</option>
      <option value="sqrt(25 - x^2 - y^2)">半球面</option>
      <option value="sin(sqrt(x^2 + y^2))">同心波纹</option>
      <option value="exp(-(x^2 + y^2)/8)">高斯钟面</option>
      <option value="3*sin(x/2)*cos(y/2)">三维波浪</option>
      <option value="sin(x)*sin(y)">格子波纹</option>
      <option value="(x^2 - y^2)/10">双曲抛物面</option>
      <option value="cos(sqrt(x^2 + y^2))*exp(-sqrt(x^2 + y^2)/6)">衰减波纹</option>
      <option value="sin(x)*cos(y)*exp(-(x^2 + y^2)/20)">衰减正弦波</option>
      <option value="abs(sin(x) + sin(y))">折叠波浪</option>
      <option value="sin(x*y/4)">交叉波纹</option>
    </select>

    <span>
      <label>坐标轴范围：</label>
      <input type="number" v-model="axisRange.min" style="width: 60px;" @change="plot" />
      <span> 到 </span>
      <input type="number" v-model="axisRange.max" style="width: 60px;" @change="plot" />
    </span>
    <span style="margin-left: 12px;">
      <label>取值范围：</label>
      <input type="number" v-model.number="valueRange.min" style="width: 60px;" @change="plot" />
      <span> 到 </span>
      <input type="number" v-model.number="valueRange.max" style="width: 60px;" @change="plot" />
      <select v-model="valueMode" @change="plot" style="margin-left:6px;">
        <option value="hide">超出隐藏</option>
        <option value="clamp">超出截断</option>
      </select>
    </span>

    <div id="pretty" style="display: flex; justify-self: center;"></div>
    <div ref="plotDiv" style="margin-top:8px; height: calc(100% - 158px);"></div>
  </section>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import * as math from 'mathjs'
import Plotly from 'plotly.js-dist-min'

declare global {
  interface Window {
    MathJax: any;
  }
}

interface Trace2D {
  x: number[]
  y: number[]
  mode: 'lines'
  type: 'scatter'
  name: string
}

interface Trace3D {
  x?: number[]
  y?: number[]
  // For surface traces Plotly expects z to be a 2D array (rows x cols). For scatter3d it's a flat array.
  z: number[] | number[][]
  type: 'surface' | 'scatter3d'
  name: string
}

type Trace = Trace2D | Trace3D

const expr = ref<string>('sqrt(2^2 - x^2),-sqrt(2^2 - x^2)')
const mode = ref<'2d' | '3d'>('2d')
const plotDiv = ref<HTMLDivElement>() as any
const axisRange = ref({
  min: -5,
  max: 5
})
// valueRange: limits applied to function values (y for 2D, z for 3D)
const valueRange = ref({
  min: -100,
  max: 100
})
// valueMode: 'hide' -> values outside range become NaN; 'clamp' -> values are clamped into range
const valueMode = ref<'hide' | 'clamp'>('hide')

const switchMode = () => {
  expr.value = mode.value === '2d' ? 'sqrt(2^2 - x^2),-sqrt(2^2 - x^2)' : 'sin(x)*cos(y)'
  plot()
}

function plot(): void {
    const traces: Trace[] = []
    if (mode.value === '2d') {
      const items = expr.value.split(';')
      if (items.length == 2) {
        items[0].split(',').forEach(e => {
          if (e !== '') {
            traces.push(draw2D(e, 'x'))
          }
        })
        items[1].split(',').forEach(e => {
          if (e !== '') {
            traces.push(draw2D(e))
          }
        })
      } else if (items.length == 1) {
        expr.value.split(',').forEach(e => {
          if (e !== '') {
            traces.push(draw2D(e))
          }
        })
      } else {
        alert('函数表达式错误')
        return
      }

      const layout = {
        margin: { l: 40, r: 40, t: 40, b: 40 },
        xaxis: { title: { text: 'x' }, range: [axisRange.value.min, axisRange.value.max], automargin: true },
        yaxis: { title: { text: 'y' }, range: [axisRange.value.min, axisRange.value.max], scaleanchor: 'x' as any, scaleratio: 1 },
        annotations: [{
          x: 5,
          y: 5,
          text: 'I',
          showarrow: false,
        }, {
          x: -5,
          y: 5,
          text: 'II',
          showarrow: false,
        }, {
          x: -5,
          y: -5,
          text: 'III',
          showarrow: false,
        }, {
          x: 5,
          y: -5,
          text: 'IV',
          showarrow: false,
        }]
      }

      Plotly.newPlot(plotDiv.value, traces, layout, { responsive: true })
    } else {
      const items = expr.value.split(';')
      if (items.length == 3) { 
        items[0].split(',').forEach(e => {
          if (e !== '') {
            traces.push(draw3D(e, 'x'))
          }
        })
        items[1].split(',').forEach(e => {
          if (e !== '') {
            traces.push(draw3D(e, 'y'))
          }
        })
        items[2].split(',').forEach(e => {
          if (e !== '') {
            traces.push(draw3D(e))
          }
        })
      } else if (items.length == 1) {
        expr.value.split(',').forEach(e => {
          if (e !== '') {
            traces.push(draw3D(e))
          }
        })
      } else {
        alert('函数表达式错误')
        return
      }

      const layout = {
        margin: { l: 40, r: 40, t: 40, b: 40 },
        scene: {
          xaxis: { title: { text: 'x' }, range: [axisRange.value.min, axisRange.value.max] },
          yaxis: { title: { text: 'y' }, range: [axisRange.value.min, axisRange.value.max] },
          zaxis: { title: { text: 'z' }, range: [axisRange.value.min, axisRange.value.max] },
          camera: {
            eye: { x: 1.5, y: 1.5, z: 1.5 }
          }
        }
      }

      Plotly.newPlot(plotDiv.value, traces, layout, { responsive: true })
    }
}

const printPretty = (expr: string) => {
  const pretty = document.getElementById('pretty');
  if (pretty) {
    let parenthesis = 'keep'
    pretty.innerHTML = ''
    try {
      pretty.appendChild(mj(math.parse(expr).toTex({parenthesis: parenthesis})))
    } catch (e) {
      console.error('表达式语法错误: ' + (e as Error).message)
    }
  }
}

function draw2D(expr: string, axis: string = 'y'): Trace2D {
  let compiled: math.EvalFunction
  try {
    compiled = math.compile(expr)
  } catch (e) {
    alert('表达式语法错误: ' + (e as Error).message)
    return null as any
  }

  printPretty(expr)

  const minAxis = -10
  const maxAxis = 10
  const N = 400
  const step = (maxAxis - minAxis) / N
  const x: number[] = []
  const y: number[] = []
  for (let i = 0; i <= N; i++) {
    const xi = minAxis + i * step
    x.push(xi)
    try {
      let yi = compiled.evaluate({ x: xi }) as number
      if (typeof yi !== 'number' || isNaN(yi)) {
        y.push(NaN)
      } else {
        const vmin = valueRange.value.min
        const vmax = valueRange.value.max
        const vminFinite = Number.isFinite(vmin)
        const vmaxFinite = Number.isFinite(vmax)
        if (valueMode.value === 'hide') {
          let outside = false
          if (vminFinite && yi < vmin) outside = true
          if (vmaxFinite && yi > vmax) outside = true
          if (outside) y.push(NaN)
          else y.push(yi)
        } else {
          // clamp
          if (vminFinite && yi < vmin) yi = vmin
          if (vmaxFinite && yi > vmax) yi = vmax
          y.push(yi)
        }
      }
    } catch {
      y.push(NaN)
    }
  }

  const trace: Trace2D = {
    x,
    y,
    mode: 'lines',
    type: 'scatter',
    name: `${axis} = ${expr}`
  }
  if (axis === 'x') {
    trace.y = x
    trace.x = y
  }
  return trace
}

function draw3D(expr: string, axis: string = 'z'): Trace3D {
  let compiled: math.EvalFunction
  try {
    compiled = math.compile(expr)
  } catch (e) {
    alert('表达式语法错误: ' + (e as Error).message)
    return null as any
  }

  printPretty(expr)

  const min = axisRange.value.min
  const max = axisRange.value.max
  const N = 50
  const step = (max - min) / N

  // build 1D x and y coordinates and a 2D z matrix (rows for x, cols for y)
  const xVals: number[] = []
  const yVals: number[] = []
  const zMatrix: number[][] = []

  for (let i = 0; i <= N; i++) {
    const xi = min + i * step
    xVals.push(xi)
  }

  for (let j = 0; j <= N; j++) {
    const yj = min + j * step
    yVals.push(yj)
  }

  for (let i = 0; i <= N; i++) {
    const xi = xVals[i]
    const row: number[] = []
    for (let j = 0; j <= N; j++) {
      const yj = yVals[j]
      try {
        let zij = compiled.evaluate({ x: xi, y: yj }) as number
        // handle sqrt domain issues (e.g. hemisphere)
        if (expr.includes('sqrt') && isNaN(zij)) {
          zij = 0
        }
        if (typeof zij !== 'number' || isNaN(zij)) {
          row.push(NaN)
        } else {
          const vmin = valueRange.value.min
          const vmax = valueRange.value.max
          const vminFinite = Number.isFinite(vmin)
          const vmaxFinite = Number.isFinite(vmax)
          if (valueMode.value === 'hide') {
            let outside = false
            if (vminFinite && zij < vmin) outside = true
            if (vmaxFinite && zij > vmax) outside = true
            if (outside) row.push(NaN)
            else row.push(zij)
          } else {
            // clamp
            if (vminFinite && zij < vmin) zij = vmin
            if (vmaxFinite && zij > vmax) zij = vmax
            row.push(zij)
          }
        }
      } catch {
        row.push(NaN)
      }
    }
    zMatrix.push(row)
  }

  const trace: Trace3D = {
    x: xVals,
    y: yVals,
    z: zMatrix,
    type: 'surface',
    name: `${axis} = ${expr}`
  }

  if (axis === 'x') {
    trace.x = zMatrix[0]
    trace.z = xVals
  } else if (axis === 'y') {
    trace.y = zMatrix[0]
    trace.z = yVals
  }

  return trace
}

const mj = function (tex: string) {
  return window.MathJax?.tex2svg?.(tex, {em: 16, ex: 6, display: false});
}

onMounted(() => plot())
</script>
