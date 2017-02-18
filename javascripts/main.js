$(document).ready(function(){
	var tickets;
	var multiselect = 0;
	var inventory_current;
	if($("#current_object_div").length){
		inventory_current = 1;
	} else {
		inventory_current = 0;
	}

	//to have data when the tab first shows up. this will be replaced when we move to mojolicious but for now here is my stop gap
	$.ajax({
		url: 'server_health.pl',
		method: 'GET'
	}).done(function(data){
		$('#server-health').html(data);
	});
	//get ajax data on tab change
	$('a[data-toggle="tab"]').on('show.bs.tab', function (e) {
		var $target = $(e.target) // activated tab
		var $content_div = $($target.attr("href"));
		$.ajax({
			url: $target.data('url'),
			method: 'GET'
		}).done(function(data){
			$content_div.html(data);
		});
	});
	
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

	function hideMenu(){
		resetLogout();
		$(this).find("ul.subnav").slideUp('fast');
	}
	
	$('.styled_form_element').focusin(function(){
		$(this).addClass('focus');
	});
	
	$('.styled_form_element').focusout(function(){
		$(this).removeClass('focus');
	});
	
	$('.jqgrow').livequery(function(){
		$(this).children('td[title="Normal"]').parent().addClass("normal_priority");
		$(this).children('td[title="Low"]').parent().addClass("low_priority");
		$(this).children('td[title="High"]').parent().addClass("high_priority");
		$(this).children('td[title="Business Critical"]').parent().addClass("critical_priority");
	});
});

function logout(){
	location.href = 'logout.pl';
}

function resetLogout(){
	logoutTimer = window.setTimeout('logout()', '3600000');
	$.ajax({
		type: 'GET',
		url: 'reset_logout.pl'
	});
}
