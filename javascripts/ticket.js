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
				window.location = "ticket.pl?mode=new";
				},
			error: function(){alert("Big fail")}
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
});