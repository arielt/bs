//=require jquery
//=require less-1.3.3
//=require bootstrap

// ===========================================================================
// Progress state machine
// ===========================================================================
var STATE_NONE      = 0; // No progress bar exposed
var STATE_INIT      = 1; // Empty progress bar exposed - next event 1 second
var STATE_BUSY      = 3; // Busy - making progress till 90%
var STATE_COMPLETED = 4; // We have final answer. Will be processed with delay of 2 seconds

var EVENT_OK    = 0; // verification OK
var EVENT_NOK   = 1; // verification NOK
var EVENT_BUSY  = 2; // verification not finished yet
var EVENT_ERR   = 3; // communication error
var EVENT_NEXT  = 4; // next operation

var byId = function (id) {
  return document.getElementById(id);
};

// ===========================================================================
// response and rendering
// ===========================================================================
var TIME_UP_OK  = "Time is up. The task was successfully completed!";
var TIME_UP_NOK = "Time is up. The task was not completed.";
var SUBMIT_OK   = "You successfully completed the task. Are you sure you want to submit solution and close the session?";
var SUBMIT_NOK  = "The task is not completed. Are you sure you want to submit solution and close the session?";

// verification status
var STATUS_OK   = 0
var STATUS_NOK  = 1
var STATUS_BUSY = 2
var STATUS_NEW  = 3
var STATUS_ERR  = 4

var viewData = {};

function setSolution() {
  editor.setValue(viewData['solution']);
  editor.clearSelection();
  editor.gotoLine(1);
}

function setIssues() {
  if (viewData['issues'] == undefined) 
    return;

  var node = document.getElementById('issues-div');

  while (node.childElementCount > 0) {
    node.removeChild(node.lastChild);
  }

  var arrayLength = viewData['issues'].length;

  for (var i = 0, tr, td; i < arrayLength; i++) {
    var newdiv = document.createElement('div');
    var divIdName = 'my' + i + 'Div';
    newdiv.setAttribute('id',divIdName);
    newdiv.setAttribute('class', 'issue');
    newdiv.innerHTML = viewData['issues'][i]['data'];
    node.appendChild(newdiv);
  }

  // display issues counter
  if (arrayLength > 0) {
    document.getElementById('issues-counter').style.display = 'block';
    document.getElementById('issues-counter').innerHTML = arrayLength;
  } else {
    document.getElementById('issues-counter').style.display = 'none';
  }
}

function setStatus() {
  switch(viewData['status']) {
    case STATUS_OK:
      byId('status_p').className   = 'succeed';
      byId('status_p').innerHTML   = 'PASSED';
      byId('time-msg').innerHTML   = TIME_UP_OK;
      byId('submit-msg').innerHTML = SUBMIT_OK;
      byId('btn-submit').disabled  = false;
      byId('btn-submit').className = 'submit button';
      break;
    case STATUS_NOK:
      byId('status_p').className   = 'failed';
      byId('status_p').innerHTML   = 'FAILED';
      byId('time-msg').innerHTML   = TIME_UP_NOK;
      byId('submit-msg').innerHTML = SUBMIT_NOK;      
      byId('btn-submit').disabled  = true;
      byId('btn-submit').className = 'submit button disabled';
      break;
    case STATUS_NEW:
      byId('status_p').className   = 'succeed';
      byId('status_p').innerHTML   = 'NEW';
      byId('time-msg').innerHTML   = TIME_UP_NOK;
      byId('submit-msg').innerHTML = SUBMIT_NOK;    
      byId('btn-submit').disabled  = true;
      byId('btn-submit').className = 'submit button disabled';
      break;
    case STATUS_ERR:
      byId('status_p').className   = 'failed';
      byId('status_p').innerHTML   = 'ERR';
      byId('time-msg').innerHTML   = TIME_UP_NOK;
      byId('submit-msg').innerHTML = SUBMIT_NOK;   
      byId('btn-submit').disabled  = true;
      byId('btn-submit').className = 'submit button disabled';
      break;
  }
}

function showProgressBar(value)
{
  if (value) {
    document.getElementById('pgb-verify').style.display = 'block';
    document.getElementById('pg-verify').style.display  = 'block';
  } else {
    document.getElementById('pgb-verify').style.display = 'none';
    document.getElementById('pg-verify').style.display  = 'none'; 
  }
}

function showStatus(value)
{
  if (value) {
    document.getElementById('tb-status').style.display  = 'block';
    document.getElementById('tb-divider').style.display = 'block';
    document.getElementById('tb-timer').style.display   = 'block';
  } else {
    document.getElementById('tb-status').style.display  = 'none';
    document.getElementById('tb-divider').style.display = 'none';
    document.getElementById('tb-timer').style.display   = 'none';
  }
}

function renderAll()
{
  showProgressBar(false);
  setStatus();
  setSolution();
  setIssues();
  showStatus(true);
}

// ===========================================================================
// progress bar rendering
// ===========================================================================
function renderNextState(e) {
  e = ((e != null) ? e : EVENT_NEXT);
  //console.log("Next state call " + e + ":" + (new Date().getSeconds()));

  if (rendering_state == STATE_INIT) {
    //console.log("Init " + (new Date().getSeconds()));
    byId('btn-verify').disabled  = true;
    byId('btn-verify').className = 'verify button disabled';
    showStatus(false);
    showProgressBar(true);
    byId('pgb-verify').style.width='0%';
    rendering_state = STATE_BUSY;
    rendering_timer = setTimeout(renderNextState, 100);
    verification_timer = setTimeout(verification_callback, 100);
    return;
  }

  if (e < EVENT_BUSY || e == EVENT_ERR) {
    //console.log("We have answer " + (new Date().getSeconds()));
    clearInterval(verification_timer);
    clearTimeout(rendering_timer);
    verification_status = e;
    document.getElementById('pgb-verify').style.width = '100%';
    rendering_state = STATE_COMPLETED;
    rendering_Timer = setTimeout(renderNextState, 1500);
    return;
  }

  if (rendering_state == STATE_BUSY) {
    //console.log("Still busy " + (new Date().getSeconds()));
    var pgb = document.getElementById('pgb-verify');
    var width = parseInt(pgb.style.width);
    if (width < 90) {
      width += 1;
    }
    pgb.style.width = width + '%';
    rendering_timer = setTimeout(renderNextState, 100);
    return;
  }

  if (rendering_state == STATE_COMPLETED) {
    //console.log("Completed " + (new Date().getSeconds())); 
    renderAll();
    byId('btn-verify').disabled = false;
    byId('btn-verify').className = 'verify button'; 
    rendering_state = STATE_NONE;
    return;
  }
}

function verification_callback()
{
  //console.log("Verification call " + (new Date().getSeconds()));
  $.ajax({
    url: "/active_sessions",
    type: "POST",
    // fix for devise not having current user with Ajax POST
    beforeSend: function(jqXHR, settings) {
        jqXHR.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
    },
    data: {
      "id":         window.TOKEN, 
      "check":      window.editor.getSession().getValue(),
      "active_tab": $('#tabs li.active').index()
    },
    timeout: 4000,
    success: function(response) {
      viewData = response;
      if (response.status == EVENT_BUSY) {
        verification_timer = setTimeout(verification_callback, 2000);
      } 
      clearTimeout(rendering_timer);
      rendering_timer = setTimeout(renderNextState, 100, response.status);
    },
    error: function(x, t, m) {
      rendering_timer = setTimeout(renderNextState, 100, EVENT_ERR);
    }
  });
}

function resize_editor() {
  var e = document.getElementById('editor');
  e.style.width = ($('#solution').width() - 2) + "px";
}

$(window).resize(function() {
   resize_editor();
});

function activate_tabs()
{
  // show default tab
  $('#tabs a[href="#objectives"]').tab('show');

  // set tab click action
  $('#tabs a').click(function (e) {
    e.preventDefault();
    $(this).tab('show');
  });

  // on shown, update active tab index
  $('#tabs a').on('shown', function () {
    active_tab = $('#tabs li.active').index();
    //$.post("/active_sessions", {id: window.session_id, update: {"active_tab": index}});
    // solution tab index is 1
    switch(active_tab) {
      case 1:
        // solution tab
        resize_editor();
        editor.focus();
        break;
      case 2:
        // issues tab
        //rebuild_issues_table();
        break;
    }
  })
}

// countdown timer callback
function countdown_callback() {
  countdown_value -= 1;

  if (countdown_value < 0)
  {
    clearInterval(countdown_timer);
    $('#time-window').modal('show');
    return;
  }

  // update the countdown
  var days=Math.floor(countdown_value / 86400); 
  var hours = Math.floor((countdown_value - (days * 86400 ))/3600);
  var minutes = Math.floor((countdown_value - (days * 86400 ) - (hours *3600 ))/60);
  //var secs = Math.floor((count - (days * 86400 ) - (hours *3600 ) - (minutes*60)));
  var text;
  if (days == 1) {
    text = days + " days " + hours + " hours";
  } else if (days > 1) {
    text = days + " days";
  } else if (countdown_value < 60) {
    text = countdown_value + " seconds";
  } else if (hours < 1) {
    text = minutes + " minutes";
  } else {
    text = hours + " hours " + minutes + " minutes";
  }
  text += " left";
  document.getElementById('ct').innerHTML = text;
}


// ===========================================================================
// close session, redirect to home
// ===========================================================================
function submit_solution() {
  $.ajax({
    url: "/active_sessions",
    type: "POST",
    // fix for devise not having current user with Ajax POST
    beforeSend: function(jqXHR, settings) {
        jqXHR.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
    },
    data: {
      "id":         window.TOKEN, 
      "submit":     "TRUE",
    },
    timeout: 4000,
    success: function(response) {
       window.location="/";
    },
    error: function(x, t, m) {
    }
  });
}

