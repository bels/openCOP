$(document).ready(function(){
	var triggers = $('#attach').overlay({
		mask: {
			loadSpeed: 200,
			opacity: 0.6,
		}
	});

	$('.add_file').live('click',function(e){
		e.preventDefault();
		var $this = $(this);
		var last_num = parseInt($(this).prevAll('input').attr('num'));
		last_num++;
		var $new_file = $(this).parent().append('<input type="file" name="file'+last_num+'" id="file'+last_num+'" num="'+last_num+'"><button class="del_file">-</button>');
		$new_file.append($this);
		$(this).parent().children('input.close').appendTo($new_file);
	});

	$('.del_file').live('click',function(e){
		e.preventDefault();
		$(this).prev('input').remove();
		$(this).prev('br').remove();
		$(this).remove();
	});

	$('.close').bind('click',function(e){
		e.preventDefault();
		
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

	if($('.ticket_lookup').length){
		$('.section_header_div').bind('click',function(){
			resetLogout();
			$(this).next(".ticket_lookup").toggle();
			var C = $(this).next(".ticket_lookup");
			var section = C.attr("id");
			var pane = C.jScrollPane({
				showArrows: true,
				maintainPosition: false
			}).data('jsp');
			var url = "lookup_ticket.pl?section=" + section;
			pane.getContentPane().load(url,function(data){
				pane.reinitialise();
			});
			$('.ticket_summary').livequery(function(){
				$('.ticket_summary').tablesorter();
			});
		});
	
		var section = $('.ticket_lookup').first().attr("id");
		var pane = $('.ticket_lookup').first().show().jScrollPane({
			showArrows: true,
			maintainPosition: false
		}).data('jsp');
		var url = "lookup_ticket.pl?section=" + section;
		pane.getContentPane().load(url,function(data){
			pane.reinitialise();
		});
		$('.ticket_summary').livequery(function(){
			$(this).tablesorter();
		});
		$('.toggle_link:not(:first)').children().toggle();
	};

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
	
	$(".lookup_row").live("click",function(){
		resetLogout();
		var ticket_number = $(this).children(".row_ticket_number").text();
		var url = "ticket_details.pl?ticket_number=" + ticket_number;
		var details_pane = $("#ticket_details").jScrollPane({
				showArrows:true,
				maintainPosition: false
		}).data('jsp');
		details_pane.getContentPane().load(url,function(data){
			details_pane.reinitialise();			
		});
		$("#ticket_details").css("display","block");
	});

	$('attach_form').submit(function(e){
		e.preventDefault();
		$(this).ajaxSubmit({
			iframe: true
		});
	});

	$("#customer_submit_button").click(function(){
		resetLogout();
		validateTicket();
		if($("#newticket").valid())
		{
			$.blockUI({message: "Submitting"});
			var url = "submit_ticket.pl?type=customer";
			var the_data = $("#newticket").serialize();
			var files;
			$.ajax({
				type: 'POST',
				url: url,
				data: the_data,
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
						$('#attach_form').submit();
						alert("Added the ticket");
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
});
