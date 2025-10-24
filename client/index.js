const socket = io("http://localhost:3000");
socket.emit("panic", "Panic");
let sentence_num = 0;
let char_num = 0;
let sentence_done = false;
const story = [
  'this is a pico live coding environment',
  'it is based on the md5 hashing algorithm',
  'it can take a text of any length and turn it into a 128-bit string. or 32 hex digits.',
  'The hash is than turned into a score, that we are hearing.',
  'Now that we established that any text can become a variation of a requiem; what is the purpose of this live coding environment?',
  'I can use Live Coding to tell a story.',
  'And the words of this story will compose its own soundtrack',
  'md5 as an algorithm was "retired" in 2010, as it was not meeting the security standards for criptography',
  '...for long it encrypted, yet, its collision resistance was broken, and therefore unusable for cryptographic purposes',
  '....and so this piece is to say goodbye. A farewell for md5',
  'Ciao md5, we had adventurous and troubling times. And between that flowers resiliently grew up!',
  'Ciao md5, your hashes never met the ocean, yet your name bestows a library.',
  'stifle seagulls still flap their wings',
  'curled laughter',
  'Your name on that rock!'
]

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
  // console.log(event.key);
  // console.log(event.keyCode);
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
      if (sentence_done) {
        sentence_num++
        char_num = 0;
        sentence_done = false
      }
      // input.value = '';
      // add_note();
      highlight_bg();
      reset_display_hashing()
    }
  } else if (event.key !== "Backspace" || event.keyCode !== 8) {
    event.preventDefault();
    type_story()
  }
})

function type_story() {
  const curr_sentence = story[sentence_num]
  const len = curr_sentence.length
  const curr_chars = curr_sentence.slice(0, char_num + 1)
  // console.log(curr_chars);
  text.textContent = curr_chars
  char_num++
  if (char_num >= len) {
    sentence_done = true
  }

}

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


