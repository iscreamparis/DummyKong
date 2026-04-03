# DummyKong

A demo multi-ecosystem project for testing [KONG](https://github.com/your-org/kong) — the unified dependency manager.

## Structure

```
DummyKong/
├── frontend/        # Vue 3 + Vite (Node.js)
│   ├── package.json
│   ├── vite.config.ts
│   └── src/
├── backend/         # Flask API (Python)
│   ├── requirements.txt
│   └── app.py
└── fractal/         # Rust CLI fractal renderer
    ├── Cargo.toml
    └── src/main.rs
```

## What it does

- **Frontend**: Vue 3 app with a Mandelbrot fractal viewer, parameterized via sliders
- **Backend**: Flask REST API (`POST /api/fractal`) that computes Mandelbrot iterations in Python
- **Fractal CLI**: Rust binary that renders the Mandelbrot set as ASCII art in the terminal

## Running with KONG

```bash
# Generate kong.rules from manifests
kong rules

# Install all dependencies (Python .venv + Node node_modules + Rust source replacement)
kong use

# Clean all virtual environments
kong use --clean
```

## Running manually

```bash
# Backend
cd backend
python app.py

# Frontend (separate terminal)
cd frontend
npm install && npm run dev

# Fractal CLI
cd fractal
cargo run -- 120 40 200
```
