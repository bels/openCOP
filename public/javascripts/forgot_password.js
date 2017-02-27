$(document).ready(function(){
	$('#blank').load('tips.html');

	$('.tooltip').each(function(){
		var $this = $(this);
		var t = setTimeout(function(){
			$this.attr('title',$('#' + $this.attr('tip')).text());
		},'200');
	});

	$('#blank').html('');

	$("#customer_submit_button").click(function(){
		validateTicket();
		if($("#newticket").valid()){
			$.blockUI({message: "Submitting"});
			var url = "change_password_request.pl";
			var the_data = $("#newticket").serialize();
			$.ajax({
				type: 'POST',
				url: url,
				data: the_data,
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
						alert("Your request has been submitted.");
						window.location = 'index.pl';
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

	if($('#free_date').length){
		$('#free_date').datepicker();
		$('.free_time').timepicker({
			hourGrid: 4,
			minuteGrid: 10,
			ampm: true,
			timeFormat: 'hh:mm TT'
		});
	}

	function validateTicket(){
		$('#newticket').validate({
			rules: {
				author: "required",
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
});
