$(document).ready(function(){
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

	if($('#free_date').length){
		$('#free_date').datepicker();
		$('.free_time').timepicker({
			hourGrid: 4,
			minuteGrid: 10,
			ampm: true,
			timeFormat: 'hh:mm TT'
		});
	}

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
					//	window.location = "ticket.pl?mode=lookup";
						var ticket_number = $("#ticket_number").text();
						var url = "ticket_details.pl?ticket_number=" + ticket_number;
						$('#ticket_details').load(url);
						
				},
				error: function(xml,text,error){
					alert("xml: " + xml.responseText + "\ntext: " + text + "\nerror: " + error);
				}
			});
	});

	$("#submit_button").click(function(){
		resetLogout();
		validateTicket();		
		if($("#newticket").valid())
		{
			$.blockUI({message: "Submitting"});
			var url = "submit_ticket.pl";
			var the_data = $("#newticket").serialize();
			$.ajax({
				type: 'POST',
				url: url,
				data: the_data,
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
						alert("Added the ticket");
						if($('#attach_form input[type="file"]').val() !== ""){
							$('#attach_form').append('<input type="hidden" name="utkid" id="utkid" value="' + $("#ticket_number").text() + '">');
							$('#attach_form').submit();
						}
						window.location = "ticket.pl?mode=new";
					} else if(error == 1){
						var str = data.replace(/^[\d\s]/,'');
						alert(str);
					} else if(error == 2){
						var str = data.replace(/^[\d\s]/,'');
						alert("The following errors were encountered while processing your request:" + str);
					} else {
						var str = data.replace(/^[\d\s]/,'');
						alert(str);
					}
					$.unblockUI();
				},
				error: function(xml,text,error){
					alert("xml: " + xml.responseText + "\ntext: " + text + "\nerror: " + error);
					$.unblockUI();
				}
			});
		}
	});

	$('#newticket').submit(function(e){
		e.preventDefault();
	});

	$("#customer_submit_button").click(function(e){
		e.preventDefault();
		resetLogout();
		validateTicket();
		if($("#newticket").valid())
		{
			$.blockUI({message: "Submitting"});
			var url = "submit_ticket.pl?type=customer";
			var the_data = $("#newticket").serialize();
			$.ajax({
				type: 'POST',
				url: url,
				data: the_data,
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
						alert("Added the ticket");
						$('#attach_form').submit();
						window.location = "customer.pl";
					} else {
						var str = data.replace(/^[\d\s]/,'');
						alert(str);
					}
					$.unblockUI();
				},
				error: function(xml,text,error){
					alert("xml: " + xml.responseText + "\ntext: " + text + "\nerror: " + error);
					$.unblockUI();
				}
			});
		}
		
	});
	
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
	
	$(".section_header_div").click(function(){
		resetLogout();
		$(this).children('a').children('.toggle_img').toggle();
	});
	
	
	$("#search_box").click(function(){
		$(this).val("");
	});
	
	$("#search_button").click(function(e){
		e.preventDefault();
		$(".ticket_lookup").each(function(){
			var C = $(this);
			var section = C.attr("id");
			var pane = C.jScrollPane({
				showArrows: true,
				maintainPosition: false
			}).data('jsp');
			var search_criteria = $("#search_box").val();
			var url = "lookup_ticket.pl?section=" + section + "&search=" + escape(search_criteria);
			pane.getContentPane().load(url,function(data){
				pane.reinitialise();
			});
			$('.ticket_summary').livequery(function(){
				$(this).tablesorter();
			});
		});
	});

	$('.ticket_lookup').each(function(){
		var section_id = $(this).attr('section');
		var caption_text = $(this).attr('caption_text');
		var url = "lookup_ticket.pl?section=" + section_id;
		$(this).jqGrid({
			url: url,
			datatype: 'xml',
			mtype: 'GET',
			colNames: ['Ticket Number','Ticket Status','Ticket Priority','Ticket Contact','Problem','Location','Section'],
			colModel: [
				{name: 'ticket', index: 'ticket', width: 100, sortable: true, search: true, stype: 'text'},
				{name: 'status', index: 'status', width: 100, sortable: true, search: true, stype: 'text'},
				{name: 'priority', index: 'priority', width: 100, sortable: true, search: true, stype: 'text'},
				{name: 'contact', index: 'contact', width: 125, sortable: true, search: true, stype: 'text'},
				{name: 'problem', index: 'problem', width: 200, sortable: true, search: true, stype: 'text'},
				{name: 'location', index: 'location', width: 200, sortable: true, search: true, stype: 'text'},
				{name: 'name', index: 'name', width: 100, sortable: true, search: true, stype: 'text'}
			],
			pager: "#" + section_id,
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
			caption: caption_text,
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
		$(this).jqGrid('filterToolbar',{
			colModel: [
				{name: 'ticket', index: 'ticket', width: 100, sortable: true, search: true, stype: 'text'},
				{name: 'status', index: 'status', width: 100, sortable: true, search: true, stype: 'text'},
				{name: 'priority', index: 'priority', width: 100, sortable: true, search: true, stype: 'text'},
				{name: 'contact', index: 'contact', width: 125, sortable: true, search: true, stype: 'text'},
				{name: 'problem', index: 'problem', width: 200, sortable: true, search: true, stype: 'text'},
				{name: 'location', index: 'location', width: 200, sortable: true, search: true, stype: 'text'},
				{name: 'name', index: 'name', width: 100, sortable: true, search: true, stype: 'text'}
			]
		});
	});

	$('.ticket_lookup').each(function(){
		$(this).trigger('reloadGrid', [{page: 1}]);
		var section_id = $(this).attr('section');
		var new_val = $('td#' + section_id + '_center span#sp_' + section_id).text();
	});
});
