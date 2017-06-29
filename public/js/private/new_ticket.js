;(function(){

	$(function(){
		jQuery.validator.setDefaults({
			success: "valid"
		});

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
			},
			highlight: function (element) {
		        $(element).closest('.form-group').addClass('has-error');
		    },
		    success: function (element) {
		        $(element).addClass('valid').closest('.form-group').removeClass('has-error');
		    }
		});
	});
})();