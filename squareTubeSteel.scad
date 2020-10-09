module roundedSquare(width, cornerRadius, center=false) {
    minkowski() {
      square(width - 2*cornerRadius, center=center);
      circle(cornerRadius);
    }
}

module squareTubeSteel(width, length, thickness=2*mm, center=false) {
  color(Stainless)
  linear_extrude(height=length)
  difference() {
    roundedSquare(width=width, cornerRadius=1, center=center);
    roundedSquare(width=width-2*thickness, cornerRadius=1, center=center);
  }
}
