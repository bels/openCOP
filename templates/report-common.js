   function show_another(){
	if(typeof(window['shown']) != "undefined"){
		for(var i = 0;i <= shown && i < number_of_fields;i++){
			if(i != 0){
				showLAYER('and'+(i - 1));
				changePon('and'+(i - 1));
			}
			changePon('invis'+i);
			showLAYER('invis'+i);

		}
		shown++;
	}
	if(typeof(window['s_shown']) != "undefined"){
		for(var i = 0;i <= s_shown && i < number_of_fields;i++){
			if(i != 0){
				showLAYER('then'+(i - 1));
				changePon('then'+(i - 1));
			}
			changePon('sortinvis'+i);
			showLAYER('sortinvis'+i);
		}
		s_shown++;
	}
	if(shown && s_shown && shown >= number_of_fields && s_shown >= number_of_fields){
		changePoff('morebutton');
		hideLAYER('morebutton');
	}
   }

// Suit of LAYER functions. 'show' and 'hide' copied from a Mozilla example.
function changePon(layName){
        if(document.getElementById){
                document.getElementById(layName).style.position='static';
        }
        else if(document.layers){ document.layers[layName].position=='static'; }
        else if(document.all){ document.all(layName).style.position=='static'; }
}
function changePoff(layName){
        if(document.getElementById){
                document.getElementById(layName).style.position='absolute';
        }
        else if(document.layers){ document.layers[layName].position=='absolute'; }
        else if(document.all){ document.all(layName).style.position=='absolute'; }
}
function reportP(layName){
	var v;
        if(document.getElementById){
                v = document.getElementById(layName).style.position='absolute';
        }
        else if(document.layers){ v = document.layers[layName].position=='absolute'; }
        else if(document.all){ v = document.all(layName).style.position=='absolute'; }
	return v;
}

function showLAYER(layName){
        if(document.getElementById){
                document.getElementById(layName).style.visibility='visible';
        }
        else if(document.layers){ document.layers[layName].visibility='show'; }
        else if(document.all){ document.all(layName).style.visibility='visible'; }
}
function hideLAYER(layName){
        if(document.getElementById){
                document.getElementById(layName).style.visibility='hidden';
        }
        else if(document.layers){ document.layers[layName].visibility='hide'; }
        else if(document.all){ document.all(layName).style.visibility='hidden'; }
}
function reportLAYER(layName){
        var result;
        if(document.getElementById){
                result = document.getElementById(layName).style.visibility; }
        else if(document.layers){ result = document.layers[layName].visibility; }
        else if(document.all){ result = document.all(layName).style.visibility; }
        if(result == "show"){ result = "visible"; }
        if(result == "hide"){ result = "hidden"; }
        return result;
}
function toggleLAYER(layName){
        if(reportLAYER(layName) == "hidden"){ showLAYER(layName); }
        else{ hideLAYER(layName); }
}
