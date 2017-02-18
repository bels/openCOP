$(document).ready(function(){
	var windowWidth = document.documentElement.clientWidth;
	var windowHeight = document.documentElement.clientHeight;
	if($('#low_resolution_warning').length){
		if(windowWidth < 1024 && windowHeight < 768){
			$('#low_resolution_warning').show();
		}
	}
	
	/*if($.browser.msie)
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
	}*/
	/*if(!$.support.boxModel || !$.support.opacity){
		alert("Your browser is not current with its standards compliance.  There are parts of this application that will not look/operate correctly.  Please upgrade to a compliant browser (Firefox 3.5+, Safari 3+, Opera 10+, IE9).");
	}*/
});
