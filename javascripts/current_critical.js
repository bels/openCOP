$(document).ready(function(){
	$('.lookup_row').live("mouseover mouseout",function(event){
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
		var windowWidth = window.innerWidth;
		var windowHeight = window.innerHeight;
		var popupHeight = $('#ticket_details').height();
		var popupWidth = $('#ticket_details').width();
		$('#ticket_details').css({
			'position': 'absolute',
			'top': 0,
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
