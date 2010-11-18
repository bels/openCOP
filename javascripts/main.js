$(document).ready(function(){
	$.ajaxSetup({
		cache: false
	});
	var logoutTimer = window.setTimeout('logout()', '3600000');
	
	$(".customer_link").hover(function(){
		$(this).addClass("highlighted_link");
	},function(){
		$(this).removeClass("highlighted_link");
	});
	
	 var config = {
		interval: 150,
		over: showMenu,
		out: hideMenu
	};
	
	$("ul.subnav").parent().append("<span></span>"); //Only shows drop down trigger when js is enabled (Adds empty span tag after ul.subnav*)

	$("ul.topnav li").hoverIntent(config);
	
	function showMenu(){
		$("#tabs").addClass("lower");
		$(this).find("ul.subnav").slideDown('fast').show();
	}
	
	function hideMenu(){
		$(this).find("ul.subnav").slideUp('fast',function(){$("#tabs").removeClass("lower");});
	}
	
	$("#tabs").tabs();
});

function logout(){
	$.cookie("session", null, { path: '/' });
	location.href = 'logout.pl';
}
