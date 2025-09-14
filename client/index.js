const socket = io("http://localhost:3000");
socket.emit("panic", "Panic");

// const form = document.getElementById('form');
// const input = document.getElementById('input');
// const submit = document.getElementById("submit");


const text = document.querySelector(".text")
const hash = document.querySelector(".hash")

function highlight_bg() {
  text.style.backgroundColor = "#ccc"
  setTimeout(() => { text.style.backgroundColor = "#00000022" }, 100)
}


let wait_interval = null;
const wait_signs = ["/", "-", "\\", "|"];
let wait_index = 0;
function wait() {
  const span_wait = document.createElement("span")
  hash.appendChild(span_wait)
  wait_interval = setInterval(() => {
    const sign = wait_signs[wait_index];
    span_wait.textContent = sign + " ~~~ HASHING ~~~ " + sign;
    wait_index++;
    if (wait_index >= wait_signs.length) {
      wait_index = 0;
    }
  }, 50);
}

const hash_signs = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
let hashing_index = 0;
let counter = 0;
let hash_interval = null;
let curren_hash = "";
let hashing_string = make_hashing_string(curren_hash)
function display_hashing(list) {
  const span_hash = document.createElement("span");
  hash.appendChild(span_hash)
  hash_interval = setInterval(() => {
    // span_hash.innerHTML = "<br>" + random_hex_string()
    if (counter % 7 === 0) {
      // span_hash.innerHTML = "<br>" + list[hashing_index]
      curren_hash = list[hashing_index]
      hashing_index++;
    }
    hashing_string = make_hashing_string(curren_hash)
    span_hash.innerHTML = hashing_string
    counter++;
    if (hashing_index >= list.length) {
      hashing_index = 0;
      counter = 0;
      clearInterval(hash_interval);
    }
  }, 30)
}

function reset_display_hashing() {
  counter = 0;
  hashing_index = 0;
  clearInterval(hash_interval)
}

function random_hex_string(num) {
  let result = ''
  for (let i = 0; i < num; i++) {
    const random_idx = Math.floor(Math.random() * hash_signs.length)
    result += hash_signs[random_idx]
  }
  return result
}

function make_hashing_string(str) {
  const len = str.length;
  const num = 32 - len;
  const hex = random_hex_string(num)
  const result = "<br>" + str + hex
  return result;
}

text.addEventListener("keydown", event => {
  if (event.key === "Shift") {
    console.log("shift");
    return
  }
  if (event.key === "Enter" || event.keyCode === 13) {
    event.preventDefault()
    console.log("pressed enter");
    if (text.textContent) {
      console.log(text.textContent);
      socket.emit("msg", text.textContent);
      // input.value = '';
      // add_note();
      highlight_bg();
      reset_display_hashing()
    }
  }
})

const panic = document.querySelector("#panic")
panic.addEventListener("click", () => {
  socket.emit("panic", "Panic")
})

let hash_msgs = []
socket.on("hash", (msg) => {
  console.log(msg);
  // hash.innerHTML += msg + "<br>"
  hash_msgs.push(msg);
});

socket.on("play", (msg) => {
  clearInterval(wait_interval)
  reset_display_hashing()
  console.log(msg);
  let hash_txt = ""
  hash_msgs.forEach(item => {
    hash_txt += item + "<br>"
  })
  hash.innerHTML = hash_txt
  // update_render_text(hash_txt)
});

const composition = document.querySelector(".viz");
let composition_txt = "";

function display_composition_OLD(msg, inline = true, div = 0) {
  const maxLength = 15000;
  // console.log(msg);
  if (inline) {
    composition_txt += msg + "<br>"
  } else {
    composition_txt += msg + " >>>>>>>>>>>> ";
  }
  // console.log(composition_txt.length)
  if (composition_txt.length > maxLength) {
    // console.log("MAX LENGTH REACHED!");
    composition_txt = composition_txt.substring(parseInt(maxLength * 0.25), maxLength);
  }
  composition.innerHTML = composition_txt;
  composition.scrollTop = composition.scrollHeight;
}

socket.on("composition", (msg) => {
  display_composition(msg)
  // const list = JSON.parse(msg);
  // console.log(list);
  // clearInterval(wait_interval)
  // reset_display_hashing()
  // console.log(msg);
  // let hash_txt = ""
  // hash_msgs.forEach(item => {
  //   hash_txt += item + "<br>"
  // })
  // hash.innerHTML = hash_txt
  // update_render_text(hash_txt)
});

const messages = document.querySelector(".messages")
const ch1 = document.querySelector(".ch1")
const ch2 = document.querySelector(".ch2")
const ch3 = document.querySelector(".ch3")
let messages_txt = ""
let ch1_txt = ""
let ch2_txt = ""
let ch3_txt = ""
function display_composition(msg, inline = true, div = 0) {
  const maxLength = 15000;
  // console.log(msg);
  if (inline) {
    messages_txt += msg + "<br>"
  } else {

    switch (div) {
      case 1:
        // console.log("channel:" + div);
        ch1_txt += msg + " >>>>>>>>>>>> ";
        break;
      case 2:
        // console.log("channel:" + div);

        ch2_txt += msg + " >>>>>>>>>>>> ";
        break;
      case 3:
        ch3_txt += msg + " >>>>>>>>>>>> ";
        // console.log("channel:" + div);
        break;

      default:
        break;
    }

    // 
  }
  // console.log(composition_txt.length)
  if (messages_txt.length > maxLength) {
    // console.log("MAX LENGTH REACHED!");
    messages_txt = messages_txt.substring(parseInt(maxLength * 0.25), maxLength);
  }
  messages.innerHTML = messages_txt;
  messages.scrollTop = messages.scrollHeight;

  ch1.innerHTML = ch1_txt;
  ch2.innerHTML = ch2_txt;
  ch3.innerHTML = ch3_txt;
  ch1.scrollTop = ch1.scrollHeight;
  ch2.scrollTop = ch2.scrollHeight;
  ch3.scrollTop = ch3.scrollHeight;
}

socket.on("md5-part", (msg) => {
  console.log(msg);
  wait();
  display_hashing(msg)
  // hash.innerHTML += msg + "<br>"
  // hash_msgs.push(msg);
});


