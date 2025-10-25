<template>
  <section style="height: 100%;">
    <h3>函数绘图</h3>

    <input
      v-model="expr"
      placeholder="例如 3*x"
      style="width:100%;padding:4px"
    />
    <button @click="plot">绘制</button>
    <select @change="expr= $event.target.value;plot()">
      <option value="sqrt(2^2 - x^2),-sqrt(2^2 - x^2)">圆</option>
      <option value="0.1*x^2-4">抛物线</option>
      <option value="log(x)">对数</option>
      <option value="x^2">二次函数</option>
      <option value="sin(x),cos(x)">三角函数</option>
      <option value="exp(-x^2)">高斯函数</option>
      <option value="floor(x),ceil(x),round(x)">取整函数</option>
    </select>

    <div ref="plotDiv" style="margin-top:8px; height: calc(100% - 98px);"></div>
  </section>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import * as math from 'mathjs'
import Plotly from 'plotly.js-dist-min'

interface Trace {
  x: number[]
  y: number[]
  mode: 'lines'
  type: 'scatter'
  name: string
}

const expr   = ref<string>('sqrt(2^2 - x^2),-sqrt(2^2 - x^2)')
const plotDiv = ref<HTMLDivElement>() as any

function plot(): void {
    const traces: Trace[] = []
    expr.value.split(',').forEach(e => {
      if (e !== '') {
        traces.push(draw(e))
      }
    })

    const layout = {
      margin: { l: 40, r: 40, t: 40, b: 40 },
      xaxis: { title: { text: 'x' }, automargin: true },
      yaxis: { title: { text: 'y' }, scaleanchor: 'x' as any, scaleratio: 1 }
    }

    Plotly.newPlot(plotDiv.value, traces, layout, { responsive: true })
}

function draw(expr: string): Trace {
  let compiled: math.EvalFunction
  try {
    compiled = math.compile(expr)
  } catch (e) {
    alert('表达式语法错误: ' + (e as Error).message)
    return null as any
  }

  const xMin = -10
  const xMax = 10
  const N    = 400
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

  const trace: Trace = {
    x,
    y,
    mode: 'lines',
    type: 'scatter',
    name: `y = ${expr}`
  }

  return trace
}

onMounted(() => plot())
</script>
