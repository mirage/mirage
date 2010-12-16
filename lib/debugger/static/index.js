function add_event (date) {
    var json = JSON.parse(data);
    var console = document.getElementById('console');

    var event = document.createElement('div');
    event.class = json.level;
    console.appendChild(event);

    var date = document.createElement('div');
    date.class = 'date';
    date.innerHTML = json.date;
    event.appendChild(date);

    var content = document.createElement('div');
    message.class = 'message';
    message.innerHTML = json.message;
    event.appendChild(message);
}

document.addEventListener('DOMContentLoaded', function () {
    var eventSrc = new EventSource('/events');
  
    eventSrc.addEventListener('open', function (event) {
        console.log(event.type);
    });
  
    eventSrc.addEventListener('message', function (event) {
        console.log(event.type);
        add_event(event.data);
    });

}, false);