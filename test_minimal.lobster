// Minimal test - just clear screen and check if gl works
gl.window("Test", 640, 480)

while gl.frame() and gl.button("escape") != 1:
    gl.clear(float4 { 0.2, 0.3, 0.5, 1.0 })
