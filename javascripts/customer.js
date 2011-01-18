$(document).ready(function(){
	$.ajaxSetup({
		cache: false
	});

	$('#blank').load('tips.html');

	$('.tooltip').each(function(){
		var $this = $(this);
		var t = setTimeout(function(){
			$this.attr('title',$('#' + $this.attr('tip')).text());
		},'200');
	});

	$('#blank').html('');

	var logoutTimer = window.setTimeout('logout()', '3600000');

	$('#attach_form').submit(function(e){
		e.preventDefault();
		$(this).ajaxSubmit({
			iframe: true
		});
	});

	$('.add_file').live('click',function(e){
		e.preventDefault();
		var $this = $(this);
		var last_num = parseInt($(this).prevAll('input').attr('num'));
		last_num++;
		var $new_file = $(this).parent().append('<input type="file" name="file'+last_num+'" id="file'+last_num+'" num="'+last_num+'"><button class="del_file">-</button>');
		$new_file.append($this);
		$(this).parent().children('input.close').appendTo($new_file);
	});

	$('.del_file').live('click',function(e){
		e.preventDefault();
		$(this).prev('input').remove();
		$(this).prev('br').remove();
		$(this).remove();
	});

	$('.close').live('click',function(e){
		e.preventDefault();
		var files = "";
		$('#attach_form input[type="file"]').each(function(){
			files += $(this).val() + "<br>";
		});
		$('#attach_div').html('<div rel="#multiAttach" id="attach"><label>Attach a File</label><img title="Attach A File" src="images/attach.png"></div>' + files);
		var triggers = $('#attach').overlay({
			mask: {
				loadSpeed: 200,
				opacity: 0.6
			}
		});
	});

	$(".ticket_link").click(function(){
		resetLogout();
		var ticket_number = $(this).attr("id");
		var oc = $('h4#oc').attr("value");
		var url = "customer_ticket_lookup.pl?ticket_number=" + ticket_number + "&oc=" + oc;
		$("#right").load(url);
	});

	$('#attach').livequery(function(){
		$(this).overlay({
			mask: {
				loadSpeed: 200,
				opacity: 0.6
			}
		});
	});

	$('#free_date').livequery(function(){
		$('#free_date').datepicker();
		$('.free_time').timepicker({
			hourGrid: 4,
			minuteGrid: 10,
			ampm: true,
			timeFormat: 'hh:mm TT'
		});
	});

	$('right_holder').jScrollPane({
		showArrows:true,
		maintainPosition: false
	});

	$("#update_ticket_button").live("click",function(){
		resetLogout();
		$('#add_notes_form').validate({
			rules: {
				new_note: {
					required: true
				}
			}
		});
		if($('#add_notes_form').valid()) {
			$('#attach_form').append('<input type="hidden" name="utkid" id="utkid" value="' + $("#tkid").val() + '">');
			var the_data = $("#add_notes_form").serialize();
			var url = "customer_update_ticket.pl";
			$.ajax({
				type: 'POST',
				url: url,
				data: the_data,
				success: function(){
					alert("Updated the ticket");
					$('#attach_form').submit();
					window.location = "customer_ticket.pl?status=open";
				},
				error: function(xml,text,error){
					alert("xml: " + xml.responseText + "\ntext: " + text + "\nerror: " + error)
				}
			});
		}
	});
});
function resetLogout(){
	logoutTimer = window.setTimeout('logout()', '3600000');
}
