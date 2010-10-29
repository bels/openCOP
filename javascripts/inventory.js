$(document).ready(function(){
	$('#add_ip_form').validate({
		rules: {
			add_ip: {
				required: true
			}
		}
	});

	$('#submit_add_button').bind('click',function(){
		submit_ip($(this));
	});

	$('#submit_del_button').bind('click',function(){
		submit_ip($(this));
	});
});


function submit_ip(button){
	which = button.attr("mode");
	value = $('#' + which).val();
	if(value == "") {
		$('.ip_return').remove();
		$('<label class="error ip_return">' + $('#' + which + '_select :selected').text() + ' cannot be blank</label>').appendTo('#' + which + '_form');
	} else {
	if( $('#' + which + '_form').valid() ){		
			mode = "configure";
			type = $('#' + which + '_select').val();
			value = $('#' + which).val();
			$.blockUI({message: "Submitting"});			
			$.ajax({
				type: 'POST',
				url: 'inventory_submit.pl',
				data: {mode: mode, type: type, value: value,action: which},
				success: function(data){
                                        var error = data.substr(0,1);
                                        if(error == "0"){
                                                var str = data.replace(/^[\d\s]/,'');
						$('#' + which).val("");
						$('#' + which).focus();
						$('<label class="error ip_return">' + $('#' + which + '_select :selected').text() + ' successfully modified</label>').appendTo('#' + which + '_form');
					} else if(error == "1"){
                                                var str = data.replace(/^[\d\s]/,'');
						$('<label class="error ip_return">' + $('#' + which + '_select :selected').text() + ' already exists</label>').appendTo('#' + which + '_form');
					} else if(error == "2"){
                                                var str = data.replace(/^[\d\s]/,'');
						$('<label class="error ip_return">' + $('#' + which + '_select :selected').text() + ' does not exist</label>').appendTo('#' + which + '_form');
					}
					$.unblockUI();
				},
				error: function(){
					alert("What? This should never return an error.");
					$.unblockUI();
				}
			});

	}
	}
}
