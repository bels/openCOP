;(function(){
	$(function(){
		$('.date-picker').datetimepicker();
		jQuery.validator.setDefaults({
			highlight: function(element) {
		        $(element).closest('.form-group').addClass('has-error');
		    },
		    unhighlight: function(element) {
		        $(element).closest('.form-group').removeClass('has-error');
		    },
		    errorElement: 'span',
		    errorClass: 'help-block',
		    errorPlacement: function(error, element) {
		        if(element.parent('.input-group').length) {
		            error.insertAfter(element.parent());
		        } else {
		            error.insertAfter(element);
		        }
		    }
		});
		
		
		$('.edit.btn').click(function(){
			var $this = $(this);
			$('.static').each(function(index,element){
				$(element).addClass('hidden');
			});
			$('.input').each(function(index,element){
				$(element).removeClass('hidden');
			});
			$this.hide();
			$('.save.btn').removeClass('hidden');
			$('#billable').prop('disabled','');
		});
		
		$('.update-ticket.form').validate({
			rules:{
				synopsis: {
					required: true
				},
				author: {
					required: true
				},
				contact: {
					required: true
				},
				phone: {
					require_from_group: [1, '.contact-group']
				},
				email: {
					email: true,
					require_from_group: [1, '.contact-group']
				},
				problem: {
					required: true
				}
			}
		});
		
		$('.save.btn').click(function(){
			var $form = $('.update-form'):
			if(!$form.valid()) return false;
			var data = {};
			$('.form-control').each(function(index,element){
				data[$(element).attr('id')] = $(element).val();
			});
			$('input:not(.form-control,#billable)').each(function(index,element){
				data[$(element).attr('id')] = $(element).val();
			});
			data['billable'] = $('#billable').prop('checked');
			data['csrf_token'] = $('#csrf_token').val();
			
			$.ajax({
				url: '/ticket/update/' + $('#ticket_id').val(),
				method: 'POST',
				data: JSON.stringify(data),
				dataType: 'json'
			}).done(function(data){
				window.location.href = window.location.href;
			});
		});

		$('.troubleshooting-form').validate({
			rules:{
				troubleshooting_time: {
					required: true,
					digits: true
				},
				troubleshoot: 'required'
			},
			submitHandler: function(form){
				var data = $(form).serialize();
				$.ajax({
					url: $(form).attr('action'),
					method: $(form).attr('method'),
					data: data
				}).done(function(data){
					alert('troubleshooting added');
					window.location.href = window.location.href;
				});
			}
		});
		
		$('.delete.btn').click(function(){
			var $this = $(this);
			var u = '/ticket/delete/' + $this.data('ticket-id');
			var d = {
				ticket_id: $this.data('ticket-id'),
				csrf_token: $('#csrf_token').val()
			};
			$.ajax({
				url: u,
				method: 'POST',
				data: d
			}).done(function(data){
				if(data.success){
					alert('Deleted Ticket');
				} else {
					alert('Could not delete ticket');
				}
			});
		});
	});
})();