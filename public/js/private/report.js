;(function(){
	$(function(){
		$('.date-picker').datepicker();
		$.Mustache.addFromDom('tickets_received');
		$.Mustache.addFromDom('tickets_per_user');
		$.Mustache.addFromDom('tickets_closed');
		$.Mustache.addFromDom('ticket_time');
		$.Mustache.addFromDom('billable_tickets');
		$('.run-report.btn').click(function(){
			var $form = $(this).closest('form');
			var current_report = $('.current-report').val();
			$.ajax({
				url: $form.attr('action'),
				method: $form.attr('method'),
				data: $form.serialize()
			}).done(function(data){
				$('.data.table').html('');
				if(current_report == 'tickets_received'){
					$('.data.table').mustache('tickets_received',data);
				}
				if(current_report == 'tickets_received_per_user'){
					$('.data.table').mustache('tickets_per_user',data);
				}
				if(current_report == 'tickets_closed'){
					$('.data.table').mustache('tickets_closed',data);
				}
				if(current_report == 'ticket_time'){
					$('.data.table').mustache('ticket_time',data);
				}
				if(current_report == 'billable_tickets'){
					$('.data.table').mustache('billable_tickets',data);
				}
			});
		});
	});
})();