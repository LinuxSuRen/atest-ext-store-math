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

    <div id="pretty" style="display: flex; justify-self: center;"></div>
    <div ref="plotDiv" style="margin-top:8px; height: calc(100% - 128px);"></div>
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
  x: number[]
  y: number[]
  z: number[]
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

const switchMode = () => {
  expr.value = mode.value === '2d' ? 'sqrt(2^2 - x^2),-sqrt(2^2 - x^2)' : 'sin(x)*cos(y)'
  plot()
}

function plot(): void {
    const traces: Trace[] = []
    if (mode.value === '2d') {
      expr.value.split(',').forEach(e => {
        if (e !== '') {
          traces.push(draw2D(e))
        }
      })

      const layout = {
        margin: { l: 40, r: 40, t: 40, b: 40 },
        xaxis: { title: { text: 'x' }, range: [axisRange.value.min, axisRange.value.max], automargin: true },
        yaxis: { title: { text: 'y' }, range: [axisRange.value.min, axisRange.value.max], scaleanchor: 'x' as any, scaleratio: 1 }
      }

      Plotly.newPlot(plotDiv.value, traces, layout, { responsive: true })
    } else {
      traces.push(draw3D(expr.value))

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

function draw2D(expr: string): Trace2D {
  let compiled: math.EvalFunction
  try {
    compiled = math.compile(expr)
  } catch (e) {
    alert('表达式语法错误: ' + (e as Error).message)
    return null as any
  }

  const pretty = document.getElementById('pretty');
  if (pretty) {
    let parenthesis = 'keep'
    pretty.innerHTML = ''
    pretty.appendChild(mj(math.parse(expr).toTex({parenthesis: parenthesis})))
  }

  const xMin = -10
  const xMax = 10
  const N = 400
  const step = (xMax - xMin) / N
  const x: number[] = []
  const y: number[] = []
  for (let i = 0; i <= N; i++) {
    const xi = xMin + i * step
    x.push(xi)
    try {
      const yi = compiled.evaluate({ x: xi }) as number
      y.push(yi)
    } catch {
      y.push(NaN)
    }
  }

  const trace: Trace2D = {
    x,
    y,
    mode: 'lines',
    type: 'scatter',
    name: `y = ${expr}`
  }

  return trace
}

function draw3D(expr: string): Trace3D {
  let compiled: math.EvalFunction
  try {
    compiled = math.compile(expr)
  } catch (e) {
    alert('表达式语法错误: ' + (e as Error).message)
    return null as any
  }

  const pretty = document.getElementById('pretty');
  if (pretty) {
    let parenthesis = 'keep'
    pretty.innerHTML = ''
    pretty.appendChild(mj(math.parse(expr).toTex({parenthesis: parenthesis})))
  }

  const min = axisRange.value.min
  const max = axisRange.value.max
  const N = 50
  const step = (max - min) / N

  const x: number[] = []
  const y: number[] = []
  const z: number[] = []

  for (let i = 0; i <= N; i++) {
    const xi = min + i * step
    
    for (let j = 0; j <= N; j++) {
      const yi = min + j * step
      x.push(xi)
      y.push(yi)
      try {
        let zi = compiled.evaluate({ x: xi, y: yi }) as number
        // 处理半球面的特殊情况
        if (expr.includes('sqrt') && isNaN(zi)) {
          zi = 0 // 将虚数部分设为0，这样就能显示一个完整的半球面
        }
        z.push(zi)
      } catch {
        z.push(NaN)
      }
    }
  }

  const trace: Trace3D = {
    x,
    y,
    z,
    type: 'surface',
    name: `z = ${expr}`
  }
  console.log(trace)

  return trace
}

const mj = function (tex: string) {
  return window.MathJax?.tex2svg?.(tex, {em: 16, ex: 6, display: false});
}

onMounted(() => plot())
</script>
