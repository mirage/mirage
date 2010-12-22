// index -> connection table
var connection = [];

// connection -> index table
var index =[];

// index -> log events table
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
    if (e.column.sort() == 'ASC')
        e.column.sort('DESC');
    else
        e.column.sort('ASC');

    this.redrawColumn(e.columnIndex);
    uki.each(this.columns(), function(i, col) {
        if (col != e.column && col.sort()) {
            col.sort('');
            this.redrawColumn(i);
        }
    });
    uki('#right').date(e.column.sortData(uki('#right').data()));
})


function update_right(index) {
    uki('#right').data(events[index]);
}

// click on the left column should update the right panel
uki('#left').bind('click', function () { update_right(this.lastClickIndex()); });

function update_left() {
    var cons = [];
    for (var c in connection)
        cons.push('Connection '+ connection[c]);
    uki('#left').data(cons);
}

function add_event (data,con) {
    console.log("add_event: con="+con+" index="+index+" connection="+connection);
    var json = JSON.parse(data);
    raw_data = [ json.date, json.level, json.section, json.message ];
    if (index[con] == undefined) {
        var id = connection.push(con);
        events.push([raw_data]);
        index[con] = id;
    } else {
        events[index[con]].push(raw_data);
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
        add_event(event.data, event.lastEventId);
    });

}, false);