;(function(){

	$(function(){
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

		$('.date-picker').datetimepicker();
		$('.new-ticket.form').validate({
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
	});
})();