function add_event (data,id) {
    var json = JSON.parse(data);
    var console = document.getElementById('console');

    var flow = document.getElementById(json.id);
    if (!flow) {
        var flow = document.createElement('div');
        flow.className += 'flow';
        flow.id = json.id;
        console.appendChild(flow);

        var input = document.createElement('input');
        input.type = 'checkbox';
        input.checked = true;
        flow.appendChild(input);

        var text = document.createElement('div');
        text.className += 'id';
        text.innerHTML = 'Connection ' + json.id;
        flow.appendChild(text);
    }

    var event = document.createElement('div');
    event.className += json.level;
    event.id = id;
    flow.appendChild(event);

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