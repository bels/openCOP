$(document).ready(function(){
	var tabs;
	var wo_tabs;
	var tickets;
	var user_admin_page;
	var group_admin_page;
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
	if($('#associate_user_group_div').length){
		user_admin_page = 1;
	} else {
		user_admin_page = 0;
	}
	if($('#associate_group_user_div').length){
		group_admin_page = 1;
	} else {
		group_admin_page = 0;
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
		if(tabs){
			$("#tabs").addClass("lower");
		}
		if(wo_tabs){
			$("#wo_tabs").addClass("lower");
		}
		if(jspC){
			$(".jspContainer").addClass("lower");
		}
		if(user_admin_page){
			$("#associate_user_group_div").addClass("lower");
			$("#a_ug_append_div").addClass("lower");
			$(".ui-multiselect").addClass("lower");
			$(".selected").addClass("lower");
			$(".available").addClass("lower");
		}
		if(group_admin_page){
			$("#associate_group_user_div").addClass("lower");
			$("#a_gu_append_div").addClass("lower");
			$(".ui-multiselect").addClass("lower");
			$(".selected").addClass("lower");
			$(".available").addClass("lower");
		}
		if(inventory_current){

			$(".jspContainer").addClass("lower");
		}
		$(this).find("ul.subnav").slideDown('fast').show();
	}
	
	function hideMenu(){
		resetLogout();
		$(this).find("ul.subnav").slideUp('fast',function(){
			if(tickets){
				$(".jspContainer").removeClass("lower");
			}
			if(user_admin_page){
				$("#associate_user_group_div").removeClass("lower");
				$("#a_ug_append_div").removeClass("lower");
				$(".ui-multiselect").removeClass("lower");
				$(".selected").removeClass("lower");
				$(".available").removeClass("lower");
			}
			if(group_admin_page){
				$("#associate_group_user_div").removeClass("lower");
				$("#a_gu_append_div").removeClass("lower");
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
});

function logout(){
	$.cookie("session", null, { path: '/' });
	location.href = 'logout.pl';
}

function resetLogout(){
	logoutTimer = window.setTimeout('logout()', '3600000');
}
