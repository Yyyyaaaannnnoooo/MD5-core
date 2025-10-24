let windSpeedSlider;
let windDirectionSlider;
let particles = [];
let numParticles = 200;
let anemometerRotation = 0;
let windDirection = 286; // in degrees
let windSpeed = 10;
let gustStartTime = 0;
let gustDirection = 0;
let gustStrength = 0;
let mouseIsPressed = false;
let pmouseX = 0;
let pmouseY = 0;
let mouseInteractionRadius = 300;
const w = innerWidth;
const h = innerHeight;


function add_note (w, h, name){

  particles.push(new Particle(w, h, name));
}

function setup() {
  noCanvas()
  // Set initial mouse position
  pmouseX = mouseX;
  pmouseY = mouseY;
}




function draw() {
  background(0);

  // Handle mouse gust interaction
  if (mouseX > 0 && mouseX < w && mouseY > 0 && mouseY < h) {
    let dx = mouseX - pmouseX;
    let dy = mouseY - pmouseY;
    let mouseSpeed = sqrt(dx * dx + dy * dy);

    if (mouseSpeed > 1) {
      gustStartTime = millis();
      gustStrength = min(mouseSpeed * 0.5, 25);
      gustDirection = atan2(dy, dx) * 180 / PI;
    }
  }

  windDirection = map(mouseX, 0, w, 200, 360);

  // Apply gust effect if active
  let gustActive = (millis() - gustStartTime < 1000);
  let currentGustStrength = 0;

  if (gustActive) {
    // Gradually reduce gust strength
    let gustProgress = (millis() - gustStartTime) / 1000;
    currentGustStrength = gustStrength * (1 - gustProgress);
  }


  // Update and draw particles
  // for (let p of particles) {
  for (let i = particles.length - 1; i >= 0; i--) {
    let p = particles[i];
    // Check if particle is near mouse for interaction
    let particleGustStrength = 0;
    let particleGustDirection = gustDirection;

    if (gustActive && dist(mouseX, mouseY, p.x, p.y) < mouseInteractionRadius) {
      // Scale gust strength based on distance from mouse
      let distanceFactor = 1 - (dist(mouseX, mouseY, p.x, p.y) / mouseInteractionRadius);
      particleGustStrength = currentGustStrength * 2 * distanceFactor;
      // particleGustStrength = currentGustStrength * 4;
    }

    p.update(windSpeed, windDirection, particleGustStrength, particleGustDirection);
    // p.show();

    // Remove particle if it goes above the screen
    if (p.y < -p.size) {
      particles.splice(i, 1);
      p.remove()
    } else {
      p.show();
    }
  }


  // Store current mouse position for next frame
  pmouseX = mouseX;
  pmouseY = mouseY;
  // console.log(particles.length);
  if(particles.length > 200){
    particles.splice(0,1)
    particles[0].remove()
  }
}

class Particle {
  constructor(x, y, name) {
    this.x = x;
    this.y = y;
    this.name = name
    // console.log(this.name);
    this.size = floor(random(2, 6));
    this.blur = map(this.size, 2, 5, 0, 0.75);
    // console.log(this.blur);
    this.speedVariation = random(0.7, 1.5);
    this.noiseOffsetX = random(1000);
    this.noiseOffsetY = random(1000);
    this.color = color(
      random(200, 255),
      random(200, 255),
      random(200, 255),
      random(100, 200)
    );

    this.notes_unicode = ["&#x266a;", "&#x266b;"]
    this.note = document.createElement('div');
    this.note.classList.add('note')
    // this.note.innerHTML = random(this.notes_unicode) + " " + this.name
    this.note.innerHTML = random(this.notes_unicode)
    // console.log(this.note);
    this.note.style.position = "fixed"
    this.note.style.color = "#afa"
    this.note.style.fontSize = (40 - (this.size * 3)) + "px"
    // this.note.style.backgroundColor = "#000"
    // this.note.style.filter = `blur(${this.blur}px)`
    this.note.style.top = y + "px"
    this.note.style.left = x + "px"
    this.note.style.pointerEvents = "none"
    document.body.appendChild(this.note);
  }

  remove() {
    setTimeout(()=>{
      this.note.style.fontSize = "0px"
      // this.note.remove()
    }, 1500)
    setTimeout(()=>{
      this.note.remove()
    }, 2000)
    
  }

  update(speed, direction, gustStrength, gustDirection) {
    // Convert direction to radians
    let dirRad = direction * PI / 180;

    // Calculate base wind force
    let baseForceX = cos(dirRad) * speed * 0.05 * this.speedVariation;
    let baseForceY = sin(dirRad) * speed * 0.05 * this.speedVariation;

    // Calculate gust force if active
    let gustForceX = 0;
    let gustForceY = 0;

    if (gustStrength > 0) {
      let gustRad = gustDirection * PI / 180;
      gustForceX = cos(gustRad) * gustStrength * 0.08;
      gustForceY = sin(gustRad) * gustStrength * 0.08;
    }

    // Add some noise for natural flow
    let noiseX = map(noise(this.noiseOffsetX), 0, 1, -0.3, 0.3);
    let noiseY = map(noise(this.noiseOffsetY), 0, 1, -0.3, 0.3);

    // Apply all forces
    this.x += baseForceX + gustForceX + noiseX;
    this.y += baseForceY + gustForceY + noiseY;

    // Update noise offsets
    this.noiseOffsetX += 0.01;
    this.noiseOffsetY += 0.01;

    // Wrap around edges
    if (this.x > w + this.size) this.x = -this.size;
    if (this.x < -this.size) this.x = w + this.size;
    // if (this.y > h + this.size * 10) this.y = -this.size;
    // if (this.y < -this.size) this.y = h + this.size;
  }

  show() {
    // fill(this.color);
    // noStroke();
    // ellipse(this.x, this.y, this.size);


    this.note.style.top = this.y + "px"
    this.note.style.left = this.x + "px"

  }
}