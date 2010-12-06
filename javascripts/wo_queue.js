$(document).ready(function(){
	$(".wo_link").click(function(){
		resetLogout();
		var wo = $(this).attr("id");
		var url = "wo_ticket_lookup.pl?wo=" + wo;
		$("#right").load(url);
		$('.wo_link.selected').removeClass('selected');
		$(this).addClass('selected');
		$('.wo_summary').livequery(function(){
			$(this).tablesorter();
		});
	});
	$('.disabled').livequery(function(){
		$(this).unbind('click');
	});
	$('.lookup_row').live("mouseover mouseout",function(event){
		if($(this).hashClass('disabled')){
			doNothing();
		}
		if(event.type == 'mouseover'){	
			$(this).addClass('selected');
		} else {
			$(this).removeClass('selected');
		}
	});
	
	$(".lookup_row").live("click",function(){
		resetLogout();
		var ticket_number = $(this).children(".row_ticket_number").text();
		var url = "ticket_details.pl?ticket_number=" + ticket_number;

		$('#behind_popup').css({'opacity':'0.7'}).fadeIn('slow');
		$('#ticket_details').load(url).fadeIn('slow');
		var windowWidth = document.documentElement.clientWidth;
		var windowHeight = document.documentElement.clientHeight;
		var popupHeight = $('#ticket_details').height();
		var popupWidth = $('#ticket_details').width();
		$('#ticket_details').css({
			'position': 'absolute',
			'top': windowHeight/2-popupHeight/2,
			'left': windowWidth/2-popupWidth/2
		});
		$('#behind_popup').css({
			'height': windowHeight
		});
	});
	$('#cancel').live('click',function(e){
		e.preventDefault();
		resetLogout();
		$('#ticket_details').fadeOut();
		$('#behind_popup').fadeOut('slow');
	});
	$('#update_form').livequery(function(){
		$(this).append('<button id="cancel">Cancel</button>')
	});

});

function doNothing(){
	return true;
}

function validateTicket(){
	$('#newticket').validate({
		rules: {
			contact: "required",
			email: {
				email: true,
				required: true
			},
			problem: "required"
		},
		messages: {
			author: {
				required: "*"
			},
			contact: {
				required: "*"
			},
			email: {
				email: "*",
				required: "*"
			},
			problem: {
				required: "* Please enter a description of your problem."
			}
		}
	});
}
