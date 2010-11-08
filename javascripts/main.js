$(document).ready(function(){
	var logoutTimer = window.setTimeout('logout()', '3600000');
	var config = {
		interval: 120,
		over: hideMenus,
		out: doNothing
	};

	$('.menu_link').each(function(){
		$(this).hoverIntent(config);
	});
	
	$(".sub_link").hover(function(){
		$(this).addClass("highlighted_link");
	},function(){
		$(this).removeClass("highlighted_link");
	});
	
	$(".customer_link").hover(function(){
		$(this).addClass("highlighted_link");
	},function(){
		$(this).removeClass("highlighted_link");
	});
});

function hideMenus(){
		var sublink = $(this).attr("id");
		$('.sub').each(function(){
			$(this).addClass("hidden_menu");
		});
		$('#sub_' + sublink).removeClass("hidden_menu");	
}

function doNothing(){
	return true;
}

function logout(){
	$.cookie("session", null, { path: '/' });
	location.href = 'logout.pl';
}
