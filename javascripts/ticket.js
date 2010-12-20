$(document).ready(function(){
	$('#attach_form').submit(function(e){
		e.preventDefault();
		$(this).ajaxSubmit({
			iframe: true
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
						window.location = "ticket.pl?mode=lookup";
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

	$('.lookup_row').live("mouseover mouseout",function(event){
		if(event.type == 'mouseover'){	
			$(this).addClass('selected');
		} else {
			$(this).removeClass('selected');
		}
	});
	
	$("#customer_submit_button").click(function(){
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
						window.location = "ticket.pl?mode=new";
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
			colNames: ['Ticket Number','Ticket Status','Ticket Priority','Ticket Contact','Problem','Section'],
			colModel: [
				{name: 'ticket', index: 'ticket', width: 100, sortable: true},
				{name: 'status', index: 'status', width: 100, sortable: true},
				{name: 'priority', index: 'priority', width: 100, sortable: true},
				{name: 'contact', index: 'contact', width: 125, sortable: true},
				{name: 'problem', index: 'problem', width: 200, sortable: true},
				{name: 'name', index: 'name', width: 100, sortable: true}
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
			}
		});
	});

	$('.ticket_lookup').each(function(){
		var section_id = $(this).attr('section');
		var new_val = $('td#' + section_id + '_center span#sp_' + section_id).text();
	});
});
