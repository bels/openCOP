$(document).ready(function(){
	$('.add_column').livequery(function(){
		$('.add_column').bind('click',function(){
			var temp = $(this).prev().children("select:last-child");
			var id_num;
			(temp.attr('id') ? id_num = temp.attr('id') : id_num = 99);
			id_num++;
			var column_select = "<select id=\"" + id_num + "\" class=\"column\"></select>";
			$(this).prev().append(column_select);
		});
	});
	$('.del_column').livequery(function(){
		$('.del_column').bind('click',function(){
			$(this).prev().prev().children("select:last-child").remove();
		});
	});
	$('.add_table').livequery(function(){
		$('.add_table').bind('click',function(){
			var table_id_num;
			var temp = $(this).prev().children("select:last-child");
			(temp.attr('id') ? id_num = temp.attr('id') : id_num = 300);
			table_id_num++;
			var table_column_id_num = "400";
			var table_select = "<div class=\"join_div\"><span class=\"fl\"> </span><div class=\"join_div_element\"><select class=\"join\"><option value=\"left join\" selected=\"selected\">Left Join</option><option value=\"right join\">Right join</option></select></div><div class=\"join_div_element\"><select id=\"" + table_id_num + "\" class=\"table\"></select></div><span class=\"label\">on</span><div class=\"join_div_element\"><select id=\"" + table_column_id_num + "\" class=\"first join_column\"></select></div><span class=\"label\">=</span><div class=\"join_div_element\"><select id=\"" + table_column_id_num + "\" class=\"second join_column\"></select></div><button id=\"206\" class=\"del_table\">-</button><button id=\"205\" class=\"add_table\">+</button></div>";
			if($(this).parent().next('#join_div_parent').length){
				$(this).parent().next().append(table_select);
			} else {
				$(this).parent().parent().append(table_select);
			}
			$(this).remove();
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
	$('.del_table').livequery(function(){
		$(this).bind('click',function(){
			if($(this).parent().prev('div.join_div').length){
				$(this).parent().prev('div.join_div').append("<button id=\"205\" class=\"add_table\">+</button>");
			} else {
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
			var where_select = "<div class=\"where\"><span class=\"fl\"> </span><select class=\"all_columns\"></select><select class=\"operator\"></select><input type=\"text\" class=\"where_input\"><button id=\"207\" class=\"del_where\">-</button></div>";
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
		$('.join_div select.table').each(function(){
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
			$(this).remove();
			var andor_val = $(this).val();
			var where_select = "<div class=\"where\"><input type=\"hidden\" value=\"" + andor_val + "\"><span class=\"fl\">" + andor_val + "</span><select class=\"all_columns\"></select><select class=\"operator\"></select><input type=\"text\" class=\"where_input\"><button id=\"207\" class=\"del_where\">-</button></div>";
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
			var mode = "select_column";
			var table = $(this).val();
			$.ajax({
				type: 'POST',
				url: 'query_builder.pl',
				data: {mode: mode, table: table},
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
							$('#fake_form').append("<select class=\"order_select\">" + str + "</select>");
						} else {
							$('#fake_form').append("<select class=\"order_select\">" + str + "</select>");
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
				last_child.remove();
				$('#fake_form').append("<input type=\"text\" class=\"limit\" id=\"limit\">");
			} else {
				$('#fake_form').append("<input type=\"text\" class=\"limit\" id=\"limit\">");
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
});

function populate_select_columns(){
	var mode = "select_column";
	var table = $('#from_div select.table').val();
	$.ajax({
		type: 'POST',
		url: 'query_builder.pl',
		data: {mode: mode, table: table},
		success: function(data){
			var error = data.substr(0,1);
			if(error == "0"){
				var str = data.replace(/^[\d\s]/,'');
				$('#select_div select.column').each(function(){
					if($(this).html().match(/.+/)){
					} else {
						$(this).html(str);
					}
				});
			} else if(error == "1"){
				var str = data.replace(/^[\d\s]/,'');
			}
		},
		error: function(){
			alert("Error");
		}
	});			
}
