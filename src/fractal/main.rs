/// Compute Mandelbrot iteration count for a single point.
fn mandelbrot(cx: f64, cy: f64, max_iter: u32) -> u32 {
    let (mut x, mut y) = (0.0f64, 0.0f64);
    for i in 0..max_iter {
        if x * x + y * y > 4.0 {
            return i;
        }
        (x, y) = (x * x - y * y + cx, 2.0 * x * y + cy);
    }
    max_iter
}

fn main() {
    let width: u32 = std::env::args()
        .nth(1)
        .and_then(|s| s.parse().ok())
        .unwrap_or(80);
    let height: u32 = std::env::args()
        .nth(2)
        .and_then(|s| s.parse().ok())
        .unwrap_or(40);
    let max_iter: u32 = std::env::args()
        .nth(3)
        .and_then(|s| s.parse().ok())
        .unwrap_or(100);

    for py in 0..height {
        for px in 0..width {
            let cx = (px as f64 / width as f64) * 3.5 - 2.5;
            let cy = (py as f64 / height as f64) * 2.0 - 1.0;
            let n = mandelbrot(cx, cy, max_iter);
            let ch = if n == max_iter {
                '@'
            } else {
                " .:-=+*#%@".chars().nth((n % 10) as usize).unwrap_or(' ')
            };
            print!("{}", ch);
        }
        println!();
    }
}
