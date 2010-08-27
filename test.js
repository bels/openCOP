<script language="JavaScript1.2">

document.captureEvents(Event.KEYPRESS);
document.onkeypress=acticate_hot;

function activate_hot(){
	var hotkey=122;
	if(keypress_match(hotkey)){
		alert('MAtched');
	}
}

function keypress_match(keycode){
	var ev;
	if (document.layers){
		ev = e.which;
	} else if (document.all){
		ev = event.keyCode;
	}
	return (ev == keycode);
}



</script>
