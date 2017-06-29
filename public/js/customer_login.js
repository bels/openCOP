$(document).ready(function(){
	var windowWidth = document.documentElement.clientWidth;
	var windowHeight = document.documentElement.clientHeight;
	if($('#low_resolution_warning').length){
		if(windowWidth < 1024 && windowHeight < 768){
			$('#low_resolution_warning').show();
		}
	}
});
