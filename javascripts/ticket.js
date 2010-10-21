$(document).ready(function(){
	if($("#ticket_lookup").length)
	{
		var pane = $("#ticket_lookup").jScrollPane({
			showArrows:true,
			maintainPosition: false
		}).data('jsp');
		var details_pane = $("#ticket_details").jScrollPane({
				showArrows:true,
				maintainPosition: false
		}).data('jsp');
		/*This will have to be improved when we start actually caring about queues */
		var url = "lookup_ticket.pl";
		pane.getContentPane().load(url,function(data){
			pane.reinitialise();
		});
		$("#ticket_summary").livequery(function(){
			$("#ticket_summary").tablesorter();
		});
	}
	
	$("#submit_button").click(function(){
		$("#newticket").validate();
		$("#email").rules("add",{required: true,email:true});
		$("#author").rules("add",{required: true});
		$("#contact").rules("add",{required: true});
		
		if($("#newticket").valid())
		{
			var url = "submit_ticket.pl";
			var the_data = $("#newticket").serialize();
			$.ajax({
				type: 'POST',
				url: url,
				data: the_data,
				success: function(){
					alert("Added the ticket");
					var pathname = window.location.pathname;
					if(pathname.match(/ticket\.pl/))
					{
						window.location = "ticket.pl?mode=new";
					}
					else
					{
						window.location = "customer.pl";
					}
				},
				error: function(xml,text,error){
					alert("xml: " + xml.responseText + "\ntext: " + text + "\nerror: " + error)
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
		$("#newticket").validate();
		$("#email").rules("add",{required: true,email:true});
		$("#author").rules("add",{required: true});
		$("#contact").rules("add",{required: true});
		
		if($("#newticket").valid())
		{
			var url = "submit_ticket.pl?type=customer";
			var the_data = $("#newticket").serialize();
			$.ajax({
				type: 'POST',
				url: url,
				data: the_data,
				success: function(){
					alert("Added the ticket");
					var pathname = window.location.pathname;
					if(pathname.match(/ticket\.pl/))
					{
						window.location = "ticket.pl?mode=new";
					}
					else
					{
						window.location = "customer.pl";
					}
				},
				error: function(xml,text,error){
					alert("xml: " + xml.responseText + "\ntext: " + text + "\nerror: " + error)
				}
			});
		}
	});
});