// Need to have a node whose ID is console
function console_create() {
		var new_console = dom.createElement('div');
		var console = dom.getElementById("console");
		if (console) {
				console.appendChild(new_console);
		} else {
				console = dom.createElement('div');
				console.id = "console";
		};
		return new_console;
}

function console_write(console, data, off, len) {
		text = data.substring(off, off+len);
		text.replace(/\n/gi, "<br/>\n");
		console.innerHTML += text;
}
		
		