// index -> connection
var index = [];

// connection -> log events table
var events = [];

uki({
    view: 'HSplitPane',
    rect: '0 0 1200 1000',
    anchors: 'left top right bottom',
    handlePosition: 200,
    leftMin: 200,
    rightMin: 300,

    leftChildViews: {
        view: 'List',
        id: 'left',
        rect: '0 0 200 1000',
        anchors: 'left top',
        data: [],
        textSelectable: false },

    rightChildViews: {
        view: 'Table',
        id : 'right',
        rect: '0 0 1000 1000',
        anchors: 'left top',
        columns: [
            { view: 'table.CustomColumn', label: 'Date', resizable: true, width: 150, sort: 'ASC' },
            { view: 'table.CustomColumn', label: 'Level', resizable: true, width: 50 },
            { view: 'table.CustomColumn', label: 'Section', resizable: true, width: 200 },
            { view: 'table.CustomColumn', label: 'Message', resizable: true, width: 600 } ],
        style: {fontSize: '11px', lineHeight: '11px'},
        textSelectable: false,
        data: [] },

}).attachTo( window, '1000 1000' );

// click on header should order the table
uki('#right').find('Header').bind('columnClick', function(e) {
    var header = this;

    if (e.column.sort() == 'ASC')
        e.column.sort('DESC');
    else
        e.column.sort('ASC');

    header.redrawColumn(e.columnIndex);
    uki.each(header.columns(), function(i, col) {
        if (col != e.column && col.sort()) {
            col.sort('');
            header.redrawColumn(i);
        }
    });
    uki('#right').data(e.column.sortData(uki('#right').data()));
})


function update_right(i) {
    uki('#right').data(events[index[i]]);
}

// click on the left column should update the right panel
uki('#left').bind('click', function () { update_right(this.lastClickIndex()); });

function update_left() {
    var cons = [];
    for (var c in events)
        cons.push('Connection '+ c);
    uki('#left').data(cons);
}

function add_event (data) {
    var json = JSON.parse(data);
    raw_data = [ json.date, json.level, json.section, json.message ];
    if (events[json.id] == undefined) {
        index.push(json.id);
        events[json.id] = [raw_data];
    } else {
        events[json.id].push(raw_data);
    };
    update_left();
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