include <libraries/MCAD/units.scad>
include <libraries/MCAD/bearing.scad>
include <libraries/nutsnbolts/cyl_head_bolt.scad>
include <libraries/nutsnbolts/data-metric_cyl_head_bolts.scad>
include <libraries/nutsnbolts/data-access.scad>

bearingModel = 608;
cartTopPop = 20*mm;
doorHeight=2.5*m;
doorWidth=3*m;
gapRunnerToDoor=200*mm;
extraRail=200*mm;
gapRunnerToCart=5*mm;
wheelRadius=30*mm;
steelWidth=30*mm;
steelThickness=2*mm;
washerWidth = 2*mm;
nutInset = 8*mm;
clh = 0.1; // height clearance inside nut catch

function totalSteel() =
  4*doorWidth + // horizontals
  2*doorHeight + // verticals
  6*(doorHeight/3)*sqrt(2) + // diag bracing
  2*(
     gapRunnerToDoor +
     2*steelWidth + 2*wheelRadius*sqrt(2) +
     steelWidth + cartTop +
     2*wheelRadius*sqrt(2) + steelWidth
  ) + // carts
  1*(2*doorWidth + 2*extraRail); // rail

echo("Total steel used (meters):");
echo(totalSteel() / 1000);

Plastic = [0, 0.5, 1];

function fromDiag(x) = x / sqrt(2);
function toDiag(x) = x * sqrt(2);

wheelWidth = 2*bearingDimensions(model=bearingModel)[2];
wheelShift = fromDiag(wheelRadius + steelWidth/2);
cartTop = wheelShift + fromDiag(wheelRadius) + toDiag(wheelWidth/4) + cartTopPop - washerWidth;
nutheight = _get_nut_height("M8");

module m8Washer(radius=8*mm, thickness=2*mm, center=false) {
  difference() {
      cylinder(h=thickness, r1=radius, r2=radius, center=center);
      translate([0, 0, center ? 0 : -epsilon])
        cylinder(h=thickness + 2*epsilon, r1=4*mm, r2=4*mm, center=center);
  }
}

module dualBearing(model, center=false) {
  zOffset = center ? -bearingDimensions(model=model)[2] : 0;
  translate([0, 0, zOffset]) {
    bearing(model=model);
    translate([0, 0, bearingDimensions(model=model)[2]])
      bearing(model=model);
  }
}

// Cut out two bearings from a cylinder
module dualBearingWheel(bearingModel, outerRadius, wheelColor, center=false) {
  let(
    height = 2 * bearingDimensions(model=bearingModel)[2]
  )
  color(wheelColor)
    difference() {
      cylinder(
        h=height - epsilon,
        r1=outerRadius,
        r2=outerRadius,
        center=center
      );
      hull()
        scale([1, 1, 1 + epsilon])
          dualBearing(bearingModel, center=center);
    };
}

module wheelAssembly(bearingModel, outerRadius, wheelColor, center=false) {
  dualBearingWheel(bearingModel, outerRadius, wheelColor, center);
  dualBearing(bearingModel, center=center);
}

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
    roundedSquare(width=width-thickness, cornerRadius=1, center=center);
  }
}

module angleWheelRollerAssembly() {
    module wheels() {
      translate([0, wheelShift, wheelShift])
        rotate(45, [1, 0, 0])
          wheelAssembly(bearingModel, wheelRadius,
                        wheelColor=Plastic, center=true);
      translate([0, -wheelShift, wheelShift])
        rotate(-45, [1, 0, 0])
          wheelAssembly(bearingModel, wheelRadius,
                        wheelColor=Plastic, center=true);
    }
    module wheel_nuts_position() {
      translate([0, -wheelShift, wheelShift])
        rotate(135, [1, 0, 0])
          translate([0, 0, -(wheelWidth/2 + nutheight/2 + nutInset)])
            translate([0, 0, nutheight/2])
              children();
      translate([0, wheelShift, wheelShift])
        rotate(-135, [1, 0, 0])
          translate([0, 0, -(wheelWidth/2 + nutheight/2 + nutInset)])
            translate([0, 0, nutheight/2])
              children();
    }
    module top_nut_position() {
      translate([0, 0, cartTop - nutInset])
        children();
    }
    module nutcatches() {
      wheel_nuts_position()
        nutcatch_sidecut(name="M8", l=wheelRadius + epsilon, clh=clh);
      top_nut_position()
        nutcatch_sidecut(name="M8", l=wheelRadius + epsilon, clh=clh);
    }
    module nuts() {
      wheel_nuts_position()
        nut("M8");
      top_nut_position()
        nut("M8");
    }
    module bolts() {
      wheel_nuts_position()
        translate([0, 0, wheelWidth + washerWidth + _get_head_height("M8")])
          screw("M8x35");
      translate([0, 0, cartTop + steelWidth + washerWidth])
        screw("M8x50");
    }
    module washers() {
      wheel_nuts_position()
        translate([0, 0, nutInset - washerWidth/2])
          m8Washer(center=true);
      wheel_nuts_position()
        translate([0, 0, nutInset + washerWidth/2 + wheelWidth])
          m8Washer(center=true);
      translate([0, 0, cartTop + steelWidth + washerWidth/2])
        m8Washer(center=true);
    }
    module cart() {
      module solidCart() {
        translate([-wheelRadius, 0, 0])
          rotate(90, [0, 1, 0]) rotate(90, [0, 0, 1])
            linear_extrude(2*wheelRadius)
              polygon([
                [-toDiag(steelWidth/2) + toDiag(wheelWidth/2) + fromDiag(washerWidth),
                 toDiag(steelWidth/2) + fromDiag(washerWidth)],
                [toDiag(steelWidth/2) - toDiag(wheelWidth/2) - fromDiag(washerWidth),
                 toDiag(steelWidth/2) + fromDiag(washerWidth)],
                [wheelShift + fromDiag(wheelRadius) - toDiag(wheelWidth/4) - fromDiag(washerWidth),
                 wheelShift + fromDiag(wheelRadius) + toDiag(wheelWidth/4) + fromDiag(washerWidth)],
                [wheelShift + fromDiag(wheelRadius) - toDiag(wheelWidth/4) - cartTopPop + washerWidth, cartTop],
                [-(wheelShift + fromDiag(wheelRadius) - toDiag(wheelWidth/4) - cartTopPop + washerWidth), cartTop],
                [-(wheelShift + fromDiag(wheelRadius) - toDiag(wheelWidth/4) - fromDiag(washerWidth)),
                 wheelShift + fromDiag(wheelRadius) + toDiag(wheelWidth/4) + fromDiag(washerWidth)]
              ]);
      }
      difference() {
        solidCart();
        nutcatches();
        bolts();
      }
    }
    wheels();
    color(Plastic)
      cart();
    color(Stainless) {
      bolts();
      washers();
      nuts();
    }
}

module cartDoorConnection() {
  // Door to under runner (vertical)
  translate([0, 0, -gapRunnerToDoor])
    squareTubeSteel(width=steelWidth,
                    length=gapRunnerToDoor - gapRunnerToCart - toDiag(steelWidth)/2 - steelWidth,
                    center=true);
  // Zig (horizontal)
  translate([0, -steelWidth/2, -steelWidth*sqrt(2)/2 - steelWidth/2 - gapRunnerToCart])
    rotate(-90, [1, 0, 0])
      squareTubeSteel(width=steelWidth,
                      length=2*steelWidth + wheelRadius*2/sqrt(2) + steelWidth/2,
                      center=true);
  // Zag (vertical)
  translate([0, 3*steelWidth/2 + wheelRadius*2/sqrt(2), -steelWidth*sqrt(2)/2 - gapRunnerToCart])
    squareTubeSteel(width=steelWidth,
                    length=steelWidth + toDiag(steelWidth)/2 + cartTop + gapRunnerToCart,
                    center=true);
  // Top (horizontal)
  translate([0, -steelWidth/2, steelWidth/2 + cartTop])
    rotate(-90, [1, 0, 0])
      squareTubeSteel(width=steelWidth,
                      length=wheelRadius*2/sqrt(2) + 3*steelWidth/2,
                      center=true);
}

module doorFrame(doorHeight, doorWidth, steelWidth, steelThickness) {
  module sides() {
    translate([0, 0, -doorHeight + steelWidth/2])
      squareTubeSteel(width=steelWidth, length=doorHeight, center=true);
    translate([doorWidth, 0, -doorHeight + steelWidth/2])
      squareTubeSteel(width=steelWidth, length=doorHeight, center=true);
  }
  module horizontals() {
    module horizontalPositions() {
      translate([0, 0, -doorHeight + steelWidth])
        rotate(90, [0, 1, 0])
          {
            children();
            translate([-(doorHeight - steelWidth)/3, 0, 0]) children();
            translate([-2*(doorHeight - steelWidth)/3, 0, 0]) children();
            translate([-(doorHeight - steelWidth), 0, 0]) children();
          }
    }
    horizontalPositions()
      squareTubeSteel(width=steelWidth, length=doorWidth - steelWidth, center=true);
  }
  module diagBracing() {
    module oneWay() {
      translate([0, 0, -(doorHeight - steelWidth)])
        rotate(45, [0, 1, 0])
          squareTubeSteel(width=steelWidth, length=sqrt(2)*doorHeight/3, center=true);
      translate([0, 0, -(doorHeight - steelWidth)/3])
        rotate(45, [0, 1, 0])
          squareTubeSteel(width=steelWidth, length=sqrt(2)*doorHeight/3, center=true);
      translate([0, 0, -2*(doorHeight - steelWidth)/3])
        rotate(45, [0, 1, 0])
          squareTubeSteel(width=steelWidth, length=sqrt(2)*doorHeight/3, center=true);
    }
    oneWay();
    translate([doorWidth, 0, 0])
      rotate(180, [0, 0, 1])
        oneWay();
  }
  sides();
  translate([+steelWidth/2, 0, 0])
    horizontals();
  diagBracing();
}

module rail() {
  translate([-extraRail, 0, 0]) rotate(90, [0, 1, 0])
    rotate(45, [0, 0, 1])
      squareTubeSteel(width=steelWidth,
                      length=2*doorWidth + 2*extraRail,
                      thickness=steelThickness,
                      center=true);
}

module rollerDoor() {
  angleWheelRollerAssembly();
  cartDoorConnection();
  translate([doorWidth, 0, 0])
    {
      angleWheelRollerAssembly();
      cartDoorConnection();
    }
  rail();
  translate([0, 0, -gapRunnerToDoor - steelWidth/2])
    doorFrame(doorHeight, doorWidth, steelWidth, steelThickness);
}

rollerDoor($fn=30);
