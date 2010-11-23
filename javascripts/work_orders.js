$(document).ready(function(){
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
			$('#wo_tabs').find('div.ui-tabs-panel').each(function(){
				var thisForm = $(this).find('form.newwo');
				if(thisForm.length){
					ci = $(this).attr('id').substr($(this).attr('id').length -1);
					newHTML += '<option value="' + ci + '">Step ' + ci + '</option>';
				}
			});
			$(this).html(newHTML);
		});
	});

	$('.requires').livequery(function(){
		var ci;
		var newHTML = "";
		var iHTML = $(this).html();
		$('#wo_tabs').find('div.ui-tabs-panel').each(function(){
			var thisForm = $(this).find('form.newwo');
			if(thisForm.length){
				ci = $(this).attr('id').substr($(this).attr('id').length -1);
				newHTML += '<option value="' + ci + '">Step ' + ci + '</option>';
			}
		});
		$(this).html(iHTML + newHTML);
	}).expire();

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

			if(allValid){
				$.blockUI({message: "Submitting"});
				var name = $('#wo_name_input').val();
				var object = $.toJSON(h);
				var url = "submit_wo.pl";
				$.ajax({
					type: 'POST',
					url: url,
					data: {object: object, name: name},
					success: function(data){
						var error = data.substr(0,1);
						if(error == "0"){
							var str = data.replace(/^[\d\s]/,'');
							alert("Creates new work order");
							window.location = "work_orders.pl";
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
			priority: "required",
			section: "required",
			problem: "required"
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
			},
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

function refreshRequires(){
}
