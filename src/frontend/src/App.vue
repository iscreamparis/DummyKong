<template>
  <div class="app">
    <h1>DummyKong — Fractal Viewer</h1>
    <FractalViewer />
  </div>
</template>

<script setup lang="ts">
import FractalViewer from './components/FractalViewer.vue'
</script>

<style>
body {
  margin: 0;
  background: #0f0f0f;
  color: #eee;
  font-family: sans-serif;
}
.app {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 2rem;
}
</style>
