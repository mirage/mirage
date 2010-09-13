// Need to have a node whose ID is console_window to hold all the consoles

var nb_console = 0;

function console_create(con_id) {
		nb_console++;
    var new_console = document.createElement('div');
		new_console.id = "console_"+nb_console;
    var con = document.getElementById("console_window");
    if (con) con.appendChild(new_console);
    return new_console;
}

function console_write(con, data, off, len) {
    if (typeof data == "object")
      data = data.toString();
    text = data.substring(off, off+len);
    con.innerHTML += "<pre>"+text+"</pre>";
    if (window.console) console.log(con.id + ": " + text);
}
