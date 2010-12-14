$(document).ready(function(){
	var tabs;
	var wo_tabs;
	var tickets;
	var multiselect = 0;
	var inventory_current;
	if($("#current_object_div").length){
		inventory_current = 1;
	} else {
		inventory_current = 0;
	}
	if($('#tabs').length){
		tabs = 1;
	} else {
		tabs = 0;
	}
	if($('#wo_tabs').length){
		wo_tabs = 1;
	} else {
		wo_tabs = 0;
	}

	$.ajaxSetup({
		cache: false
	});
	var logoutTimer = window.setTimeout('logout()', '3600000');
	
	$(".customer_link").hover(function(){
		resetLogout();
		$(this).addClass("highlighted_link");
	},function(){
		$(this).removeClass("highlighted_link");
	});
	
	 var config = {
		interval: 150,
		over: showMenu,
		out: hideMenu
	};
	
	if($('ul.subnav').parent().children('span').length){
	} else {
		$("ul.subnav").parent().append("<span></span>"); //Only shows drop down trigger when js is enabled (Adds empty span tag after ul.subnav*)
	}

	$("ul.topnav li").hoverIntent(config);
	
	function showMenu(){
		resetLogout();
		$(this).find("ul.subnav").slideDown('fast').show();
	}

	$('.report_link').bind('click',function(){
		var id = $(this).attr('id');
		var name = $(this).text();
		location.href='display_report.pl?id=' + id + '&name=' + name;
	});
	
	function hideMenu(){
		resetLogout();
		$(this).find("ul.subnav").slideUp('fast');
	}
	if(tabs){
		$("#tabs").tabs().scrollabletab();
	}
	$('table.sort').livequery(function(){
		$(this).tablesorter();
	});
	
	$('.styled_form_element').focusin(function(){
		$(this).addClass('focus');
	});
	
	$('.styled_form_element').focusout(function(){
		$(this).removeClass('focus');
	});
	
	$('#cancel').live('click',function(e){
		e.preventDefault();
		resetLogout();
		$('#ticket_details').fadeOut('fast');
		$('#behind_popup').fadeOut('fast');
	});
});

function logout(){
	location.href = 'logout.pl';
}

function resetLogout(){
	logoutTimer = window.setTimeout('logout()', '3600000');
}
