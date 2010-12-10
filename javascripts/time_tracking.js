$(document).ready(function(){
	$("#start_date").datepicker();
	$("#end_date").datepicker();

	$('div#by_tech #display').bind('click',function(){
		resetLogout();
		var uid = $('#user_select').val();
		var mode = "by_tech";
		if(uid){
			var sd = $('#start_date').val();
			var ed = $('#end_date').val();
			$.ajax({
				type: 'POST',
				url: 'time_tracking_addon.pl',
				data: {id: uid, sd: sd, ed: ed, mode: mode},
				success: function(data){
					$('#tech_output').html(data);
				},
				error: function(){
					alert("Error");
				},
			});
		}
	});
	$('div#by_ticket #display').bind('click',function(){
		resetLogout();
		var search = $('#ticket_search').val();
		var mode = "by_ticket";
		if(search){
			$.ajax({
				type: 'POST',
				url: 'time_tracking_addon.pl',
				data: {search: search, mode: mode},
				success: function(data){
					$('#ticket_output').html(data);
				},
				error: function(){
					alert("Error");
				},
			});
		}
	});
});
