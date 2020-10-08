include <../libraries/MCAD/units.scad>
include <../libraries/MCAD/bearing.scad>
include <../libraries/nutsnbolts/cyl_head_bolt.scad>
include <../libraries/nutsnbolts/data-metric_cyl_head_bolts.scad>
include <../libraries/nutsnbolts/data-access.scad>

Plastic = [0, 0.5, 1];

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

module squareTubeSteel(width, length, thickness, center=false) {
  color(Stainless)
  linear_extrude(height=length)
  difference() {
    roundedSquare(width=width, cornerRadius=1, center=center);
    roundedSquare(width=width-thickness, cornerRadius=1, center=center);
  }
}

function fromDiag(x) = x / sqrt(2);
function toDiag(x) = x * sqrt(2);

function cartTop(wheelShift, wheelRadius, steelWidth) =
  fromDiag(wheelRadius + steelWidth/2) + 2 * fromDiag(wheelRadius);

module angleWheelRollerAssembly(bearingModel,
                                wheelRadius,
                                steelWidth,
                                plasticColor=Plastic) {
    wheelWidth = bearingDimensions(model=bearingModel)[2];
    wheelShift = fromDiag(wheelRadius + steelWidth/2);
    module wheels() {
      translate([0, wheelShift, wheelShift])
        rotate(45, [1, 0, 0])
          wheelAssembly(bearingModel, wheelRadius,
                        wheelColor=plasticColor, center=true);
      translate([0, -wheelShift, wheelShift])
        rotate(-45, [1, 0, 0])
          wheelAssembly(bearingModel, wheelRadius,
                        wheelColor=plasticColor, center=true);
    }
    cartTop = wheelShift + 2* fromDiag(wheelRadius) + toDiag(wheelWidth/2);
    module cart() {
      module solidCart() {
        translate([-wheelRadius, 0, 0])
          rotate(90, [0, 1, 0]) rotate(90, [0, 0, 1])
            linear_extrude(2*wheelRadius)
              polygon([
                [-toDiag(steelWidth/2) + toDiag(wheelWidth), toDiag(steelWidth/2)],
                [toDiag(steelWidth/2) - toDiag(wheelWidth), toDiag(steelWidth/2)],
                [wheelShift + fromDiag(wheelRadius) - toDiag(wheelWidth/2),
                 wheelShift + fromDiag(wheelRadius) + toDiag(wheelWidth/2)],
                [wheelShift - toDiag(wheelWidth/2), cartTop],
                [-(wheelShift - toDiag(wheelWidth/2)), cartTop],
                [-(wheelShift + fromDiag(wheelRadius) - toDiag(wheelWidth/2)),
                 wheelShift + fromDiag(wheelRadius) + toDiag(wheelWidth/2)]
              ]);
      }
      module nutcatches() {
        //translate([0, wheelShift, wheelShift])
          rotate(45, [1, 0, 0])
            translate([0, _get_nut_height("M8")/2, _get_nut_height("M8")/2]) // center
              nutcatch_sidecut(name="M8", l=wheelRadius + epsilon);
      }
      difference() {
        solidCart();
        scale([100, 1, 1]) nutcatches();
      }
      #nutcatches();
    }
    module boltAndNut() {
      translate([0, 0, wheelGap/2 + width])
        screw("M8x35");
      translate([0, 0, -(wheelGap/2 + width)])
        nut("M8");
    }
    #wheels();
    color(plasticColor)
      cart();
    // TODO
    *color(Steel)
      boltAndNut();
}

angleWheelRollerAssembly(
  608,
  20*mm,
  30*mm,
  Plastic
);

module cartDoorConnection(steelWidth, height, gapUnderRunner) {
  translate([0, 0, -height])
    squareTubeSteel(width=steelWidth, length=height - (2*steelWidth/sqrt(2) + gapUnderRunner), center=true);
  translate([0, -steelWidth/2, -steelWidth*sqrt(2)/2 - steelWidth/2 - gapUnderRunner])
    rotate(-90, [1, 0, 0])
      squareTubeSteel(width=steelWidth, length=3*steelWidth, center=true);
  translate([0, 2*steelWidth, -steelWidth*sqrt(2)/2 - gapUnderRunner])
    squareTubeSteel(width=steelWidth, length=(2*steelWidth*sqrt(2) + gapUnderRunner ), center=true);
  translate([0, -steelWidth/2, steelWidth*sqrt(2)*(3/2)])
    rotate(-90, [1, 0, 0])
      squareTubeSteel(width=steelWidth, length=3*steelWidth, center=true);
}

module doorFrame(doorHeight, doorWidth, steelWidth, steelThickness) {
  module sides() {
    translate([0, 0, -doorHeight])
      squareTubeSteel(width=steelWidth, length=doorHeight, center=true);
    translate([doorWidth, 0, -doorHeight])
      squareTubeSteel(width=steelWidth, length=doorHeight, center=true);
  }
  module horizontals() {
    rotate(90, [0, 1, 0])
      squareTubeSteel(width=steelWidth, length=doorWidth, center=true);
    translate([0, 0, -doorHeight/3])
      rotate(90, [0, 1, 0])
        squareTubeSteel(width=steelWidth, length=doorWidth, center=true);
    translate([0, 0, -2*doorHeight/3])
      rotate(90, [0, 1, 0])
        squareTubeSteel(width=steelWidth, length=doorWidth, center=true);
    translate([0, 0, -doorHeight])
      rotate(90, [0, 1, 0])
        squareTubeSteel(width=steelWidth, length=doorWidth, center=true);
  }
  module diagBracing() {
    module oneWay() {
      translate([0, 0, -doorHeight])
        rotate(45, [0, 1, 0])
          squareTubeSteel(width=steelWidth, length=sqrt(2)*doorHeight/3, center=true);
      translate([0, 0, -doorHeight/3])
        rotate(45, [0, 1, 0])
          squareTubeSteel(width=steelWidth, length=sqrt(2)*doorHeight/3, center=true);
      translate([0, 0, -2*doorHeight/3])
        rotate(45, [0, 1, 0])
          squareTubeSteel(width=steelWidth, length=sqrt(2)*doorHeight/3, center=true);
    }
    oneWay();
    translate([doorWidth, 0, 0])
      rotate(180, [0, 0, 1])
        oneWay();
  }
  sides();
  horizontals();
  diagBracing();
}

module rollerDoor(doorHeight=2.5*m,
                  doorWidth=3*m,
                  gapRunnerToDoor=200*mm,
                  extraRunner=200*mm,
                  gapRunnerToCart=5*mm,
                  bearingModel=608,
                  //wheelGap=12*mm,
                  wheelRadius=20*mm,
                  steelWidth=30*mm,
                  steelThickness=2*mm) {
  let(
    wheelThickness = bearingDimensions(model=bearingModel)[2],
    steelZOffset = -(steelWidth * sqrt(2)/2)
                   +wheelGap/2
                   -(wheelRadius - wheelThickness)
   ){
    angleWheelRollerAssembly(bearingModel, wheelRadius, steelWidth);
    cartDoorConnection(steelWidth, gapRunnerToDoor, gapRunnerToCart);
    translate([doorWidth, 0, 0])
      {
        angleWheelRollerAssembly(bearingModel, wheelRadius, steelWidth);
        cartDoorConnection(steelWidth, gapRunnerToDoor, gapRunnerToCart);
      }
    // Move under wheels
    translate([0, 0, steelZOffset])
      // goes along roller direction
      translate([-extraRunner, 0, 0]) rotate(90, [0, 1, 0])
      rotate(45, [0, 0, 1])
        squareTubeSteel(width=steelWidth,
                        length=2*doorWidth + 2*extraRunner,
                        thickness=steelThickness,
                        center=true);
  }
  translate([0, 0, -gapRunnerToDoor*mm])
    doorFrame(doorHeight, doorWidth, steelWidth, steelThickness);
}

*rollerDoor($fn=30);
