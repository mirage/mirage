// Need to have a node whose ID is console_window to hold all the consoles
function console_create() {
    var new_console = document.createElement('div');
    var con = document.getElementById("console_window");
    if (con) {
        con.appendChild(new_console);
    } else {
        con = document.createElement('div');
        con.id = "console_1";
    };
    return new_console;
}

function console_write(con, data, off, len) {
    text = data.substring(off, off+len);
    con.innerHTML += "<pre>"+text+"</pre>";
    console.log(con.id + ": " + text);
}
