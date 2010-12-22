$(document).ready(function(){
	$('#update').bind('click',function(){
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
