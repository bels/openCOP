$(document).ready(function(){
	$(".ticket_link").click(function(){
		var ticket_number = $(this).attr("id");
		var url = "customer_ticket_lookup.pl?ticket_number=" + ticket_number;
		$("#right").load(url);
	});

		$('right_holder').jScrollPane({
			showArrows:true,
			maintainPosition: false
		});


	$("#update_ticket_button").live("click",function(){
		$('#add_notes_form').validate({
			rules: {
				new_note: {
					required: true
				}
			}
		});
		if($('#add_notes_form').valid()) {
			var the_data = $("#add_notes_form").serialize();
			var url = "customer_update_ticket.pl";
			$.ajax({
				type: 'POST',
				url: url,
				data: the_data,
				success: function(){
					alert("Updated the ticket");
					window.location = "customer_ticket.pl?status=open";
				},
				error: function(xml,text,error){
					alert("xml: " + xml.responseText + "\ntext: " + text + "\nerror: " + error)
				}
			});
		}
	});
});
