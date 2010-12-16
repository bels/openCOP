$(document).ready(function(){
	$('.add_where').livequery(function(){
		$(this).bind('click',function(){
			resetLogout();
			$(this).remove();
			$('.where_div').append("<span>Where</span>");
			var where_select = "<div class=\"where\"><span class=\"fl\"> </span><select name=\"700\" class=\"all_columns\"></select><select name=\"800\" class=\"operator\"></select><input type=\"text\" name=\"900\" class=\"where_input\"><button id=\"207\" class=\"del_where\">-</button></div>";
			var andor_select = "<select class=\"andor_select\"><option value=\"\">Add and/or</option><option value=\"and\">and</option><option value=\"or\">or</option></select>";
			$('.where_div').append(where_select + andor_select);
		});
	});
	$('.del_where').livequery(function(){
		$(this).bind('click',function(){
			resetLogout();
			var where_text = $(this).parent().prev('span');
			if(where_text.length){
				var next_where = $(this).parent().next('.where');
				if(next_where.length){
				} else {
					$(this).parent().parent().prepend("<button id=\"204\" class=\"add_where\">Add Where</button>");
					$(this).parent().parent().children('.andor_select').remove();
					where_text.remove();
				}
			}
			$(this).parent().remove();
		});
	});

	$('select.all_columns').livequery(function(){
		var all_columns_select = $(this);
			var mode = "second_join";
			$.ajax({
				type: 'POST',
				url: 'query_builder.pl',
				data: {mode: mode},
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
						all_columns_select.html(str);
					} else if(error == "1"){
						var str = data.replace(/^[\d\s]/,'');
					}
				},
				error: function(){
					alert("Error");
				}
			});
	});
	$('.andor_select').livequery(function(){
		$(this).change(function(){
			resetLogout();
			var ac = $(this).prev().children("select.all_columns");
			var op = $(this).prev().children("select.operator");
			var wi = $(this).prev().children("input.where_input");
			var ao = $(this).prev('.where').children("input.andor");
			var ac_num;
			var op_num;
			var wi_num;
			var ao_num;
			(ac.attr('name') ? ac_num = ac.attr('name') : ac_num = 699);
			(op.attr('name') ? op_num = op.attr('name') : op_num = 799);
			(wi.attr('name') ? wi_num = wi.attr('name') : wi_num = 899);
			(wi.attr('name') ? wi_num = wi.attr('name') : wi_num = 899);
			(ao.attr('name') ? ao_num = ao.attr('name') : ao_num = 1099);
			ac_num++;
			op_num++;
			wi_num++;
			ao_num++;
			$(this).remove();
			var andor_val = $(this).val();
			var where_select = "<div class=\"where\"><input type=\"hidden\" class=\"andor\" name=\"" + ao_num + "\" value=\"" + andor_val + "\"><span class=\"fl\">" + andor_val + "</span><select name=\"" + ac_num + "\" class=\"all_columns\"></select><select name=\"" + op_num + "\" class=\"operator\"></select><input type=\"text\" name=\"" + wi_num + "\" class=\"where_input\"><button id=\"207\" class=\"del_where\">-</button></div>";
			var andor_select = "<select class=\"andor_select\"><option value=\"\">Add and/or</option><option value=\"and\">and</option><option value=\"or\">or</option>";
			$('.where_div').append(where_select + andor_select);
		});
	});
	$('.operator').livequery(function(){
		var mode = "operator";
		var operator_select = $(this);
		$.ajax({
			type: 'POST',
			url: 'query_builder.pl',
			data: {mode: mode},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
					var iHTML = $(this).html();
					operator_select.html(iHTML + str);
				} else if(error == "1"){
					var str = data.replace(/^[\d\s]/,'');
				}
			},
			error: function(){
				alert("Error");
			}
		});
	});
	$('#fake_form').validate({
		rules: {
			limit: {
				required: true,
				digits: true
			}
		}
	});
	$('#submit_div .image_button').bind('click',function(){
		resetLogout();
		var mode = $(this).attr('id');
		var h = {};
		h['where'] = $('.where').children().serializeObject();
		var rg_select_string = "";
		var rg_unselect_string = "";
		h['groups'] = [];
		$('#query_permissions ul.selected').children().each(function(e){
			if($(this).attr("title") !== ""){
				var ar = {'selected': $(this).attr("value")};
				h['groups'].push(ar);
			}
		});
		var report_name = $('input#as').val();
		alert($.toJSON(h));
		$.ajax({
			type: 'POST',
			url: 'build_sql.pl',
			data: {mode: mode, data: $.toJSON(h), report_name: report_name},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
					location.reload(true);
				} else if(error == "1"){
					var str = data.replace(/^[\d\s]/,'');
					alert("Duplicate entry detected. Please choose another name.");
				} else if(error == "2"){
					var str = data.replace(/^[\d\s]/,'');
					document.write(str);
					document.close();
				}
			},
			error: function(){
				alert("Error");
			}
		});
	});
	$('.multiselect').livequery(function(){
		var $this = $(this);
		$.get('report_addon.pl', function(data){
			$this.append(data).multiselect();
			$('.ui-multiselect').show();
		});
	});
	
});

$.fn.serializeObject = function(){
	var a = this.serializeArray();
	return a;
};
