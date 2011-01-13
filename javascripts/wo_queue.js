$(document).ready(function(){
	$("#update_button").live('click',function(e){
		e.preventDefault();
		resetLogout();
			var url = "update_ticket.pl";
			var the_data = $("#update_form").serialize();
			$.ajax({
				type: 'POST',
				url: url,
				data: the_data,
				success: function(data){
						if($('#attach_form input[type="file"]').val() !== ""){
							$('#attach_form').append('<input type="hidden" name="utkid" id="utkid" value="' + $("#ticket_number").text() + '">');
							$('#attach_form').submit();
						}
						window.location = "wo_queue.pl";
				},
				error: function(xml,text,error){
					alert("xml: " + xml.responseText + "\ntext: " + text + "\nerror: " + error);
				}
			});
	});

	$('#update_close').live('click',function(){
		resetLogout();
		$('#behind_popup').fadeOut('slow');
		$('#ticket_details').fadeOut('slow');
	});

	$('#attach_form').submit(function(e){
		e.preventDefault();
		$(this).ajaxSubmit({
			iframe: true
		});
	});

	$('#attach').live('click',function(){
		$(document).unbind('keydown.escTicket');
		$(document).bind('keydown.escAttach',function(e){
			if(e.keyCode == 27){
				$(document).bind('keydown.escTicket',function(e){
					if(e.keyCode == 27){
						resetLogout();
						$('#behind_popup').fadeOut('slow');
						$('#ticket_details').fadeOut('slow');
						$(this).unbind(e);
						$(document).unbind('keydown.escAttach');
					}
				});
			}
		});
	});

	$('#attach').livequery(function(){
		var triggers = $('#attach').overlay({
			mask: {
				loadSpeed: 200,
				opacity: 0.6
			}
		});
	});

	$('.add_file').live('click',function(e){
		e.preventDefault();
		var $this = $(this);
		var last_num = parseInt($(this).prevAll('input').attr('num'));
		last_num++;
		var $new_file = $(this).parent().append('<input type="file" name="file'+last_num+'" id="file'+last_num+'" num="'+last_num+'"><button class="del_file">-</button>');
		$new_file.append($this);
		$(this).parent().children('button.close').appendTo($new_file);
	});

	$('.del_file').live('click',function(e){
		e.preventDefault();
		$(this).prev('input').remove();
		$(this).prev('br').remove();
		$(this).remove();
	});

	$('.close').live('click',function(e){
		e.preventDefault();
		var files = "";
		$('#attach_form input[type="file"]').each(function(){
			files += $(this).val() + "<br>";
		});
		$('#attach_div').html('<div rel="#multiAttach" id="attach"><label>Attach a File</label><img title="Attach A File" src="images/attach.png"></div>' + files);
		var triggers = $('#attach').overlay({
			mask: {
				loadSpeed: 200,
				opacity: 0.6
			}
		});
	});

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
					$(document).bind('keydown.escTicket',function(e){
						if(e.keyCode == 27){
							resetLogout();
							$('#behind_popup').fadeOut('slow');
							$('#ticket_details').fadeOut('slow');
							$(this).unbind(e);
						}
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
