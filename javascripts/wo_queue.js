$(document).ready(function(){
	$(".wo_link").click(function(){
		resetLogout();
		var wo = $(this).attr("id");
		var url = "wo_ticket_lookup.pl?wo=" + wo;
		$('.wo_link.selected').removeClass('selected');
		$(this).addClass('selected');
			$('#right').jqGrid({
				url: url,
				datatype: 'xml',
				mtype: 'GET',
				colNames: ['Step Number','Ticket Number','Ticket Status','Ticket Priority','Assigned Technician','Problem','Section'],
				colModel: [
					{name: 'step', index: 'step', width: 100, sortable: true},
					{name: 'ticket', index: 'ticket', width: 100, sortable: true},
					{name: 'status', index: 'status', width: 100, sortable: true},
					{name: 'priority', index: 'priority', width: 100, sortable: true},
					{name: 'technician', index: 'technician', width: 125, sortable: true},
					{name: 'problem', index: 'problem', width: 200, sortable: true},
					{name: 'name', index: 'name', width: 100, sortable: true}
				],
				pager: "#pager",
				rowNum: 10,
				rowList: [10,20,30],
				sortname: 'step',
				sortorder: 'asc',
				viewrecords: true,
				altRows: true,
				gridview: true,
				ignoreCase: true,
				multiKey: 'ctrlKey',
				multiselect: true,
				multiboxonly: true,
				toolbar: [true,'top'],
				ondblClickRow: function(rowid){
					resetLogout();
					var ticket_number = rowid;
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
				}
			});
	});
	$('.disabled').livequery(function(){
		$(this).unbind('click');
	});
	$('.lookup_row').live("mouseover mouseout",function(event){
		if($(this).hasClass('disabled')){
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
