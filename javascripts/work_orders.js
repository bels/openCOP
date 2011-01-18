$(document).ready(function(){
	var requires_index = 1;
	$('.requires').livequery(function(){
		$(this).attr('id',requires_index);
		requires_index++;
	});

	$('#blank').load('tips.html');

	$('.tooltip').each(function(){
		var $this = $(this);
		var t = setTimeout(function(){
			$this.attr('title',$('#' + $this.attr('tip')).text());
		},'200');
	});

	$('#blank').html('');

	$('#wo_tabs').tabs({
		panelTemplate: "<div>" + $('#content1').html() + "</div>"
	});
	$('#wo_tabs').tabs('disable', 1);
	$('#new_tab').find('a').bind('click', function(){
		resetLogout();
		var ci = $('ul.ui-tabs-nav').children().length;
		$('#wo_tabs').tabs('add', '#content' + ci, 'Step ' + ci, ci -1);
		$('#wo_tabs').tabs('select', ci -1)
		$('.requires').each(function(){
			var ci;
			var newHTML = "<option></option>";
			var index = $(this).attr('id');
			var step = $('#' + index + ' :selected').val();
			$('#wo_tabs').find('div.ui-tabs-panel').each(function(){
				var thisForm = $(this).find('form.newwo');
				if(thisForm.length){
					ci = $(this).attr('id').substr($(this).attr('id').length -1);
					newHTML += '<option value="' + ci + '">Step ' + ci + '</option>';
				}
			});
			ci = $(this).parent().parent().parent().attr('id').substr($(this).attr('id').length -1);
			var ci = ci.substr(ci.length -1);
			$(this).html(newHTML);
			$(this).children('option[value=' + ci + ']').remove();
			$(this).children('option[value=' + step + ']').attr('selected','selected');
			if(ci == ($('ul.ui-tabs-nav').children().length -1)){
				$(this).children('option[value=""]').attr('selected','selected');
			}
		});
	});

	$('.create_button').livequery(function(){
		$(this).bind('click',function(){
			resetLogout();
			var h = [];
			h[0] = [undefined, "0"];
			var allValid = 1;
			$('#wo_tabs').find('div.ui-tabs-panel').each(function(){
				var thisForm = $(this).find('form.newwo');
				if(thisForm.length){
					var isValid = validateTicket(thisForm);
					if(isValid){
						var ci = $(this).attr('id').substr($(this).attr('id').length -1);
						var the_data = thisForm.serialize();
						h[ci] = [];
						var a = the_data.split("&");
						$.each(a,function(i, array){
							var b = array.split("=");
							var c = b[0];
							var d = b[1];
							h[ci][i] = {};
							h[ci][i][c] = d;
						});
						allValid = ( 1 & allValid);
					} else {
						allValid = ( 0 );
					}
				}
			});
			if($('#wo_name_input').val() !== ""){
				if(allValid){
					$.blockUI({message: "Submitting"});
					var name = $('#wo_name_input').val();
					var object = $.toJSON(h);
					var url = "create_wo.pl";
					$.ajax({
						type: 'POST',
						url: url,
						data: {object: object, name: name},
						success: function(data){
							var error = data.substr(0,1);
							if(error == "0"){
								var str = data.replace(/^[\d\s]/,'');
								alert("Created new work order");
								window.location = "work_orders.pl";
							} else if(error == "1"){
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
			} else {
				alert("You must give this work order a name");
			}
		});
	});
});

function validateTicket(e){
	e.validate({
		rules: {
			section: "required",
			problem: "required"
		},
		messages: {
			section: {
				required: "*"
			},
			problem: {
				required: "* Please enter a description of your problem."
			}
		}
	});
	return e.valid();
}
