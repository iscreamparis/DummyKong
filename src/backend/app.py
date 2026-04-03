import sys
import os

# Allow running as: python app.py
sys.path.insert(0, os.path.dirname(__file__))

from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)


def mandelbrot(cx: float, cy: float, max_iter: int) -> int:
    x, y = 0.0, 0.0
    for i in range(max_iter):
        if x * x + y * y > 4.0:
            return i
        x, y = x * x - y * y + cx, 2 * x * y + cy
    return max_iter


@app.route("/api/fractal", methods=["POST"])
def fractal():
    data = request.get_json(force=True)
    iterations = int(data.get("iterations", 100))
    width = int(data.get("width", 800))
    height = int(data.get("height", 600))

    pixels = []
    for py in range(height):
        for px in range(width):
            cx = (px / width) * 3.5 - 2.5
            cy = (py / height) * 2.0 - 1.0
            pixels.append(mandelbrot(cx, cy, iterations))

    return jsonify({"pixels": pixels, "width": width, "height": height})


@app.route("/api/health")
def health():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    app.run(debug=True, port=5000)
