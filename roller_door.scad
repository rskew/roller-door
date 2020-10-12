include <libraries/MCAD/units.scad>
include <libraries/MCAD/bearing.scad>
include <libraries/nutsnbolts/cyl_head_bolt.scad>
include <libraries/nutsnbolts/data-metric_cyl_head_bolts.scad>
include <libraries/nutsnbolts/data-access.scad>
include <squareTubeSteel.scad>

bearingModel = 608;
doorHeight = 2.5*m;
doorWidth = 3*m;
// TODO remove
extraRail = 100*mm;
// TODO remove
extraGapRailToCart = 5*mm;
extraGapRailToDoor = 5*mm;
wheelRadius = 20*mm;
doorSteelWidth = 20*mm;
railSteelWidth = 30*mm;
wheelClearance = 8*mm;
doorSteelThickness = 1.6*mm;
railSteelThickness = 2*mm;
washerWidth = 2*mm;
nutInset = 8*mm;
// height clearance inside nut catch
clh = 0.1;
// So the nut trap fits inside the steel square tube
nutTrapClearanceFactor = 0.01;
// The nuts clash inside the cart, so move them by a fudge-factor
fudge = 1*mm;

Plastic = [0, 0.5, 1];

function fromDiag(x) = x / sqrt(2);
function toDiag(x) = x * sqrt(2);

wheelWidth = 2*bearingDimensions(model=bearingModel)[2];
wheelShift = fromDiag(wheelRadius + railSteelWidth/2);
nutheight = _get_nut_height("M8");
cartPosition = [-doorSteelWidth/2, 0, toDiag(railSteelWidth/2 + wheelRadius)];
gapRailToCart = extraGapRailToCart + railSteelWidth - toDiag(railSteelWidth/2);
halfCartWidth =
  toDiag(railSteelWidth/4)
  + fromDiag(wheelRadius*2)
  + wheelWidth;

module doorTube(length, center=false) {
  squareTubeSteel(
    width=doorSteelWidth,
    length=length,
    thickness=doorSteelThickness,
    center=center
  );
}

module railTube(length, center=false) {
  squareTubeSteel(
    width=railSteelWidth,
    length=length,
    thickness=railSteelThickness,
    center=center
  );
}

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

module cart(position) {
  translate(position)
  rotate(45, [1, 0, 0])
    rotate(90, [0, 1, 0])
      railTube(length=doorSteelWidth, center=true);
}

module angleWheelRollerAssembly() {
    module wheelPositions() {
      translate([0, fudge, fudge])
        translate([0, wheelShift, wheelShift])
          rotate(45, [1, 0, 0])
            translate([0, 0, -wheelWidth/4])
              children();
      translate([0, -fudge, fudge])
        translate([0, -wheelShift, wheelShift])
          rotate(-45, [1, 0, 0])
            translate([0, 0, -wheelWidth/4])
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
    module innerNutPositions() {
      wheelPositions()
        translate([0, 0, railSteelWidth/2 + wheelRadius - 3*wheelWidth/4 + nutheight + railSteelThickness/2])
          children();
    }
    module nuts() {
      wheelPositions()
        translate([0, 0, wheelWidth/2 + washerWidth + nutheight])
          nut("M8");
      wheelPositions()
        translate([0, 0, railSteelWidth/2 + wheelRadius - 3*wheelWidth/4 - railSteelThickness/2])
          nut("M8");
      innerNutPositions()
        nut("M8");
    }
    module bolts(extendFactor=1) {
      wheelPositions()
        translate([0, 0, -(washerWidth/2 + _get_head_height("M8"))])
          rotate(180, [1, 0, 0])
            scale([1, 1, extendFactor])
              screw("M8x40");
    }
    module nutTrap() {
      scale([1, 1 - nutTrapClearanceFactor, 1 - nutTrapClearanceFactor])
        difference() {
          hull()
            translate(cartPosition)
              scale([1, 0.9, 0.9])
                cart([0, 0, 0]);
          cart(cartPosition);
          nuts();
          bolts(extendFactor=2);
          innerNutPositions()
            nutcatch_sidecut("M8");
        }
    }
    wheelPositions() wheelAssembly(center=true);
    color(Stainless) {
      cart(cartPosition);
      bolts();
      washers();
      nuts();
    }
    color(Plastic) nutTrap();
}

module cartDoorConnection() {
  // horizontal
  horizontalLength = 3*doorSteelWidth/2 + halfCartWidth + doorSteelWidth;
  translate([0, -doorSteelWidth/2, -toDiag(railSteelWidth/2) - doorSteelWidth/2 - extraGapRailToDoor])
    rotate(-90, [1, 0, 0])
      doorTube(length=horizontalLength, center=true);
  // diagonal
  translate([0,
             doorSteelWidth/2 - fromDiag(doorSteelWidth/2),
             -(toDiag(railSteelWidth + wheelRadius) + extraGapRailToDoor + 3*doorSteelWidth - toDiag(doorSteelWidth/2))])
    rotate(-45, [1, 0, 0])
      doorTube(length=toDiag(horizontalLength - doorSteelWidth), center=true);
  // vertical
  translate([0, doorSteelWidth/2 + halfCartWidth, -toDiag(railSteelWidth/2) - extraGapRailToDoor])
    doorTube(length=extraGapRailToDoor + toDiag(railSteelWidth) + 2*fromDiag(wheelRadius),
             center=true);
  translate([0, 3*doorSteelWidth/2 + halfCartWidth, -toDiag(railSteelWidth/2) - extraGapRailToDoor])
    doorTube(length=extraGapRailToDoor + toDiag(railSteelWidth) + 2*fromDiag(wheelRadius),
             center=true);
  // horizontal
  difference() {
    scale([0.99, 1, 1]) // TODO remove hack
    translate([0, 0, doorSteelWidth/2 + toDiag(railSteelWidth/2 + wheelRadius)])
      rotate(-90, [1, 0, 0])
        doorTube(length=halfCartWidth + 2*doorSteelWidth,
                 center=true);
    *hull() scale([2, 1, 1]) // TODO uncomment
      cart(cartPosition);
  }
}

module doorFrame(doorHeight, doorWidth, doorSteelWidth) {
  module sides() {
    module side() doorTube(length=doorHeight - doorSteelWidth, center=true);
    translate([0, 0, -doorHeight + doorSteelWidth/2]) side();
    translate([doorWidth, 0, -doorHeight + doorSteelWidth/2]) side();
  }
  module horizontals() {
    module horizontalPositions() {
      translate([0, 0, -doorHeight + doorSteelWidth])
        rotate(90, [0, 1, 0])
          {
            children();
            translate([-(doorHeight - doorSteelWidth)/2, 0, 0]) children();
            translate([-(doorHeight - doorSteelWidth), 0, 0]) children();
          }
    }
    horizontalPositions()
      doorTube(length=doorWidth - doorSteelWidth, center=true);
  }
  module diagBracing() {
    module oneSlash() {
      rotate(45, [0, 1, 0])
        doorTube(length=sqrt(2)*doorHeight/4,
                 center=true);
    }
    module twoSlash() {
      translate([0, 0, -(doorHeight/2 - doorSteelWidth)/2]) {
        oneSlash();
        rotate(180, [1, 0, 0])
          oneSlash();
      }
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
  translate([+doorSteelWidth/2, 0, 0])
    horizontals();
  diagBracing();
}

module rail() {
  translate([-extraRail, 0, 0]) rotate(90, [0, 1, 0])
    rotate(45, [0, 0, 1])
      railTube(length=2*doorWidth + 2*extraRail,
               center=true);
  module bracket() {
    translate([0, toDiag(doorSteelWidth/2), -doorSteelWidth/2])
      rotate(90, [1, 0, 0])
        doorTube(length=halfCartWidth + toDiag(doorSteelWidth), center=true);
    translate([0, -halfCartWidth/2, -3*doorSteelWidth/2])
      rotate(90, [1, 0, 0])
        doorTube(length=(halfCartWidth + toDiag(doorSteelWidth))/2, center=true);
    translate([0,
                -(halfCartWidth + toDiag(doorSteelWidth/2) + doorSteelWidth/2),
                -2*doorSteelWidth])
      doorTube(length=3*doorSteelWidth, center=true);
  }
  *translate([-extraRail + 3*doorSteelWidth/2, 0, 0])
    bracket();
  *translate([doorWidth, 0, 0])
    bracket();
  *translate([2*doorWidth - (-extraRail + 3*doorSteelWidth/2), 0, 0])
    bracket();
}

module rollerDoor() {
  rail();
  translate([0, 0, -fudge]) {
    angleWheelRollerAssembly();
    cartDoorConnection();
    translate([doorWidth, 0, 0])
      {
        angleWheelRollerAssembly();
        cartDoorConnection();
      }
    translate([0, 0, -toDiag(railSteelWidth/2) - doorSteelWidth/2 - extraGapRailToDoor])
      doorFrame(doorHeight, doorWidth, doorSteelWidth);
  }
}

rollerDoor($fn=30);
