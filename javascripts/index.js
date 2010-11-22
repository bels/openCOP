$(document).ready(function(){
	var windowWidth = document.documentElement.clientWidth;
	var windowHeight = document.documentElement.clientHeight;
	if($('#low_resolution_warning').length){
		if(windowWidth < 1024 && windowHeight < 768){
			$('#low_resolution_warning').show();
		}
	}
	
	if($.browser.msie)
	{
		alert($.browser.version);
	}
	if($.browser.mozilla)
	{
		alert($.browser.version);
	}
	if($.browser.webkit)
	{
		alert($.browser.version);
	}
	if($.browser.opera)
	{
		alert($.browser.version);
	}
});
