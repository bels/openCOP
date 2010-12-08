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
	if($('.jspContainer').length){
		jspC = 1;
	} else {
		jspC = 0;
	}
	$('.jspContainer').livequery(function(){
		jspC = 1;
	});
	$('.multiselect').livequery(function(){
		multiselect = 1;
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
		if(tabs){
			$("#tabs").addClass("lower");
		}
		if(wo_tabs){
			$("#wo_tabs").addClass("lower");
		}
		if(jspC){
			$(".jspContainer").addClass("lower");
		}
		if(multiselect){
			$("#associate_user_group_div").addClass("lower");
			$("#a_ug_append_div").addClass("lower");
			$(".ui-multiselect").addClass("lower");
			$(".selected").addClass("lower");
			$(".available").addClass("lower");
		}
		if(inventory_current){

			$(".jspContainer").addClass("lower");
		}
		$(this).find("ul.subnav").slideDown('fast').show();
	}

	$('.report_link').bind('click',function(){
		var id = $(this).attr('id');
		var name = $(this).text();
		location.href='display_report.pl?id=' + id + '&name=' + name;
	});
	
	function hideMenu(){
		resetLogout();
		$(this).find("ul.subnav").slideUp('fast',function(){
			if(tickets){
				$(".jspContainer").removeClass("lower");
			}
			if(multiselect){
				$("#associate_user_group_div").removeClass("lower");
				$("#a_ug_append_div").removeClass("lower");
				$(".ui-multiselect").removeClass("lower");
				$(".selected").removeClass("lower");
				$(".available").removeClass("lower");
			}
			if(inventory_current){
				$(".jspContainer").removeClass("lower");
			}
			$("#tabs").removeClass("lower");
			$("#wo_tabs").removeClass("lower");
		});
	}
	if(tabs){
		$("#tabs").tabs();
	}
	$('table').livequery(function(){
		$(this).tablesorter();
	});
});

function logout(){
	location.href = 'logout.pl';
}

function resetLogout(){
	logoutTimer = window.setTimeout('logout()', '3600000');
}
