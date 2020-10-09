include <libraries/MCAD/units.scad>
include <libraries/MCAD/bearing.scad>
include <libraries/nutsnbolts/cyl_head_bolt.scad>
include <libraries/nutsnbolts/data-metric_cyl_head_bolts.scad>
include <libraries/nutsnbolts/data-access.scad>
include <squareTubeSteel.scad>

bearingModel = 608;
doorHeight = 2.5*m;
doorWidth = 3*m;
extraRail = 200*mm;
gapRailToCart = 5*mm;
wheelRadius = 20*mm;
steelWidth = 30*mm;
wheelClearance = 8*mm;
steelThickness = 2*mm;
washerWidth = 2*mm;
nutInset = 8*mm;
clh = 0.1; // height clearance inside nut catch

function totalSteel() =
  4*doorWidth + // horizontals
  2*doorHeight + // verticals
  6*(doorHeight/3)*sqrt(2) + // diag bracing
  2*(
     2*steelWidth + 2*wheelRadius*sqrt(2) +
     //steelWidth + cartTop +
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
nutheight = _get_nut_height("M8");

module m8Washer(radius=8*mm, thickness=2*mm, center=false) {
  difference() {
      cylinder(h=thickness, r1=radius, r2=radius, center=center);
      translate([0, 0, center ? 0 : -epsilon])
        cylinder(h=thickness + 2*epsilon, r1=4*mm, r2=4*mm, center=center);
  }
}

module dualBearing(center=false) {
  zOffset = center ? -bearingDimensions(model=bearingModel)[2] : 0;
  translate([0, 0, zOffset]) {
    bearing(model=bearingModel);
    translate([0, 0, bearingDimensions(model=bearingModel)[2]])
      bearing(model=bearingModel);
  }
}

// Cut out two bearings from a cylinder
module dualBearingWheel(center=false) {
  let(
    height = 2 * bearingDimensions(model=bearingModel)[2]
  )
  color(Plastic)
    difference() {
      cylinder(
        h=height - epsilon,
        r1=wheelRadius,
        r2=wheelRadius,
        center=center
      );
      hull()
        scale([1, 1, 1 + epsilon])
          dualBearing(center=center);
    };
}

module wheelAssembly(center=false) {
  dualBearingWheel(center=center);
  dualBearing(center=center);
}

module cart() {
  translate([-steelWidth/2, 0, toDiag(steelWidth/2 + wheelRadius)])
  rotate(45, [1, 0, 0])
    rotate(90, [0, 1, 0])
      doorTube(length=steelWidth, center=true);
}

module angleWheelRollerAssembly() {
    module wheelPositions() {
      translate([0, wheelShift, wheelShift])
        rotate(45, [1, 0, 0])
          translate([0, 0, -wheelWidth/2])
            children();
      translate([0, -wheelShift, wheelShift])
        rotate(-45, [1, 0, 0])
          translate([0, 0, -wheelWidth/2])
            children();
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
    module washers() {
      wheelPositions()
        translate([0, 0, -wheelWidth/2 - washerWidth/2])
          m8Washer(center=true);
      wheelPositions()
        translate([0, 0, wheelWidth/2 + washerWidth/2])
          m8Washer(center=true);
    }
    module nuts() {
      wheelPositions()
        translate([0, 0, wheelWidth/2 + washerWidth + nutheight])
          nut("M8");
      wheelPositions()
        translate([0, 0, steelWidth/2 + wheelRadius - wheelWidth/2 - steelThickness/2])
          nut("M8");
      #wheelPositions()
        translate([0, 0, steelWidth/2 + wheelRadius - wheelWidth/2 + nutheight + steelThickness/2])
          nut("M8");
    }
    module bolts() {
      wheelPositions()
        translate([0, 0, -(washerWidth/2 + _get_head_height("M8"))])
          rotate(180, [1, 0, 0])
            screw("M8x45");
    }
    wheelPositions()
      wheelAssembly(center=true);
    color(Stainless) {
      cart();
      bolts();
      washers();
      nuts();
    }
}

module doorTube(length, center=false) {
  squareTubeSteel(
    width=steelWidth,
    length=length,
    thickness=steelThickness,
    center=center
  );
}

module cartDoorConnection() {
  halfCartWidth =
    toDiag(steelWidth/4)
    + fromDiag(wheelRadius*2)
    + wheelWidth;
  // horizontal
  translate([0, -steelWidth/2, -steelWidth*sqrt(2)/2 - steelWidth/2 - gapRailToCart])
    rotate(-90, [1, 0, 0])
      doorTube(length=3*steelWidth/2 + halfCartWidth + steelWidth, center=true);
  // diagonal
  translate([0,
             steelWidth/2 - fromDiag(steelWidth/2),
             -(toDiag(steelWidth + wheelRadius) + gapRailToCart + 3*steelWidth - toDiag(steelWidth/2))])
    rotate(-45, [1, 0, 0])
      doorTube(length=steelWidth/2 + halfCartWidth + steelWidth + toDiag(steelWidth), center=true);
  // vertical
  translate([0, steelWidth/2 + halfCartWidth, -toDiag(steelWidth/2) - gapRailToCart])
    doorTube(length=toDiag(steelWidth + wheelRadius) + gapRailToCart,
             center=true);
  translate([0, 3*steelWidth/2 + halfCartWidth, -toDiag(steelWidth/2) - gapRailToCart])
    doorTube(length=toDiag(steelWidth + wheelRadius) + gapRailToCart,
             center=true);
  // horizontal
  difference() {
    translate([0, -steelWidth/2, steelWidth/2 + toDiag(steelWidth/2 + wheelRadius)])
      rotate(-90, [1, 0, 0])
        doorTube(length=steelWidth/2 + halfCartWidth + 2*steelWidth,
                 center=true);
    hull() scale([2, 1, 1])
      cart();
  }
}

module doorFrame(doorHeight, doorWidth, steelWidth, steelThickness) {
  module sides() {
    module side() doorTube(length=doorHeight - steelWidth, center=true);
    translate([0, 0, -doorHeight + steelWidth/2]) side();
    translate([doorWidth, 0, -doorHeight + steelWidth/2]) side();
  }
  module horizontals() {
    module horizontalPositions() {
      translate([0, 0, -doorHeight + steelWidth])
        rotate(90, [0, 1, 0])
          {
            children();
            translate([-(doorHeight - steelWidth)/2, 0, 0]) children();
            translate([-(doorHeight - steelWidth), 0, 0]) children();
          }
    }
    horizontalPositions()
      doorTube(length=doorWidth - steelWidth, center=true);
  }
  module diagBracing() {
    module oneSlash() {
      rotate(45, [0, 1, 0])
        doorTube(length=sqrt(2)*doorHeight/4,
                 center=true);
    }
    module twoSlash() {
      translate([0, 0, -(doorHeight/2 - steelWidth)/2])
        rotate(180, [1, 0, 0])
          oneSlash();
      translate([0, 0, -(doorHeight/2 - steelWidth)/2])
        oneSlash();
    }
    module leftBracing() {
      twoSlash();
      translate([0, 0, -doorHeight/2])
        twoSlash();
    }
    module rightBracing() {
      translate([doorWidth, 0, 0])
        rotate(180, [0, 0, 1])
          leftBracing();
    }
    leftBracing();
    rightBracing();
  }
  sides();
  translate([+steelWidth/2, 0, 0])
    horizontals();
  diagBracing();
}

module rail() {
  translate([-extraRail, 0, 0]) rotate(90, [0, 1, 0])
    rotate(45, [0, 0, 1])
      doorTube(length=2*doorWidth + 2*extraRail,
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
  translate([0, 0, -steelWidth*sqrt(2)/2 - steelWidth/2 - gapRailToCart])
    doorFrame(doorHeight, doorWidth, steelWidth, steelThickness);
}

rollerDoor($fn=30);
