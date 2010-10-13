$(document).ready(function(){
	$("#submit_button").click(function(){
		var url = "submit_ticket.pl";
		/*var the_data = "site=" + $("#site").val() + "&author=" + $("#author").val() + "&barcode=" + $("#barcode").val() + "&serial=" + $("#serial").val() + "&contact=" + $("#contact").val() + "&phone=" + $("#phone").val() + "&email=" + $("#email").val() + "&location=" +$("#location").val() + "&priority=" + $("#priority").val() + "&group=" + $("#group").val() + "&problem=" + $("#problem").val() + "&troubleshoot=" + $("#troubleshoot").val();*/
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
	});
	
	if($("#ticket_lookup").length)
	{
		/*This will have to be improved when we start actually caring about queues */
		var url = "lookup_ticket.pl";
		$.get(url,function(data){
			$("#ticket_lookup").append(data);
		});
	}
	
	$(".lookup_row").live("click",function(){
		var ticket_number = $(this).children(".row_ticket_number").text();
		var url = "ticket_details.pl?ticket_number=" + ticket_number;
		$("#ticket_details").html("");
		$("#ticket_details").append("<h2>Ticket Details</h2>");
		$.get(url,function(data){
			$("#ticket_details").append(data);
		});
		$("#ticket_details").css("display","block");
	});
	$("#customer_submit_button").click(function(){
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
	});
});