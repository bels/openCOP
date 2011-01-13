$(document).ready(function(){
	$("#start_date").datepicker();
	$("#end_date").datepicker();

	$('#attach_form').submit(function(e){
		e.preventDefault();
		$(this).ajaxSubmit({
			iframe: true
		});
	});

	$('#update_close').live('click',function(){
		resetLogout();
		$('#behind_popup').fadeOut('slow');
		$('#ticket_details').fadeOut('slow');
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
		var $new_file = $(this).parent().append('<input type="file" name="file'+last_num+'" id="file'+last_num+'" num="'+last_num+'"><img src="images/minus.png" class="del_file image_button" alt="Remove">');
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
						location.href = "time_tracking.pl";
				},
				error: function(xml,text,error){
					alert("xml: " + xml.responseText + "\ntext: " + text + "\nerror: " + error);
				}
			});
	});



	$('div#by_tech #display').bind('click',function(){
		resetLogout();
		var uid = $('#user_select').val();
		var mode = "by_tech";
		if(uid){
			var sd = $('#start_date').val();
			var ed = $('#end_date').val();
			var url = 'time_tracking_addon.pl';
			$('#gbox_tech_output').remove();
			$('#by_tech').append('<table id="tech_output"></table><div id="tech_pager"></div>');
		$('#tech_output').jqGrid({
			url: url,
			datatype: 'xml',
			mtype: 'GET',
			colNames: ['Ticket Number','Ticket Status','Last Updated','Time Worked','Ticket Priority','Ticket Contact','Problem','Section'],
			colModel: [
				{name: 'ticket', index: 'ticket', width: 100, sortable: true},
				{name: 'status', index: 'status', width: 150},
				{name: 'updated', index: 'updated', width: 200},
				{name: 'time_worked', index: 'time_worked', width: 150},
				{name: 'priority', index: 'priority', width: 150},
				{name: 'contact', index: 'contact', width: 175},
				{name: 'problem', index: 'problem', width: 200},
				{name: 'section', index: 'section', width: 150}
			],
			pager: "#tech_pager",
			rowNum: 10,
			rowList: [10,20,30],
			sortname: 'ticket',
			sortorder: 'asc',
			viewrecords: true,
			altRows: true,
			gridview: true,
			ignoreCase: true,
			multiKey: 'ctrlKey',
			multiselect: true,
			multiboxonly: true,
			toolbar: [true,'top'],
			postData: {id: uid, sd: sd, ed: ed, mode: mode},
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
		}
	});
	$('td[aria-describedby="tech_output_time_worked"]').livequery(function(){
			var total_time;
			var t5 = ['0','0','0'];
			$('td[aria-describedby="tech_output_time_worked"]').each(function(){
				var t4 = $(this).attr('title').split(':')
				t5[0] = parseInt(t5[0]) + parseInt(t4[0]);
				t5[1] = parseInt(t5[1]) + parseInt(t4[1]);
				t5[2] = parseInt(t5[2]) + parseInt(t4[2]);
			});
			var total_time = t5.join(':');
			$('#total_time').text('Total time worked by tech over period: ' + total_time);
	});

	$('div#by_ticket #display').bind('click',function(){
		resetLogout();
		var search = $('#ticket_search').val();
		var mode = "by_ticket";
		if(search){
			$('#gbox_ticket_output').remove();
			$('#by_ticket').append('<table id="ticket_output"></table><div id="ticket_pager"></div>');
			var url = 'time_tracking_addon.pl';
		$('#ticket_output').jqGrid({
			url: url,
			datatype: 'xml',
			mtype: 'GET',
			colNames: ['Ticket Number','Ticket Status','Last Updated','Time Worked','Ticket Priority','Ticket Contact','Technician','Problem','Section'],
			colModel: [
				{name: 'ticket', index: 'ticket', width: 100, sortable: true},
				{name: 'status', index: 'status', width: 150},
				{name: 'updated', index: 'updated', width: 150},
				{name: 'time_worked', index: 'time_worked', width: 150},
				{name: 'priority', index: 'priority', width: 150},
				{name: 'contact', index: 'contact', width: 175},
				{name: 'technician', index: 'technician', width: 175},
				{name: 'problem', index: 'problem', width: 200},
				{name: 'section', index: 'section', width: 150}
			],
			pager: "#ticket_pager",
			rowNum: 10,
			rowList: [10,20,30],
			sortname: 'ticket',
			sortorder: 'asc',
			viewrecords: true,
			altRows: true,
			gridview: true,
			ignoreCase: true,
			multiKey: 'ctrlKey',
			multiselect: true,
			multiboxonly: true,
			toolbar: [true,'top'],
			postData: {search: search, mode: mode},
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
		}
	});
});
