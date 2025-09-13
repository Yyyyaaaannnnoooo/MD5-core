// from https://gistlib.com/javascript/map-pitch-to-note-in-javascript
function midi_to_note(midiNote) {
  const noteMapping = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];
  const octave = Math.floor(midiNote / 12) - 1;
  const noteIndex = midiNote % 12;
  
  return noteMapping[noteIndex] + octave.toString();
}

// below here mostly AI generated
document.addEventListener('DOMContentLoaded', function () {
  const statusElement = document.getElementById('status');
  const requestButton = document.getElementById('requestButton');
  const midiInfo = document.getElementById('midiInfo');
  const devicesList = document.getElementById('devicesList');
  const midiMessages = document.getElementById('midiMessages');

  let midiAccess = null;

  // Check if Web MIDI API is available
  if (!navigator.requestMIDIAccess) {
    statusElement.textContent = "Web MIDI API is not supported in this browser";
    requestButton.disabled = true;
    return;
  }

  requestButton.addEventListener('click', function () {
    requestButton.disabled = true;
    statusElement.textContent = "Requesting MIDI access...";

    navigator.requestMIDIAccess()
      .then(function (access) {
        midiAccess = access;
        statusElement.textContent = "MIDI access granted!";
        statusElement.className = "status connected";
        midiInfo.style.display = "block";

        // List connected devices
        updateDevicesList();

        // Setup event listeners for connected devices
        setupMidiInputs();

        // Listen for device changes
        midiAccess.onstatechange = function (e) {
          updateDevicesList();
          setupMidiInputs(); // Re-setup inputs when devices change
        };
      })
      .catch(function (error) {
        statusElement.textContent = "Failed to get MIDI access: " + error;
        statusElement.className = "status disconnected";
        requestButton.disabled = false;
      });
  });

  function updateDevicesList() {
    devicesList.innerHTML = '';

    const inputs = midiAccess.inputs.values();
    for (let input = inputs.next(); input && !input.done; input = inputs.next()) {
      const device = input.value;
      const li = document.createElement('li');
      li.textContent = `${device.name} (${device.manufacturer})`;
      devicesList.appendChild(li);
    }

    if (devicesList.children.length === 0) {
      const li = document.createElement('li');
      li.textContent = "No MIDI devices found";
      devicesList.appendChild(li);
    }
  }

  function setupMidiInputs() {
    // Clear previous listeners by removing all onmidimessage handlers
    const inputs = midiAccess.inputs.values();
    for (let input = inputs.next(); input && !input.done; input = inputs.next()) {
      input.value.onmidimessage = null;
    }

    // Add new listeners
    const newInputs = midiAccess.inputs.values();
    for (let input = newInputs.next(); input && !input.done; input = newInputs.next()) {
      input.value.onmidimessage = handleMidiMessage;
    }
  }

  function handleMidiMessage(message) {
    const data = message.data;
    const timestamp = message.timeStamp;

    let messageText = '';

    // Parse MIDI message
    let root = 0
    let note_color = "#7f7" 
    let prepend = "////////////" 
    const command = data[0] >> 4;
    const channel = data[0] & 0x0f;
    if(channel === 1){root = 12; note_color = "#7fa"; prepend = ">>>>>>>>>>>>"}
    if(channel === 2){root = -24; note_color = "#afa"; prepend = "************"}
    const note = data[1] + root;
    const velocity = data[2];

    if (command === 0x09 && velocity > 0) {
      // Note on
      messageText = `<span style="color: ${note_color}">Note On: Channel ${channel + 1}, Note ${midi_to_note(note)}, Velocity ${velocity}</span>`;

      display_composition(messageText, false)
      
    } else if (command === 0x08 || (command === 0x09 && velocity === 0)) {
      // Note off
      messageText = `<span style="color: ${note_color}">Note Off: Channel ${channel + 1}, Note ${midi_to_note(note)}</span>`;
      display_composition(messageText, false)
    } else if (command === 0x0B) {
      // Control change
      messageText = `Control Change: Channel ${channel + 1}, Controller ${note}, Value ${velocity}`;
    } else {
      // Other message types
      messageText = `Message: [${data[0]}, ${data[1]}, ${data[2]}]`;
    }

    // // Add to message log
    // if (midiMessages.querySelector('p')) {
    //   midiMessages.innerHTML = '';
    // }

    // const messageElement = document.createElement('div');
    // messageElement.className = 'message';

    // if (command === 0x09 && velocity > 0) {
    //   messageElement.innerHTML = `<span class="note">${messageText}</span>`;
    // } else if (command === 0x0B) {
    //   messageElement.innerHTML = `<span class="control">${messageText}</span>`;
    // } else {
    //   messageElement.textContent = messageText;
    // }

    // midiMessages.prepend(messageElement);
  }
});