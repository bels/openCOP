$(document).ready(function(){
	$('#blank').load('tips.html');

	$('.tooltip').each(function(){
		var $this = $(this);
		var t = setTimeout(function(){
			$this.attr('title',$('#' + $this.attr('tip')).text());
		},'200');
	});

	$('#blank').html('');

	$("#submit_button").click(function(){
		resetLogout();
		if(validateTicket($('#newwo')));{
			$.blockUI({message: "Submitting"});
			var url = "submit_wo.pl";
			var the_data = $("#newwo").serialize();
			$.ajax({
				type: 'POST',
				url: url,
				data: the_data,
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
						alert("Added the work order");
						window.location = "work_order_new.pl";
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
});

function validateTicket(e){
	e.validate({
		rules: {
			site: "required",
			author: "required",
			contact: "required",
			email: {
				email: true,
				required: true
			},
			priority: "required"
		},
		messages: {
			site: {
				required: "*"
			},
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
			priority: {
				required: "*"
			}
		}
	});
	return e.valid();
}
