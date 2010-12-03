$(document).ready(function(){
	$(".wo_link").click(function(){
		resetLogout();
		var wo = $(this).attr("id");
		var url = "wo_ticket_lookup.pl?wo=" + wo;
		$("#right").load(url);
	});
});