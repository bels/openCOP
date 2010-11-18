$(document).ready(function(){
	var pane = $('#top').jScrollPane({
		showArrows: true,
		maintainPosition: false
	}).data('jsp');
	$('#res_table').livequery(function(){
		$(this).tablesorter();
	});
});
