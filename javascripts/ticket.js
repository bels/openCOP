$(document).ready(function(){

	if($('#free_date').length){
		$('#free_date').datepicker();
		$('#free_time').timepicker({
			hourGrid: 4,
			minuteGrid: 10,
			ampm: true,
			timeFormat: 'hh:mm TT'
		});
	}

	if($(".ticket_lookup").length){
	//	alert("We have a div");
		$('.ticket_lookup').each(function(){
		//	alert($(this).attr("id"));
			var section = $(this).attr("id");
			var pane = $(this).jScrollPane({
				showArrows:true,
				maintainPosition: false
			}).data('jsp');
			var url = "lookup_ticket.pl?section=" + section;
		//	alert(url);
			pane.getContentPane().load(url,function(data){
		//		alert (data);
				pane.reinitialise();
			});
			$('.ticket_summary').livequery(function(){
				$('.ticket_summary').tablesorter();
			});
		});
		var details_pane = $("#ticket_details").jScrollPane({
				showArrows:true,
				maintainPosition: false
		}).data('jsp');
		/*This will have to be improved when we start actually caring about queues */
	}
	
	$("#submit_button").click(function(){
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
	
	$(".lookup_row").live("click",function(){
		var ticket_number = $(this).children(".row_ticket_number").text();
		var url = "ticket_details.pl?ticket_number=" + ticket_number;
		details_pane.getContentPane().load(url,function(data){
			details_pane.reinitialise();			
		});
		$("#ticket_details").css("display","block");
	});
	$("#customer_submit_button").click(function(){
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
				success: function(){
					alert("Added the ticket");
					window.location = "customer.pl";
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
					required: "*"
				}
			}
		});
	}
});
