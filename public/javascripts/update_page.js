$(document).ready(function(){
		var triggers = $('#update').overlay({
			mask: {
				loadSpeed: 200,
				opacity: 0.6
			}
		});

	$('#no').bind('click',function(e){
		e.preventDefault();
		var triggers = $('#update').overlay({
			mask: {
				loadSpeed: 200,
				opacity: 0.6
			}
		});
	});

	$('#yes').bind('click',function(){
		var url = 'update.pl';
		$.ajax({
			type: 'POST',
			url: url,
			success: function(){
				location.reload(true);
			},
			error: function(xml,text,error){
				alert("xml: " + xml.responseText + "\ntext: " + text + "\nerror: " + error);
			}
		});
	});
});
