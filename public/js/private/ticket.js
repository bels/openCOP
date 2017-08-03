;(function(){
	$(function(){
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
		
		$('.save.btn').click(function(){
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
		
		$('.add.troubleshooting.btn').click(function(){
			var $form = $(this).parent().parent().find('form');
			var data = $form.serialize();
			$.ajax({
				url: $form.attr('action'),
				method: $form.attr('method'),
				data: data
			}).done(function(data){
				alert('troubleshooting added');
				window.location.href = window.location.href;
			});
		});
	});
})();