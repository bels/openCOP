;(function(){
	$(function(){
		$('.password-form').validate({
			rules:{
				password1: {
					required: true
				},
				password2: {
					required: true,
					equalTo: 'password1'
				}
			}
		});
	});
})();