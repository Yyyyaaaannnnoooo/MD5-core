/**
 * @name p5.asciify | Playground
 * @description Playground sketch to experiment with p5.asciify
 * @author humanbydefinition
 * @link https://github.com/humanbydefinition/p5.asciify
 */

let asciifier;
let brightnessRenderer;
let edgeRenderer;

let font;

function preload() {
  font = loadFont("./fonts/Web437_EagleSpCGA_Alt3-2y.woff");
}

function setup() {
  setAttributes("antialias", false);
  let cnv = createCanvas(windowWidth, windowHeight, WEBGL);
  cnv.parent("#c")
}

// Set up stuff relevant to p5.asciify here
// This function is called automatically after `setup()`
function setupAsciify() {
  // Fetch the default `P5Asciifier` instance
  asciifier = p5asciify.asciifier();

  // Fetch the pre-defined "brightness" and "edge" renderers
  brightnessRenderer = asciifier.renderers().get("brightness");
  edgeRenderer = asciifier.renderers().get("edge");

  // p5asciify.asciifier().renderers().swap("brightness", "edge");

  // Update the font to use
  //asciifier.font(font);

  // Update the font size
  asciifier.fontSize(8);

  // Update the pre-defined `brightness` renderer
  brightnessRenderer.update({
    enabled: true,
    characters: " fh5hjl",
    characterColor: "#ffffff",
    characterColorMode: "sampled", // or "fixed"
    backgroundColor: "#000000",
    backgroundColorMode: "fixed", // or "sampled"
    invertMode: true, // swap char and bg colors
    rotationAngle: 0, // rotation angle in degrees
    flipVertically: false,
    flipHorizontally: false,
  });

  edgeRenderer.update({
    enabled: false,
    characters: "-/|\\-/|\\", // should be 8 characters long
    characterColor: "#ffffff",
    characterColorMode: "fixed", // or "sampled"
    backgroundColor: "#000000",
    backgroundColorMode: "fixed", // or "sampled"
    invertMode: false, // swap char and bg colors
    rotationAngle: 0, // rotation angle in degrees
    flipVertically: false,
    flipHorizontally: false,
    sampleThreshhold: 16, // sample threshold for edge detection
    sobelThreshold: 0.5, // sobel threshold for edge detection
  });
}
let sze = 50;
// Draw anything on the canvas to be asciified
function draw() {
  clear();
  fill(255);
  stroke("#afa")
  strokeWeight(8)
  // normalMaterial();
  push()
  translate(-200, 0, 0)
  rotateY(radians(frameCount* 0.1));
  directionalLight(255, 255, 255, 0, 0, -1);
  box(sze, 500, sze)
  pop()

  push()
  translate(0, 0, 0)
  rotateY(radians(frameCount* 0.1));
  directionalLight(255, 255, 255, 0, 0, -1);
  box(sze, 500, sze)
  pop()

  push()
  translate(200, 0, 0)
  rotateY(radians(frameCount* -0.1));
  directionalLight(255, 255, 255, 0, 0, -2);
  box(sze, 500, sze)
  pop()
  directionalLight(255, 255, 255, 0, 0, -2);
}

// Draw on top of the asciified content
// function drawAsciify() {
//   const fpsText = "FPS:" + Math.min(Math.ceil(frameRate()), 60);

//   noStroke();
//   fill(0);
//   rect(
//     -width / 2,
//     height / 2 - textAscent() - 4,
//     textWidth(fpsText),
//     textAscent()
//   );

//   textFont(asciifier.fontManager.font);
//   textSize(64);
//   fill(255, 255, 0);
//   // text(fpsText, -width / 2, height / 2);
// }

function windowResized() {
  resizeCanvas(windowWidth, windowHeight);
}


// function update_render_text(txt) {
//   brightnessRenderer.update({
//     enabled: true,
//     characters: txt,
//     characterColor: "#ffffff",
//     characterColorMode: "sampled", // or "fixed"
//     backgroundColor: "#000000",
//     backgroundColorMode: "fixed", // or "sampled"
//     invertMode: true, // swap char and bg colors
//     rotationAngle: 0, // rotation angle in degrees
//     flipVertically: false,
//     flipHorizontally: false,
//   });
// }
