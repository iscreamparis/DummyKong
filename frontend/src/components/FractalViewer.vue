<template>
  <div class="viewer">
    <div class="controls">
      <label>
        Iterations:
        <input v-model.number="iterations" type="number" min="10" max="1000" step="10" />
      </label>
      <label>
        Width:
        <input v-model.number="width" type="number" min="100" max="1920" step="100" />
      </label>
      <label>
        Height:
        <input v-model.number="height" type="number" min="100" max="1080" step="100" />
      </label>
      <button @click="generate" :disabled="loading">
        {{ loading ? 'Generating...' : 'Generate' }}
      </button>
    </div>
    <div v-if="error" class="error">{{ error }}</div>
    <canvas v-if="imageData" ref="canvas" :width="width" :height="height" />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'

const iterations = ref(100)
const width = ref(800)
const height = ref(600)
const loading = ref(false)
const error = ref('')
const imageData = ref<number[] | null>(null)
const canvas = ref<HTMLCanvasElement | null>(null)

async function generate() {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.post('/api/fractal', {
      iterations: iterations.value,
      width: width.value,
      height: height.value,
    })
    imageData.value = res.data.pixels
    await drawPixels(res.data.pixels)
  } catch (e: any) {
    error.value = e.message ?? 'Request failed'
  } finally {
    loading.value = false
  }
}

async function drawPixels(pixels: number[]) {
  await new Promise(r => setTimeout(r, 0))
  if (!canvas.value) return
  const ctx = canvas.value.getContext('2d')!
  const img = ctx.createImageData(width.value, height.value)
  for (let i = 0; i < pixels.length; i++) {
    const v = pixels[i]
    img.data[i * 4 + 0] = (v * 9) % 256
    img.data[i * 4 + 1] = (v * 3) % 256
    img.data[i * 4 + 2] = (v * 6) % 256
    img.data[i * 4 + 3] = 255
  }
  ctx.putImageData(img, 0, 0)
}

onMounted(generate)
</script>

<style scoped>
.viewer { display: flex; flex-direction: column; align-items: center; gap: 1rem; }
.controls { display: flex; gap: 1rem; align-items: center; flex-wrap: wrap; }
label { display: flex; flex-direction: column; gap: 0.25rem; font-size: 0.85rem; }
input { width: 80px; padding: 0.25rem; }
button { padding: 0.5rem 1.5rem; cursor: pointer; }
canvas { border: 1px solid #333; }
.error { color: salmon; }
</style>
