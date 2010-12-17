function add_event (data,id) {
    var json = JSON.parse(data);
    var console = document.getElementById('console');

    var event = document.createElement('div');
    event.className += json.level;
    event.id = id;
    console.appendChild(event);

    var date = document.createElement('div');
    date.className += 'date';
    date.innerHTML = json.date;
    event.appendChild(date);

    var section = document.createElement('div');
    section.className += 'section';
    section.innerHTML = json.section;
    event.appendChild(section);

    var message = document.createElement('div');
    message.className += 'message';
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
        add_event(event.data, event.lastEventId);
    });

}, false);