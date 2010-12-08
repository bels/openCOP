$(document).ready(function(){
	$('#user_select').change(function(){
		var uid = $(this).val();
		$.ajax({
			type: 'POST',
			url: 'time_tracking_addon.pl',
			data: {id: uid},
			success: function(data){

			},
			error: function(){
				alert("Error");
			},
		});
	});
});
