$(document).ready(function(){
	var tabs;
	var tickets;
	if($('#tabs').length){
		tabs = 1;
	} else {
		tabs = 0;
	}
	if($('.ticket_lookup').length){
		tickets = 1;
	} else {
		tickets = 0;
	}
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
		if(tabs){
			$("#tabs").addClass("lower");
		}
		if(tickets){
			$(".jspContainer").addClass("lower");
		}
		$(this).find("ul.subnav").slideDown('fast').show();
	}
	
	function hideMenu(){
		$(this).find("ul.subnav").slideUp('fast',function(){
			$(".jspContainer").removeClass("lower");
			$("#tabs").removeClass("lower");
		});
	}
	if(tabs){
		$("#tabs").tabs();
	}
});

function logout(){
	$.cookie("session", null, { path: '/' });
	location.href = 'logout.pl';
}
