$(document).ready(function(){
	$('.add_column').livequery(function(){
		$(this).bind('click',function(){
			var temp = $(this).prev().children("select:last-child");
			var id_num;
			(temp.attr('id') ? id_num = temp.attr('id') : id_num = 99);
			id_num++;
			var column_select = "<select id=\"" + id_num + "\" name=\"" + id_num + "\" class=\"column\"></select>";
			$(this).prev().append(column_select);
		});
	});
	$('.del_column').livequery(function(){
		$('.del_column').bind('click',function(){
			$(this).prev().prev().children("select:last-child").remove();
		});
	});
	$('.add_table').livequery(function(){
		$(this).bind('click',function(){
			var table_num;
			var temp = $(this).parent().find("select.table");
			(temp.attr('id') ? table_num = temp.attr('id') : table_num = 299);
			table_num++;
			var join = $(this).parent().find("select.join");
			var j_num;
			(join.attr('id') ? j_num = join.attr('id') : j_num = 399);
			j_num++;
			var fc = $(this).parent().find("select.first");
			var fc_num;
			(fc.attr('id') ? fc_num = fc.attr('id') : fc_num = 499);
			fc_num++;
			var fs = $(this).parent().find("select.second");
			var fs_num;
			(fs.attr('id') ? fs_num = fs.attr('id') : fs_num = 599);
			fs_num++;
			var table_select = "<div class=\"join_div\"><span class=\"fl\"> </span><div class=\"join_div_element\"><select class=\"join\" id=\"" + j_num + "\" name=\"" + j_num + "\"><option value=\"left join\" selected=\"selected\">Left Join</option><option value=\"right join\">Right join</option><option value=\"inner join\">Inner join</option><option value=\"outer join\">Outer join</option></select></div><div class=\"join_div_element\"><select id=\"" + table_num + "\" name=\"" + table_num + "\" class=\"table\"></select></div><span class=\"label\">on</span><div class=\"join_div_element\"><select id=\"" + fc_num + "\" name=\"" + fc_num + "\" class=\"first join_column\"></select></div><span class=\"label\">=</span><div class=\"join_div_element\"><select id=\"" + fs_num + "\" name=\"" + fs_num + "\" class=\"second join_column\"></select></div><button id=\"206\" class=\"del_table\">-</button><button id=\"205\" class=\"add_table\">+</button></div>";
			if($(this).parent().next('#join_div_parent').length){
				$(this).parent().next().append(table_select);
			} else {
				$(this).parent().parent().append(table_select);
			}
			$(this).remove();
			var mode = "first_join";
			var table = $(this).val();
			var table_select = $(this);
			if($(this).val() === null){
			} else if($(this).val() == ''){
			} else {
			$.ajax({
				type: 'POST',
				url: 'query_builder.pl',
				data: {mode: mode, table: table},
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
						var iHTML = table_select.html();
						table_select.parent().parent().find('.join_div_element select.first').html(str);
					} else if(error == "1"){
						var str = data.replace(/^[\d\s]/,'');
					}
				},
				error: function(){
					alert("Error");
				}
			});
			$('.where_div select.all_columns').each(function(){
				var all_columns_select = $(this);
				var mode = "second_join";
				var tablestring = "";
				$('div select.table').each(function(){
					tablestring += $(this).val() + ":";
				});
				$.ajax({
					type: 'POST',
					url: 'query_builder.pl',
					data: {mode: mode, tablestring: tablestring},
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
			$('.join_div select.table').each(function(){
				var mode = "second_join";
				var tablestring = "";
				var table_select = $(this);
				$('div select.table').each(function(){
					tablestring += $(this).val() + ":";
				});
				$.ajax({
					type: 'POST',
					url: 'query_builder.pl',
					data: {mode: mode, tablestring: tablestring},
					success: function(data){
						var error = data.substr(0,1);
						if(error == "0"){
							var str = data.replace(/^[\d\s]/,'');
							table_select.parent().parent().find('.join_div_element select.second').html(str);
						} else if(error == "1"){
							var str = data.replace(/^[\d\s]/,'');
						}
					},
					error: function(){
						alert("Error");
					}
				});
			});
			}
		});
	});
	$('.del_table').livequery(function(){
		$(this).bind('click',function(){
			if($(this).parent().prev('div.join_div').length && !$(this).parent().next('div.join_div').length){
				$(this).parent().prev('div.join_div').append("<button id=\"205\" class=\"add_table\">+</button>");
			} else if(!$(this).parent().next('div.join_div').length){
				$('#from_div').append("<button id=\"205\" class=\"add_table\">+</button>");
			}
			$(this).parent().remove();
			var mode = "first_join";
			var table = $(this).val();
			var table_select = $(this);
			$.ajax({
				type: 'POST',
				url: 'query_builder.pl',
				data: {mode: mode, table: table},
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
						var iHTML = table_select.html();
						table_select.parent().parent().find('.join_div_element select.first').html(str);
					} else if(error == "1"){
						var str = data.replace(/^[\d\s]/,'');
					}
				},
				error: function(){
					alert("Error");
				}
			});
			$('.where_div select.all_columns').each(function(){
				var all_columns_select = $(this);
				var mode = "second_join";
				var tablestring = "";
				$('div select.table').each(function(){
					tablestring += $(this).val() + ":";
				});
				$.ajax({
					type: 'POST',
					url: 'query_builder.pl',
					data: {mode: mode, tablestring: tablestring},
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
			$('.join_div select.table').each(function(){
				var mode = "second_join";
				var tablestring = "";
				var table_select = $(this);
				$('div select.table').each(function(){
					tablestring += $(this).val() + ":";
				});
				$.ajax({
					type: 'POST',
					url: 'query_builder.pl',
					data: {mode: mode, tablestring: tablestring},
					success: function(data){
						var error = data.substr(0,1);
						if(error == "0"){
							var str = data.replace(/^[\d\s]/,'');
							table_select.parent().parent().find('.join_div_element select.second').html(str);
						} else if(error == "1"){
							var str = data.replace(/^[\d\s]/,'');
						}
					},
					error: function(){
						alert("Error");
					}
				});
			});
		});
	});
	$('.add_where').livequery(function(){
		$(this).bind('click',function(){
			$(this).remove();
			$('.where_div').append("<span>Where</span>");
			var where_select = "<div class=\"where\"><span class=\"fl\"> </span><select name=\"700\" class=\"all_columns\"></select><select name=\"800\" class=\"operator\"></select><input type=\"text\" name=\"900\" class=\"where_input\"><button id=\"207\" class=\"del_where\">-</button></div>";
			var andor_select = "<select class=\"andor_select\"><option value=\"\">Add and/or</option><option value=\"and\">and</option><option value=\"or\">or</option>";
			$('.where_div').append(where_select + andor_select);
		});
	});
	$('.del_where').livequery(function(){
		$(this).bind('click',function(){
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
	$('.all_columns').livequery(function(){
		var all_columns_select = $(this);
		$('div select.table').each(function(){
			var mode = "second_join";
			var tablestring = "";
			$('div select.table').each(function(){
				tablestring += $(this).val() + ":";
			});
			$.ajax({
				type: 'POST',
				url: 'query_builder.pl',
				data: {mode: mode, tablestring: tablestring},
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
	});

	$('.andor_select').livequery(function(){
		$('.andor_select').change(function(){
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
	$('#from_div select.table').livequery(function(){
		var mode = "table";
		var table_select = $(this);
		$.ajax({
			type: 'POST',
			url: 'query_builder.pl',
			data: {mode: mode},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
					var iHTML = $(this).html();
					table_select.html(iHTML + str);
				} else if(error == "1"){
					var str = data.replace(/^[\d\s]/,'');
				}
			},
			error: function(){
				alert("Error");
			}
		});
		$('#from_div select.table').change(function(){

		var all_columns_select = $(this);
		$('div select.table').each(function(){
			var mode = "select_column";
			var tablestring = "";
			$('div select.table').each(function(){
				tablestring += $(this).val() + ":";
			});
			$.ajax({
				type: 'POST',
				url: 'query_builder.pl',
				data: {mode: mode, tablestring: tablestring},
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
						$('#select_div select.column').each(function(){
								$(this).html(str);
								$('.join_div select.table').each(function(){
									var mode = "second_join";
									var tablestring = "";
									var table_select = $(this);
									$('div select.table').each(function(){
										tablestring += $(this).val() + ":";
									});
									$.ajax({
										type: 'POST',
										url: 'query_builder.pl',
										data: {mode: mode, tablestring: tablestring},
										success: function(data){
											var error = data.substr(0,1);
											if(error == "0"){
												var str = data.replace(/^[\d\s]/,'');
												table_select.parent().parent().find('.join_div_element select.second').html(str);
											} else if(error == "1"){
												var str = data.replace(/^[\d\s]/,'');
											}
										},
										error: function(){
											alert("Error");
										}
									});
								});

						});
					} else if(error == "1"){
						var str = data.replace(/^[\d\s]/,'');
					}
				},
				error: function(){
					alert("Error");
				}
			});
		});

			if($(this).val() === null){
				} else if($(this).val() == ''){
			} else {
			$('.where_div select.all_columns').each(function(){
				var all_columns_select = $(this);
				var mode = "second_join";
				var tablestring = "";
				$('div select.table').each(function(){
					tablestring += $(this).val() + ":";
				});
				$.ajax({
					type: 'POST',
					url: 'query_builder.pl',
					data: {mode: mode, tablestring: tablestring},
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
			}
		});
	});
	$('#select_div select.column').livequery(function(){
			if($('#from_div select.table').val()){
				populate_select_columns();
			}
	});
	$('.join_div select.table').livequery(function(){
		var mode = "table";
		var table_select = $(this);
		$.ajax({
			type: 'POST',
			url: 'query_builder.pl',
			data: {mode: mode},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
					table_select.html(str);
				} else if(error == "1"){
					var str = data.replace(/^[\d\s]/,'');
				}
			},
			error: function(){
				alert("Error");
			}
		});
		$('.join_div select.table').change(function(){
			populate_select_columns();
			var mode = "first_join";
			var table = $(this).val();
			var table_select = $(this);
			$.ajax({
				type: 'POST',
				url: 'query_builder.pl',
				data: {mode: mode, table: table},
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
						var iHTML = table_select.html();
						table_select.parent().parent().find('.join_div_element select.first').html(str);
					} else if(error == "1"){
						var str = data.replace(/^[\d\s]/,'');
					}
				},
				error: function(){
					alert("Error");
				}
			});
			$('.where_div select.all_columns').each(function(){
				var all_columns_select = $(this);
				var mode = "second_join";
				var tablestring = "";
				$('div select.table').each(function(){
					tablestring += $(this).val() + ":";
				});
				$.ajax({
					type: 'POST',
					url: 'query_builder.pl',
					data: {mode: mode, tablestring: tablestring},
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
			$('.join_div select.table').each(function(){
				var mode = "second_join";
				var tablestring = "";
				var table_select = $(this);
				$('div select.table').each(function(){
					tablestring += $(this).val() + ":";
				});
				$.ajax({
					type: 'POST',
					url: 'query_builder.pl',
					data: {mode: mode, tablestring: tablestring},
					success: function(data){
						var error = data.substr(0,1);
						if(error == "0"){
							var str = data.replace(/^[\d\s]/,'');
							table_select.parent().parent().find('.join_div_element select.second').html(str);
						} else if(error == "1"){
							var str = data.replace(/^[\d\s]/,'');
						}
					},
					error: function(){
						alert("Error");
					}
				});
			});
		});
	});
	$('.add_other').change(function(){
		var mode;
		if($('.add_other').val() == "order by"){
			var mode = "second_join";
			var tablestring = "";
			$('#from_div select.table').each(function(){
				tablestring += $(this).val() + ":";
			});
			if(tablestring == ':'){
			} else {
			$.ajax({
				type: 'POST',
				url: 'query_builder.pl',
				data: {mode: mode, tablestring: tablestring},
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
						var last_child = $('#fake_form').children(':last');
						if(last_child.length){
							last_child.remove();
							$('#fake_form').append("<select class=\"order_select\" name=\"order by\">" + str + "</select>");
							$('#fake_form').append("<select class=\"order_select\" name=\"ascdesc\"><option value=\"asc\">Ascending</option><option value=\"desc\">Descending</option></select>");
						} else {
							$('#fake_form').append("<select class=\"order_select\" name=\"order by\">" + str + "</select>");
							$('#fake_form').append("<select class=\"order_select\" name=\"ascdesc\"><option value=\"asc\">Ascending</option><option value=\"desc\">Descending</option></select>");
						}
					} else if(error == "1"){
						var str = data.replace(/^[\d\s]/,'');
					}
				},
				error: function(){
					alert("Error");
				}
			});
			}
		} else if ($('.add_other').val () == "limit"){
			var last_child = $('#fake_form').children(':last');
			if(last_child.length){
				$('#fake_form').children().each(function(){
					$(this).remove();
				});
				$('#fake_form').append("<input type=\"text\" class=\"limit\" id=\"limit\" name=\"limit\">");
			} else {
				$('#fake_form').append("<input type=\"text\" class=\"limit\" id=\"limit\" name=\"limit\">");
			}
		} else {
			$(this).next().children().remove();
		}		
	});
	$('#fake_form').validate({
		rules: {
			limit: {
				required: true,
				digits: true
			}
		}
	});
	$('#submit_div button').bind('click',function(){
	//	alert($.toJSON($('#select_div select.column').serializeObject()));
		var mode = $(this).attr('id');
		var h = {};
		h['select_columns'] = $('#select_div select.column').serializeObject();
		h['tables'] = $('select.table').serializeObject();
		h['joins'] = $('select.join_column').serializeObject();
		h['where'] = $('.where').children().serializeObject();
		h['other'] = $('#fake_form').children().serializeObject();
		var report_name = $('input#as').val();
		$.ajax({
			type: 'POST',
			url: 'build_sql.pl',
			data: {mode: mode, data: $.toJSON(h), report_name: report_name},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "1"){
					var str = data.replace(/^[\d\s]/,'');
					location.reload(true);
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


});

$.fn.serializeObject = function(){
	var o = {};
	var a = this.serializeArray();
	$.each(a, function() {
		if (o[this.name]) {
			if (!o[this.name].push) {
				o[this.name] = [o[this.name]];
			}
			o[this.name].push(this.value || '');
		} else {
			o[this.name] = this.value || '';
		}
	});
//	return o;
	return a;
};


function populate_select_columns(){
		var all_columns_select = $(this);
		$('div select.table').each(function(){
			var mode = "select_column";
			var tablestring = "";
			$('div select.table').each(function(){
				tablestring += $(this).val() + ":";
			});
			$.ajax({
				type: 'POST',
				url: 'query_builder.pl',
				data: {mode: mode, tablestring: tablestring},
				success: function(data){
					var error = data.substr(0,1);
					if(error == "0"){
						var str = data.replace(/^[\d\s]/,'');
						$('#select_div select.column').each(function(){
							$(this).html(str);
						});
					} else if(error == "1"){
						var str = data.replace(/^[\d\s]/,'');
					}
				},
				error: function(){
					alert("Error");
				}
			});
		});
}
